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

class TraxrootAuthDatasource {
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
      throw Exception('Failed to retrieve Traxroot token');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Traxroot token missing in response');
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

class TraxrootObjectsDatasource {
  TraxrootObjectsDatasource(this._authDatasource);

  final TraxrootAuthDatasource _authDatasource;

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
      throw Exception('Failed to fetch object status');
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      throw Exception('Empty Traxroot object status response');
    }
    final map = _extractSingleStatus(decoded);
    return TraxrootObjectStatusModel.fromMap(map);
  }

  Future<List<TraxrootObjectStatusModel>> getAllObjectsStatus() async {
    final uri = Uri.parse(Variables.traxrootObjectsStatusEndpoint);
    final response = await _authorizedGet(uri);

    log(
      'status: ${response.statusCode}',
      name: 'TraxrootObjectsDatasource.getAll',
      level: 800,
    );
    // log(response.body, name: 'TraxrootObjectsDatasource.getAll', level: 900);

    if (response.statusCode != 200) {
      log(response.body, name: 'TraxrootObjectsDatasource.getAll', level: 1200);
      throw Exception('Failed to fetch objects status list');
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      throw Exception('Empty Traxroot objects status response');
    }
    final list = _extractStatusList(decoded);
    return list.map(TraxrootObjectStatusModel.fromMap).toList();
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
      throw Exception('Failed to fetch object latest point');
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      throw Exception('Empty Traxroot object status response');
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
      throw Exception('Failed to fetch Traxroot objects');
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      throw Exception('Empty Traxroot objects response');
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
      throw Exception('Failed to fetch Traxroot object icons');
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      throw Exception('Empty Traxroot object icons response');
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
      throw Exception('Failed to fetch Traxroot drivers');
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      throw Exception('Empty Traxroot drivers response');
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
      throw Exception('Failed to fetch Traxroot geozones');
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      throw Exception('Empty Traxroot geozones response');
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
      throw Exception('Failed to fetch Traxroot geozone icons');
    }

    final decoded = _decodeTraxrootBody(response.body);
    if (decoded == null) {
      throw Exception('Empty Traxroot geozone icons response');
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
      throw Exception('Failed to fetch Traxroot profile');
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
      throw Exception('Failed to parse profile response');
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

    // Create sensor models with sample values based on sensor type
    final sensors = sensorMetadata.map((t) {
      final sensorMap = Map<String, dynamic>.from(t);
      // Handle both 'itemid' and 'input' field names
      final itemId =
          sensorMap['itemid']?.toString() ??
          sensorMap['input']?.toString() ??
          '';
      final name = sensorMap['name']?.toString() ?? '';

      // Add sample values based on sensor type
      if (!sensorMap.containsKey('value') || sensorMap['value'] == null) {
        sensorMap['value'] = _getSampleSensorValue(itemId, name);
      }

      return TraxrootSensorModel.fromMap(sensorMap);
    }).toList();

    return status.copyWith(sensors: sensors);
  }

  /// Get sample sensor value based on sensor type
  String _getSampleSensorValue(String itemId, String name) {
    final nameLower = name.toLowerCase();

    // Boolean sensors (0 or 1)
    if (nameLower.contains('moving')) {
      return '1'; // Moving
    }
    if (itemId == 'IN239' || nameLower.contains('ignition')) {
      return '1'; // Ignition ON
    }
    if (itemId == 'IN251' || nameLower.contains('idling')) {
      return '0'; // Not idling
    }
    if (itemId == 'IN252' ||
        nameLower.contains('device status') ||
        nameLower.contains('device unplugged')) {
      return '1'; // Device active
    }
    if (itemId == 'IN247' || itemId == 'IN257' || nameLower.contains('crash')) {
      return '0'; // No crash
    }

    // Numeric sensors
    if (itemId == 'IN21' || nameLower.contains('gsm signal')) {
      return '4'; // Signal strength 4/5
    }
    if (itemId == 'IN32' || nameLower.contains('coolant')) {
      return '75'; // 75°C
    }
    if (itemId == 'IN390' || nameLower.contains('fuel')) {
      return '45.5'; // 45.5 Liters
    }
    if (itemId == 'IN36' || nameLower.contains('rpm')) {
      return '1850'; // 1850 RPM
    }
    if (itemId == 'PWR' || nameLower.contains('vehicle battery')) {
      return '13.8'; // 13.8V
    }
    if (itemId == 'BATT' || nameLower.contains('device battery')) {
      return '4.1'; // 4.1V
    }
    if (itemId == 'ACCEL' || nameLower.contains('harsh acceleration')) {
      return '0'; // No harsh acceleration
    }
    if (itemId == 'BREAK_ACCEL' ||
        itemId == 'VACCEL' ||
        nameLower.contains('harsh break')) {
      return '0'; // No harsh braking
    }
    if (itemId == 'TURN_ACCEL' ||
        nameLower.contains('harsh turn') ||
        nameLower.contains('harsh corner')) {
      return '0'; // No harsh cornering
    }
    if (nameLower.contains('intake air')) {
      return '28'; // 28°C
    }

    return ''; // No value
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
  throw Exception('Unexpected Traxroot object status response');
}

List<Map<String, dynamic>> _extractStatusList(dynamic payload) {
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
  final points = _normalizeDynamicList(pointsRaw);
  if (points.isEmpty) {
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

  final merged = <Map<String, dynamic>>[];
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
    }
  }
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
      throw Exception('Failed to fetch drivers');
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
    throw Exception('Unexpected drivers response');
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
      throw Exception('Failed to fetch driver $driverId');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return TraxrootDriverModel.fromMap(decoded);
    }
    throw Exception('Unexpected driver detail response');
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
      throw Exception('Failed to fetch geozones');
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
    throw Exception('Unexpected geozones response');
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
      throw Exception('Failed to fetch geozone icons');
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
    throw Exception('Unexpected geozone icons response');
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
