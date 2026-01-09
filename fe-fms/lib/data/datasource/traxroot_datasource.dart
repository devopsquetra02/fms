import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/services/traxroot_credentials_manager.dart';
import '../models/traxroot_driver_model.dart';
import '../models/traxroot_geozone_model.dart';
import '../models/traxroot_icon_model.dart';
import '../models/traxroot_object_model.dart';
import '../models/traxroot_object_status_model.dart';
import '../models/traxroot_object_group_model.dart';
import '../models/traxroot_sensor_model.dart';

/// Datasource for Traxroot authentication.
class TraxrootAuthDatasource {
  static String? lastErrorMessage;

  /// Gets a valid access token, refreshing if necessary.
  Future<String> getAccessToken({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!forceRefresh) {
      final cachedToken = prefs.getString(Variables.prefTraxrootToken);
      final expiryMillis = prefs.getInt(Variables.prefTraxrootTokenExpiry);

      if (cachedToken != null && expiryMillis != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
        if (DateTime.now().isBefore(
          expiry.subtract(const Duration(minutes: 5)),
        )) {
          return cachedToken;
        }
      }
    }

    return _requestAndCacheToken(prefs);
  }

  Future<String> refreshToken() => getAccessToken(forceRefresh: true);

  Future<void> clearCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(Variables.prefTraxrootToken);
    await prefs.remove(Variables.prefTraxrootTokenExpiry);
  }

  Future<String> _requestAndCacheToken(SharedPreferences prefs) async {
    lastErrorMessage = null;
    final username = await TraxrootCredentialsManager.getUsername(prefs: prefs);
    final password = await TraxrootCredentialsManager.getPassword(prefs: prefs);
    final response = await http.post(
      Uri.parse(Variables.traxrootTokenEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'userName': username,
        'password': password,
        'subUserId': Variables.traxrootSubUserId,
        'language': Variables.traxrootLanguage,
      }),
    );

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootAuthDatasource',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(response.body, name: 'TraxrootAuthDatasource', level: 1200);

      String message = 'Failed to retrieve Traxroot token';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['errorMessage'] != null) {
          message = decoded['errorMessage'].toString();
        } else if (decoded['Message'] != null) {
          message = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {
        // ignore parsing error, keep default message
      }
      lastErrorMessage = message;
      log(
        'Traxroot token error: $message',
        name: 'TraxrootAuthDatasource',
        level: 1000,
      );
      // Do not throw; return empty token so callers can handle gracefully.
      return '';
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      log(
        'Traxroot token missing in response',
        name: 'TraxrootAuthDatasource',
        level: 1000,
      );
      return '';
    }

    final expiresInSeconds = (decoded['expiresIn'] as int?) ?? 7200;
    final expiry = DateTime.now().add(Duration(seconds: expiresInSeconds));

    await prefs.setString(Variables.prefTraxrootToken, token);
    await prefs.setInt(
      Variables.prefTraxrootTokenExpiry,
      expiry.millisecondsSinceEpoch,
    );

    return token;
  }
}

/// Datasource for fetching Traxroot objects and data.
class TraxrootObjectsDatasource {
  TraxrootObjectsDatasource(this._authDatasource);

  final TraxrootAuthDatasource _authDatasource;

  /// Gets the status of a specific object by ID.
  Future<TraxrootObjectStatusModel> getObjectStatus({
    required int objectId,
  }) async {
    final uri = Uri.parse(Variables.getTraxrootObjectStatusEndpoint(objectId));
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getObjectStatus',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getObjectStatus',
        level: 1200,
      );
      return TraxrootObjectStatusModel();
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      return TraxrootObjectStatusModel();
    }
    final map = _extractSingleStatus(decoded);
    return TraxrootObjectStatusModel.fromMap(map);
  }

  /// Gets the status of all objects.
  Future<List<TraxrootObjectStatusModel>> getAllObjectsStatus() async {
    log(
      'Fetching /ObjectsStatus - Request started',
      name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
      level: 800,
    );

    final uri = Uri.parse(Variables.traxrootObjectsStatusEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'Fetching /ObjectsStatus - Response status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        'Fetching /ObjectsStatus - Failed with status ${response.statusCode}: ${response.body}',
        name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
        level: 1200,
      );
      return [];
    }

    try {
      dynamic decoded = _decodeTraxrootBody(response.body);

      // Some Traxroot responses wrap JSON in strings; try decoding again if needed
      if (decoded is String) {
        dynamic reparsed =
            _decodeTraxrootBody(decoded) ?? _attemptJsonDecode(decoded);

        // If still null, try to salvage by taking the substring between
        // the first '{' and the last '}' – this often strips trailing junk.
        if (reparsed == null) {
          final raw = decoded;
          final start = raw.indexOf('{');
          final end = raw.lastIndexOf('}');
          if (start != -1 && end > start) {
            final candidate = raw.substring(start, end + 1);
            reparsed = _attemptJsonDecode(candidate);
          }
        }

        if (reparsed != null) {
          decoded = reparsed;
        } else {
          final snippet = decoded.length > 200
              ? decoded.substring(0, 200)
              : decoded;
          log(
            'Parsing /ObjectsStatus - Decoded body is still String after reparsing. Snippet: $snippet',
            name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
            level: 1000,
          );
        }
      }

      if (decoded == null) {
        log(
          'Parsing /ObjectsStatus - Failed to decode response body',
          name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
          level: 1200,
        );
        return [];
      }

      log(
        'Parsing /ObjectsStatus - Decoded response type: ${decoded.runtimeType}',
        name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
        level: 800,
      );

      // Log the structure to understand what we're receiving
      if (decoded is Map<String, dynamic>) {
        log(
          'Parsing /ObjectsStatus - Response keys: ${decoded.keys.toList()}',
          name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
          level: 800,
        );

        // Check if points exist and log its type/length
        final pointsRaw = decoded['points'] ?? decoded['Points'];
        if (pointsRaw != null) {
          log(
            'Parsing /ObjectsStatus - Found points field, type: ${pointsRaw.runtimeType}',
            name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
            level: 800,
          );
          if (pointsRaw is List) {
            log(
              'Parsing /ObjectsStatus - Points array length: ${pointsRaw.length}',
              name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
              level: 800,
            );
          }
        } else {
          log(
            'Parsing /ObjectsStatus - No "points" or "Points" field found in response',
            name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
            level: 1000,
          );
        }
      }

      log(
        'Parsing /ObjectsStatus - Extracting points array via _extractStatusList',
        name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
        level: 800,
      );

      final list = _extractStatusList(decoded);

      log(
        'Parsing /ObjectsStatus - Extracted ${list.length} status objects from points array',
        name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
        level: 800,
      );

      // If we got 0 results, log the first few items to debug
      if (list.isEmpty && decoded is Map) {
        log(
          'Parsing /ObjectsStatus - WARNING: 0 items extracted. Raw decoded keys: ${decoded.keys.take(10).toList()}',
          name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
          level: 1000,
        );
      }

      final result = list.map(TraxrootObjectStatusModel.fromMap).toList();

      log(
        'Fetching /ObjectsStatus - Success: Parsed ${result.length} vehicle statuses',
        name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
        level: 800,
      );

      return result;
    } catch (e, st) {
      log(
        'Parsing /ObjectsStatus - Exception during parsing: $e',
        name: 'TraxrootObjectsDatasource.getAllObjectsStatus',
        level: 1200,
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final uri = Uri.parse(Variables.traxrootObjectsStatusEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getAllEvents',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getAllEvents',
        level: 1200,
      );
      return const [];
    }

    final decoded = _decodeTraxrootBody(response.body);

    // Normal path: decoded body is a map with an events array
    if (decoded is Map<String, dynamic>) {
      final eventsRaw = decoded['events'] ?? decoded['Events'];
      final eventsList = _normalizeDynamicList(eventsRaw);
      return eventsList;
    }

    // Special case: body is still a String with loose JSON containing
    // an "events" array, similar to how points are embedded.
    if (decoded is String && decoded.contains('"events"')) {
      final raw = decoded;

      // Extract all event objects that have trackerid + typedesc/text
      final regex = RegExp(
        r'\{[^{}]*"trackerid"[^{}]*"type"[^{}]*"text"[^{}]*\}',
      );
      final matches = regex.allMatches(raw).toList();
      if (matches.isEmpty) {
        return const [];
      }

      final results = <Map<String, dynamic>>[];
      for (final m in matches) {
        final text = m.group(0);
        if (text == null) continue;
        final parsed = _attemptJsonDecode(text);
        if (parsed is Map) {
          final map = _normalizeDynamicMap(parsed);
          if (map != null) {
            results.add(map);
          }
        }
      }

      log(
        'Parsing /ObjectsStatus.events - Extracted ${results.length} events from String payload via regex',
        name: 'TraxrootObjectsDatasource.getAllEvents',
        level: 800,
      );

      return results;
    }

    return const [];
  }

  Future<TraxrootObjectStatusModel?> getLatestPoint({
    required int objectId,
  }) async {
    final uri = Uri.parse(
      '${Variables.traxrootObjectsStatusEndpoint}/$objectId',
    );
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getLatestPoint',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getLatestPoint',
        level: 1200,
      );
      return null;
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      return null;
    }

    final list = _extractStatusList(decoded);
    if (list.isEmpty) {
      return null;
    }

    return TraxrootObjectStatusModel.fromMap(list.first);
  }

  Future<List<TraxrootObjectModel>> getObjects() async {
    final uri = Uri.parse(Variables.traxrootObjectsEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getObjects',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getObjects',
        level: 1200,
      );
      return [];
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      return [];
    }

    final list = _normalizeDynamicList(decoded);
    if (list.isEmpty) {
      return const [];
    }

    return list.map(TraxrootObjectModel.fromMap).toList();
  }

  Future<List<TraxrootIconModel>> getObjectIcons() async {
    final uri = Uri.parse(Variables.traxrootObjectIconsEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getObjectIcons',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getObjectIcons',
        level: 1200,
      );
      return [];
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      return [];
    }

    final list = _normalizeDynamicList(decoded);
    if (list.isEmpty) {
      return const [];
    }

    return list.map(TraxrootIconModel.fromMap).toList();
  }

  Future<List<TraxrootDriverModel>> getDrivers() async {
    final uri = Uri.parse(Variables.traxrootDriversEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getDrivers',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getDrivers',
        level: 1200,
      );
      return [];
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      return [];
    }

    final list = _normalizeDynamicList(decoded);
    if (list.isEmpty) {
      return const [];
    }

    return list.map((map) => TraxrootDriverModel.fromMap(map)).toList();
  }

  Future<List<TraxrootGeozoneModel>> getGeozones() async {
    final uri = Uri.parse(Variables.traxrootGeozonesEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getGeozones',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getGeozones',
        level: 1200,
      );
      return [];
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      return [];
    }

    final list = _normalizeDynamicList(decoded);
    if (list.isEmpty) {
      return const [];
    }

    return list.map(TraxrootGeozoneModel.fromMap).toList();
  }

  Future<List<TraxrootIconModel>> getGeozoneIcons() async {
    final uri = Uri.parse(Variables.traxrootGeozoneIconsEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getGeozoneIcons',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getGeozoneIcons',
        level: 1200,
      );
      return [];
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      return [];
    }

    final list = _normalizeDynamicList(decoded);
    if (list.isEmpty) {
      return const [];
    }

    return list.map(TraxrootIconModel.fromMap).toList();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final uri = Uri.parse(Variables.traxrootProfileEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getProfile',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootObjectsDatasource.getProfile',
        level: 1200,
      );
      return {};
    }

    dynamic decoded = _decodeTraxrootBody(response.body);

    // Some Traxroot responses wrap JSON in strings; try decoding again if needed
    if (decoded is String) {
      final reparsed =
          _decodeTraxrootBody(decoded) ?? _attemptJsonDecode(decoded);
      if (reparsed != null) {
        decoded = reparsed;
      }
    }

    if (decoded is! Map<String, dynamic>) {
      log(
        'Unexpected profile payload type: ${decoded.runtimeType}',
        name: 'TraxrootObjectsDatasource.getProfile',
        level: 1200,
      );
      return {};
    }

    return decoded;
  }

  Future<List<TraxrootObjectGroupModel>> getObjectGroups() async {
    final profile = await getProfile();

    // Extract objectgroups from profile response
    final objectgroups = profile['objectgroups'];
    if (objectgroups != null) {
      final list = _normalizeDynamicList(objectgroups);
      log(
        'Object groups found: ${list.length}',
        name: 'TraxrootObjectsDatasource.getObjectGroups',
        level: 800,
      );
      return list.map(TraxrootObjectGroupModel.fromMap).toList();
    }

    log(
      'No objectgroups found in response',
      name: 'TraxrootObjectsDatasource.getObjectGroups',
      level: 1000,
    );
    return const [];
  }

  /// Get object with sensors/trends data
  Future<TraxrootObjectStatusModel?> getObjectWithSensors({
    required int objectId,
  }) async {
    // Get both objects list and status in parallel
    final results = await Future.wait([
      getObjects(),
      getObjectStatus(objectId: objectId),
    ]);

    final objectsList = results[0] as List<TraxrootObjectModel>;
    final status = results[1] as TraxrootObjectStatusModel;

    // Find the object with matching ID
    final objectData = objectsList.firstWhere(
      (obj) => obj.id == objectId,
      orElse: () => const TraxrootObjectModel(),
    );

    if (objectData.id == null) {
      return status;
    }

    // Get sensor metadata from object's raw data or trends field
    final rawData = objectData.raw;

    log(
      'Object ID: $objectId, Has trends field: ${objectData.trends.isNotEmpty}, Raw keys: ${rawData.keys.toList()}',
      name: 'TraxrootObjectsDatasource.getObjectWithSensors',
      level: 800,
    );

    // Try to get trends from multiple possible locations
    dynamic trendsData = objectData.trends.isNotEmpty
        ? objectData.trends
        : (rawData['trends'] ?? rawData['Trends']);

    // If trends not found, check for nested structures
    if (trendsData == null || (trendsData is List && trendsData.isEmpty)) {
      // Check in 'main' or other nested objects
      if (rawData['main'] is Map) {
        trendsData = rawData['main']['trends'];
      }
    }

    log(
      'Trends data found: ${trendsData != null}, Count: ${trendsData is List ? trendsData.length : 0}',
      name: 'TraxrootObjectsDatasource.getObjectWithSensors',
      level: 800,
    );

    if (trendsData == null || (trendsData is List && trendsData.isEmpty)) {
      log(
        'No trends data found for object $objectId',
        name: 'TraxrootObjectsDatasource.getObjectWithSensors',
        level: 1000,
      );
      return status;
    }

    final sensorMetadata = _normalizeDynamicList(trendsData);

    log(
      'Sensor metadata count: ${sensorMetadata.length}',
      name: 'TraxrootObjectsDatasource.getObjectWithSensors',
      level: 800,
    );

    // Create sensor models from trends metadata
    // Only include sensors that have unique/meaningful data (name, units)
    // Do not add placeholder values - only show real data from API
    final sensors = sensorMetadata
        .map((t) {
          final sensorMap = Map<String, dynamic>.from(t);
          return TraxrootSensorModel.fromMap(sensorMap);
        })
        .where((sensor) {
          // Only include sensors with name (metadata from trends)
          final hasName = sensor.name != null && sensor.name!.isNotEmpty;

          return hasName;
        })
        .toList();

    return status.copyWith(sensors: sensors);
  }

  Future<http.Response> _authorizedGet(Uri uri) async {
    Future<http.Response> performRequest({required bool forceRefresh}) async {
      final token = await _authDatasource.getAccessToken(
        forceRefresh: forceRefresh,
      );
      return http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }

    var response = await performRequest(forceRefresh: false);
    if (response.statusCode == 401) {
      log(
        'Unauthorized response for ${uri.path}. Refreshing token and retrying.',
        name: 'TraxrootObjectsDatasource',
        level: 900,
      );
      await _authDatasource.clearCachedToken();
      response = await performRequest(forceRefresh: true);
    }
    return response;
  }
}

Map<String, dynamic> _extractSingleStatus(dynamic payload) {
  final candidates = _extractStatusList(payload);
  if (candidates.isNotEmpty) {
    return candidates.first;
  }
  final unwrapped = _unwrapTraxrootPayload(payload);
  if (unwrapped is Map<String, dynamic>) {
    return Map<String, dynamic>.from(unwrapped);
  }
  return {};
}

List<Map<String, dynamic>> _extractStatusList(dynamic payload) {
  // Special case: some /ObjectsStatus responses come back as a *string* that
  // contains a JSON object like {"points":[{...},{...}]}. Our generic
  // decoders can fail on this, so we try a lightweight manual extractor.
  if (payload is String && payload.contains('"points"')) {
    final raw = payload;

    // Find all point objects that contain trackerid + lat + lng so we only
    // capture coordinate-bearing entries, not plain stat records.
    final regex = RegExp(r'\{[^{}]*"trackerid"[^{}]*"lat"[^{}]*"lng"[^{}]*\}');
    final matches = regex.allMatches(raw).toList();
    if (matches.isNotEmpty) {
      final results = <Map<String, dynamic>>[];
      for (final m in matches) {
        final text = m.group(0);
        if (text == null) continue;
        final decoded = _attemptJsonDecode(text);
        if (decoded is Map) {
          final map = _normalizeDynamicMap(decoded);
          if (map != null && _looksLikeStatus(map)) {
            results.add(map);
          }
        }
      }
      if (results.isNotEmpty) {
        log(
          'Parsing /ObjectsStatus - Extracted ${results.length} point objects from String payload via regex',
          name: 'TraxrootObjectsDatasource._extractStatusList',
          level: 800,
        );
        return results;
      }
    }
  }

  // If the raw payload is a map, try merging points with stats FIRST,
  // so we don't lose iconId/ObjectId due to aggressive unwrapping.
  if (payload is Map<String, dynamic>) {
    final mergedFromRaw = _mergePointsWithStats(payload);
    if (mergedFromRaw.isNotEmpty) {
      return mergedFromRaw;
    }
  }

  final unwrapped = _unwrapTraxrootPayload(payload);

  final directCandidates = _normalizeDynamicList(unwrapped);
  final directStatuses = directCandidates.where(_looksLikeStatus).toList();
  if (directStatuses.isNotEmpty) {
    return directStatuses
        .map((map) => Map<String, dynamic>.from(map))
        .toList(growable: false);
  }

  if (unwrapped is Map<String, dynamic>) {
    final merged = _mergePointsWithStats(unwrapped);
    if (merged.isNotEmpty) {
      return merged;
    }

    for (final entry in unwrapped.entries) {
      final nestedList = _extractStatusList(entry.value);
      if (nestedList.isNotEmpty) {
        return nestedList;
      }
    }
  }

  if (unwrapped is List) {
    for (final element in unwrapped) {
      final nestedList = _extractStatusList(element);
      if (nestedList.isNotEmpty) {
        return nestedList;
      }
    }
  }

  return const [];
}

dynamic _unwrapTraxrootPayload(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      final decoded = _decodeLooseJson(trimmed);
      if (decoded != null) {
        return _unwrapTraxrootPayload(decoded);
      }
    }
    return value;
  }
  if (value is Map<String, dynamic>) {
    const priorityKeys = [
      'Data',
      'data',
      'Result',
      'result',
      'Payload',
      'payload',
      'Items',
      'items',
      'Response',
      'response',
      'Objects',
      'objects',
      'ObjectsStatus',
      'objectsStatus',
      'Points',
      'points',
      'IOPoints',
      'iopoints',
    ];
    for (final key in priorityKeys) {
      if (value.containsKey(key)) {
        final nested = value[key];
        if (nested != null) {
          final unwrapped = _unwrapTraxrootPayload(nested);
          if (unwrapped != null) {
            return unwrapped;
          }
        }
      }
    }
    for (final entry in value.entries) {
      final nested = _unwrapTraxrootPayload(entry.value);
      if (nested is List) {
        return nested;
      }
    }
    return value;
  }
  return value;
}

bool _looksLikeStatus(Map<String, dynamic> map) {
  const possibleKeys = {
    'Latitude',
    'latitude',
    'Lat',
    'lat',
    'Longitude',
    'longitude',
    'Lon',
    'lon',
    'Lng',
    'lng',
    'Id',
    'id',
    'ObjectId',
    'objectId',
    'Name',
    'name',
    'ObjectName',
    'objectName',
    'trackerid',
    'TrackerId',
    'trackerId',
  };
  return map.keys.any(possibleKeys.contains);
}

List<Map<String, dynamic>> _normalizeDynamicList(dynamic value) {
  if (value == null) {
    return const [];
  }
  if (value is String) {
    final trimmed = value.trim();
    if ((trimmed.startsWith('[') && trimmed.endsWith(']')) ||
        (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
      final decoded = _decodeLooseJson(trimmed);
      if (decoded != null) {
        return _normalizeDynamicList(decoded);
      }
    }
    return const [];
  }
  if (value is List) {
    final results = <Map<String, dynamic>>[];
    for (final element in value) {
      final map = _normalizeDynamicMap(element);
      if (map != null) {
        results.add(map);
      }
    }
    return results;
  }
  final map = _normalizeDynamicMap(value);
  if (map != null) {
    return [map];
  }
  return const [];
}

Map<String, dynamic>? _normalizeDynamicMap(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      final decoded = _decodeLooseJson(trimmed);
      if (decoded != null) {
        return _normalizeDynamicMap(decoded);
      }
    }
    return null;
  }
  if (value is Map) {
    final result = <String, dynamic>{};
    value.forEach((key, v) {
      final normalizedKey = key is String ? key : key.toString();
      result[normalizedKey] = v;
    });
    return result;
  }
  return null;
}

dynamic _decodeLooseJson(String source) {
  final attempt = _attemptJsonDecode(source);
  if (attempt != null) {
    return attempt;
  }
  final repaired = _repairLooseJson(source);
  if (repaired == null) {
    return null;
  }
  return _attemptJsonDecode(repaired);
}

dynamic _attemptJsonDecode(String source) {
  try {
    return jsonDecode(source);
  } catch (_) {
    return null;
  }
}

String? _repairLooseJson(String input) {
  var result = input;
  var changed = false;

  final singleQuotedKeys = RegExp(r"(?<=\{|,)(\s*)'([^']+)'\s*:(\s*)");
  result = result.replaceAllMapped(singleQuotedKeys, (match) {
    changed = true;
    final leading = match.group(1) ?? '';
    final key = match.group(2) ?? '';
    final trailing = match.group(3) ?? '';
    final escapedKey = key.replaceAll('"', r'\"');
    return '$leading"$escapedKey":$trailing';
  });

  final bareKeys = RegExp(r"(?<=\{|,)(\s*)([A-Za-z0-9_]+)\s*:(\s*)");
  result = result.replaceAllMapped(bareKeys, (match) {
    changed = true;
    final leading = match.group(1) ?? '';
    final key = match.group(2) ?? '';
    final trailing = match.group(3) ?? '';
    return '$leading"$key":$trailing';
  });

  final singleQuotedValues = RegExp(r"(?<=[:\[,]\s*)'([^']*)'");
  result = result.replaceAllMapped(singleQuotedValues, (match) {
    changed = true;
    final value = match.group(1)?.replaceAll('"', r'\"') ?? '';
    return '"$value"';
  });

  final boolValues = RegExp(r":\s*(True|False)(?=[,\}\]])");
  result = result.replaceAllMapped(boolValues, (match) {
    changed = true;
    return ':${match.group(1)!.toLowerCase()}';
  });

  final nullValues = RegExp(r":\s*(Null|NULL)(?=[,\}\]])");
  result = result.replaceAllMapped(nullValues, (_) {
    changed = true;
    return ':null';
  });

  final nonNumeric = RegExp(r":\s*(NaN|nan|Infinity|-Infinity)(?=[,\}\]])");
  result = result.replaceAllMapped(nonNumeric, (_) {
    changed = true;
    return ':null';
  });

  return changed ? result : null;
}

dynamic _decodeTraxrootBody(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final decoded = _decodeLooseJson(trimmed);
  if (decoded != null) {
    return decoded;
  }
  try {
    return jsonDecode(trimmed);
  } catch (_) {
    return null;
  }
}

List<Map<String, dynamic>> _mergePointsWithStats(Map<String, dynamic> payload) {
  final pointsRaw = payload['points'] ?? payload['Points'];

  log(
    '_mergePointsWithStats - pointsRaw type: ${pointsRaw.runtimeType}, isNull: ${pointsRaw == null}',
    name: 'TraxrootObjectsDatasource._mergePointsWithStats',
    level: 800,
  );

  final points = _normalizeDynamicList(pointsRaw);

  log(
    '_mergePointsWithStats - Normalized points list length: ${points.length}',
    name: 'TraxrootObjectsDatasource._mergePointsWithStats',
    level: 800,
  );

  if (points.isEmpty) {
    log(
      '_mergePointsWithStats - Points array is empty, returning empty list',
      name: 'TraxrootObjectsDatasource._mergePointsWithStats',
      level: 900,
    );
    return const [];
  }

  final statsRaw =
      payload['stat'] ??
      payload['Stat'] ??
      payload['stats'] ??
      payload['Stats'];
  final stats = _normalizeDynamicList(statsRaw);
  final statsByTracker = <String, Map<String, dynamic>>{};
  for (final stat in stats) {
    final tracker = _trackerKey(stat);
    if (tracker != null && tracker.isNotEmpty) {
      statsByTracker[tracker] = stat;
    }
  }

  log(
    '_mergePointsWithStats - Processing ${points.length} points, ${stats.length} stats',
    name: 'TraxrootObjectsDatasource._mergePointsWithStats',
    level: 800,
  );

  final merged = <Map<String, dynamic>>[];
  int filteredOut = 0;

  for (final point in points) {
    final tracker = _trackerKey(point);
    final combined = <String, dynamic>{};
    if (tracker != null) {
      final stat = statsByTracker[tracker];
      if (stat != null) {
        combined.addAll(stat);
      }
    }
    combined.addAll(point);

    if (!combined.containsKey('status') && combined['stat'] is String) {
      combined['status'] = combined['stat'];
    }

    if (_looksLikeStatus(combined)) {
      merged.add(combined);
    } else {
      filteredOut++;
      if (filteredOut <= 3) {
        // Log first 3 filtered items to see why they don't pass
        log(
          '_mergePointsWithStats - Point filtered out (does not look like status). Keys: ${combined.keys.toList()}',
          name: 'TraxrootObjectsDatasource._mergePointsWithStats',
          level: 900,
        );
      }
    }
  }

  log(
    '_mergePointsWithStats - Merged ${merged.length} valid status objects, filtered out $filteredOut',
    name: 'TraxrootObjectsDatasource._mergePointsWithStats',
    level: 800,
  );

  return merged;
}

String? _trackerKey(Map<String, dynamic> map) {
  final candidates = [
    map['trackerid'],
    map['TrackerId'],
    map['trackerId'],
    map['TrackerID'],
    map['trackerID'],
    map['id'],
    map['Id'],
    map['objectId'],
    map['ObjectId'],
  ];

  for (final candidate in candidates) {
    final text = _asNonEmptyString(candidate);
    if (text != null) {
      return text;
    }
  }
  return null;
}

String? _asNonEmptyString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  final text = value.toString();
  return text.isEmpty ? null : text;
}

class TraxrootInternalDatasource {
  TraxrootInternalDatasource([TraxrootAuthDatasource? authDatasource])
    : _authDatasource = authDatasource ?? TraxrootAuthDatasource();

  final TraxrootAuthDatasource _authDatasource;

  Future<List<TraxrootDriverModel>> getDrivers() async {
    final response = await _authorizedGet(
      Uri.parse(Variables.traxrootDriversEndpoint),
    );

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootInternalDatasource.getDrivers',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootInternalDatasource.getDrivers',
        level: 1200,
      );
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map(
            (e) => TraxrootDriverModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return [];
  }

  Future<TraxrootDriverModel> getDriverById(int driverId) async {
    final response = await _authorizedGet(
      Uri.parse(Variables.getTraxrootDriverEndpoint(driverId)),
    );

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootInternalDatasource.getDriverById',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootInternalDatasource.getDriverById',
        level: 1200,
      );
      return TraxrootDriverModel();
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return TraxrootDriverModel.fromMap(decoded);
    }
    return TraxrootDriverModel();
  }

  Future<List<TraxrootGeozoneModel>> getGeozones() async {
    final response = await _authorizedGet(
      Uri.parse(Variables.traxrootGeozonesEndpoint),
    );

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootInternalDatasource.getGeozones',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootInternalDatasource.getGeozones',
        level: 1200,
      );
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map(
            (e) => TraxrootGeozoneModel.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return [];
  }

  Future<List<TraxrootIconModel>> getGeozoneIcons() async {
    final response = await _authorizedGet(
      Uri.parse(Variables.traxrootGeozoneIconsEndpoint),
    );

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootInternalDatasource.getGeozoneIcons',
      level: 800,
    );

    if (response.statusCode != 200) {
      log(
        response.body,
        name: 'TraxrootInternalDatasource.getGeozoneIcons',
        level: 1200,
      );
      return [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .map(
            (e) =>
                TraxrootIconModel.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }
    return [];
  }

  Future<http.Response> _authorizedGet(Uri uri) async {
    Future<http.Response> performRequest({required bool forceRefresh}) async {
      final token = await _authDatasource.getAccessToken(
        forceRefresh: forceRefresh,
      );
      return http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }

    var response = await performRequest(forceRefresh: false);
    if (response.statusCode == 401) {
      log(
        'Unauthorized response for ${uri.path}. Refreshing token and retrying.',
        name: 'TraxrootInternalDatasource',
        level: 900,
      );
      await _authDatasource.clearCachedToken();
      response = await performRequest(forceRefresh: true);
    }
    return response;
  }
}
