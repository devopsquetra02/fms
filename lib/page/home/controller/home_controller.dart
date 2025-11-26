import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/core/models/geo.dart';
import 'package:fms/data/datasource/get_job_datasource.dart';
import 'package:fms/data/datasource/get_job_ongoing_datasource.dart';
import 'package:fms/data/datasource/get_job_history_datasource.dart';
import 'package:fms/data/datasource/traxroot_datasource.dart';
import 'package:fms/data/models/response/get_job_response_model.dart';
import 'package:fms/data/models/response/get_job_ongoing_response_model.dart'
    as ongoing;
import 'package:fms/data/models/traxroot_icon_model.dart';
import 'package:fms/data/models/traxroot_object_model.dart';
import 'package:fms/data/models/traxroot_object_status_model.dart';
import 'package:fms/data/models/traxroot_geozone_model.dart';
import 'package:fms/data/models/response/get_job_history__response_model.dart'
    as history;
import 'dart:developer';
import 'package:fms/core/services/home_widget_service.dart';
import 'package:home_widget/home_widget.dart';
import 'package:fms/core/services/traxroot_credentials_manager.dart';
import 'package:fms/core/navigation/navigation_controller.dart';

/// Controller for the home screen, managing map data, jobs, and vehicle tracking.
class HomeController extends GetxController {
  final _objectsDatasource = TraxrootObjectsDatasource(
    TraxrootAuthDatasource(),
  );
  final _internalDatasource = TraxrootInternalDatasource();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<MapMarkerModel> markers = <MapMarkerModel>[].obs;
  final RxList<MapZoneModel> zones = <MapZoneModel>[].obs;
  final RxList<TraxrootObjectStatusModel> objects =
      <TraxrootObjectStatusModel>[].obs;
  final RxList<TraxrootObjectStatusModel> movingObjects =
      <TraxrootObjectStatusModel>[].obs;
  final Map<int, TraxrootObjectStatusModel> _lastStatusByObjectId = {};
  final Map<int, DateTime> _lastMovementTimeByObjectId = {};
  final Map<int, String> _lastMovementEventIdByObjectId = {};
  final Map<int, String> lastMovementTextByObjectId = {};
  final RxMap<int, String> iconUrlByObjectId = <int, String>{}.obs;
  final Rx<GetJobResponseModel?> allJobsResponse = Rx<GetJobResponseModel?>(
    null,
  );
  final Rx<ongoing.GetJobOngoingResponseModel?> ongoingJobsResponse =
      Rx<ongoing.GetJobOngoingResponseModel?>(null);
  final Rx<history.GetJobHistoryResponseModel?> completedJobsResponse =
      Rx<history.GetJobHistoryResponseModel?>(null);

  static const GeoPoint defaultCenter = GeoPoint(
    14.5995,
    120.9842,
  ); // Manila fallback

  GeoPoint get mapCenter => defaultCenter;

  int get openJobsCount => allJobsResponse.value?.data?.length ?? 0;
  int get ongoingJobsCount => ongoingJobsResponse.value?.data?.length ?? 0;
  int get completedJobsCount => completedJobsResponse.value?.data?.length ?? 0;

  /// Fetches an object with its sensor data.
  Future<TraxrootObjectStatusModel?> getObjectWithSensors(int objectId) {
    return _objectsDatasource.getObjectWithSensors(objectId: objectId);
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// Loads all initial data for the home screen.
  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';

    try {
      final hasTraxrootCreds =
          await TraxrootCredentialsManager.hasCredentials();
      // Check for widget launch
      final widgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (widgetUri != null) {
        _handleWidgetNavigation(widgetUri);
      }

      // Listen for widget clicks while app is running
      HomeWidget.widgetClicked.listen(_handleWidgetNavigation);

      // Always load job-related data
      final allJobsFuture = GetJobDatasource().getJob();
      final ongoingJobsFuture = GetJobOngoingDatasource().getOngoingJobs();
      final completedJobsFuture = GetJobHistoryDatasource().getJobHistory();

      // Conditionally load Traxroot map/vehicle data only when credentials exist
      List<TraxrootObjectModel> objectsData = <TraxrootObjectModel>[];
      List<TraxrootIconModel> icons = <TraxrootIconModel>[];
      List<TraxrootGeozoneModel> geozones = <TraxrootGeozoneModel>[];

      if (hasTraxrootCreds) {
        final objectsFuture = _objectsDatasource.getObjects();
        final iconsFuture = _objectsDatasource.getObjectIcons();
        final geozonesFuture = _internalDatasource.getGeozones();

        objectsData = await objectsFuture;
        icons = await iconsFuture;
        geozones = await geozonesFuture;
      } else {
        error.value =
            'Unable to load map: Traxroot credentials are not configured. Please contact your administrator.';
      }

      final allJobs = await allJobsFuture;
      final ongoingJobs = await ongoingJobsFuture;
      final completedJobs = await completedJobsFuture;

      // Fetch all object IDs to get their status
      final objectIds = objectsData
          .where((obj) => obj.id != null)
          .map((obj) => obj.id!)
          .toList();

      // Fetch all statuses in parallel
      final statusFutures = objectIds.map(
        (id) => _objectsDatasource
            .getLatestPoint(objectId: id)
            .catchError((_) => null),
      );
      final allStatuses = await Future.wait(statusFutures);

      // Build status map by object ID
      final statusByObjectId = <int, TraxrootObjectStatusModel>{};
      for (var i = 0; i < objectIds.length; i++) {
        final status = allStatuses[i];
        if (status != null) {
          statusByObjectId[objectIds[i]] = status;
        }
      }

      final iconsById = <int, TraxrootIconModel>{
        for (final icon in icons)
          if (icon.id != null) icon.id!: icon,
      };

      final iconUrlMap = <int, String>{};
      final iconUrlByObjectName = <String, String>{};
      final iconUrlByTrackerId = <String, String>{};
      final trackersByObject = <int, Set<String>>{};

      for (final object in objectsData) {
        final objectId = object.id;
        if (objectId == null) continue;

        final iconId = object.iconId;
        if (iconId == null) continue;

        final iconUrl = iconsById[iconId]?.url;
        if (iconUrl != null && iconUrl.isNotEmpty) {
          iconUrlMap[objectId] = iconUrl;
          final name = object.name;
          if (name != null && name.isNotEmpty) {
            iconUrlByObjectName[name] = iconUrl;
          }

          void collectTrackers(dynamic node) {
            if (node is Map) {
              for (final entry in node.entries) {
                final key = '${entry.key}'.toLowerCase();
                final value = entry.value;
                if (key.contains('tracker') || key.contains('imei')) {
                  final text = value?.toString().trim();
                  if (text != null && text.isNotEmpty) {
                    iconUrlByTrackerId.putIfAbsent(text, () => iconUrl);
                    trackersByObject
                        .putIfAbsent(objectId, () => <String>{})
                        .add(text);
                  }
                }
                collectTrackers(value);
              }
            } else if (node is List) {
              for (final v in node) {
                collectTrackers(v);
              }
            }
          }

          collectTrackers(object.raw);
        }
      }

      // Build markers from /Objects (name, id, iconId) + extracted statuses (lat, lng)
      final markersList = <MapMarkerModel>[];
      final usedIconUrls = <String>{};
      final statusList = <TraxrootObjectStatusModel>[];

      for (final object in objectsData) {
        final objectId = object.id;
        if (objectId == null) continue;

        final objectName = object.name;
        final objectIconId = object.iconId;
        final iconUrl = objectIconId != null
            ? iconsById[objectIconId]?.url
            : null;

        if (iconUrl != null && iconUrl.isNotEmpty) {
          usedIconUrls.add(iconUrl);
        }

        // Get status from the map we built earlier
        final statusPoint = statusByObjectId[objectId];
        if (statusPoint == null) continue;

        final lat = statusPoint.latitude;
        final lon = statusPoint.longitude;
        if (lat == null || lon == null || (lat == 0.0 && lon == 0.0)) {
          continue;
        }

        // Compose status model with data from both endpoints
        // IMPORTANT: trackerId should match the trackerid field from /ObjectsStatus
        // Usually this is the object's ID as a string
        final trackerId = statusPoint.trackerId ?? objectId.toString();

        // log(
        //   'Initial Load - Object id=$objectId, name=$objectName, trackerId from API=${statusPoint.trackerId}, using trackerId=$trackerId',
        //   name: 'HomeController.loadData',
        //   level: 800,
        // );

        final composed = TraxrootObjectStatusModel(
          id: objectId,
          name: objectName,
          trackerId: trackerId,
          latitude: lat,
          longitude: lon,
          address: statusPoint.address,
          speed: statusPoint.speed,
          course: statusPoint.course,
          altitude: statusPoint.altitude,
          status: statusPoint.status,
          updatedAt: statusPoint.updatedAt,
          satellites: statusPoint.satellites,
          accuracy: statusPoint.accuracy,
          iconId: objectIconId,
        );

        statusList.add(composed);
        final marker = composed.toMarker(icon: iconUrl);
        if (marker != null) {
          markersList.add(marker);
        }
      }

      final zonesList = <MapZoneModel>[];
      for (final geozone in geozones) {
        final zoneModel = geozone.toZoneModel();
        if (zoneModel != null) {
          zonesList.add(zoneModel);
        }
      }

      markers.value = markersList;
      zones.value = zonesList;
      objects.value = statusList;
      iconUrlByObjectId.value = iconUrlMap;
      await _detectMovement(statusList);
      allJobsResponse.value = allJobs;
      ongoingJobsResponse.value = ongoingJobs;
      completedJobsResponse.value = completedJobs;
      isLoading.value = false;

      _precacheIcons(usedIconUrls);
      _updateWidgets();
      if (error.value.isEmpty) {
        final authError = TraxrootAuthDatasource.lastErrorMessage;
        if (authError != null &&
            authError.toLowerCase().contains('invalid username or password')) {
          error.value =
              'Unable to load map: Traxroot credentials are invalid. Please contact your administrator.';
        }
      }
    } catch (e) {
      // On any Traxroot failure, keep job data but clear map-related state
      markers.clear();
      zones.clear();
      objects.clear();
      iconUrlByObjectId.clear();

      isLoading.value = false;

      final msg = e.toString();
      if (msg.toLowerCase().contains('invalid username or password')) {
        error.value =
            'Unable to load map: Traxroot credentials are invalid. Please contact your administrator.';
      } else {
        final authError = TraxrootAuthDatasource.lastErrorMessage;
        if (authError != null &&
            authError.toLowerCase().contains('invalid username or password')) {
          error.value =
              'Unable to load map: Traxroot credentials are invalid. Please contact your administrator.';
        } else {
          error.value = 'Failed to load map data. Please try again later.';
        }
      }
      // No Get.snackbar here to avoid Overlay-related errors; HomeTab already
      // displays error text under the map using controller.error.
    }
  }

  void _precacheIcons(Set<String> urls) {
    if (urls.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = Get.context;
        if (context != null) {
          for (final url in urls) {
            precacheImage(NetworkImage(url), context);
          }
        }
      });
    }
  }

  /// Refreshes the status of tracked objects.
  Future<void> refreshStatuses() async {
    if (objects.isEmpty) {
      return;
    }

    try {
      log(
        'Live Tracking - Refresh started for ${objects.length} tracked vehicles',
        name: 'HomeController.refreshStatuses',
        level: 800,
      );

      final allStatuses = await _objectsDatasource.getAllObjectsStatus();

      if (allStatuses.isEmpty) {
        log(
          'Live Tracking - No statuses received from /ObjectsStatus',
          name: 'HomeController.refreshStatuses',
          level: 900,
        );
        return;
      }

      log(
        'Live Tracking - Received ${allStatuses.length} statuses from /ObjectsStatus',
        name: 'HomeController.refreshStatuses',
        level: 800,
      );

      // Build map by trackerId since /ObjectsStatus returns trackerid, not object ID
      final statusByTrackerId = <String, TraxrootObjectStatusModel>{};
      for (final status in allStatuses) {
        final trackerId = status.trackerId?.trim();
        if (trackerId != null && trackerId.isNotEmpty) {
          statusByTrackerId[trackerId] = status;
        }
      }

      log(
        'Mapping trackerid - Built map with ${statusByTrackerId.length} unique trackerIds',
        name: 'HomeController.refreshStatuses',
        level: 800,
      );

      // Log first 5 trackerIds to verify format
      final sampleTrackerIds = statusByTrackerId.keys.take(5).toList();
      if (sampleTrackerIds.isNotEmpty) {
        log(
          'Mapping trackerid - Sample trackerIds from /ObjectsStatus: $sampleTrackerIds',
          name: 'HomeController.refreshStatuses',
          level: 800,
        );
      }

      final updatedStatuses = <TraxrootObjectStatusModel>[];
      final updatedMarkers = <MapMarkerModel>[];
      final usedIconUrls = <String>{};
      int matchedCount = 0;
      int unmatchedCount = 0;
      int positionChangedCount = 0;

      for (final previous in objects) {
        final objectId = previous.id;
        if (objectId == null) {
          continue;
        }

        // Try to find matching status by trackerId
        TraxrootObjectStatusModel? latest;
        final previousTrackerId = previous.trackerId?.trim();
        if (previousTrackerId != null && previousTrackerId.isNotEmpty) {
          latest = statusByTrackerId[previousTrackerId];

          if (latest != null) {
            matchedCount++;

            // Check if position changed
            final posChanged =
                previous.latitude != latest.latitude ||
                previous.longitude != latest.longitude;
            final angChanged = previous.course != latest.course;

            if (posChanged || angChanged) {
              positionChangedCount++;
              log(
                'Position Update - Vehicle objectId=$objectId, trackerId=$previousTrackerId: '
                'lat: ${previous.latitude} → ${latest.latitude}, '
                'lng: ${previous.longitude} → ${latest.longitude}, '
                'ang: ${previous.course} → ${latest.course}',
                name: 'HomeController.refreshStatuses',
                level: 800,
              );
            }
          } else {
            unmatchedCount++;
            log(
              'Mapping trackerid - No match found for objectId=$objectId, trackerId=$previousTrackerId',
              name: 'HomeController.refreshStatuses',
              level: 900,
            );
          }
        }

        final composed = latest == null
            ? previous
            : previous.copyWith(
                latitude: latest.latitude,
                longitude: latest.longitude,
                speed: latest.speed,
                course: latest.course, // This is the 'ang' field from API
                altitude: latest.altitude,
                status: latest.status,
                address: latest.address,
                updatedAt: latest.updatedAt,
                satellites: latest.satellites,
                accuracy: latest.accuracy,
              );

        updatedStatuses.add(composed);

        final iconUrl = iconUrlByObjectId[objectId];
        if (iconUrl != null && iconUrl.isNotEmpty) {
          usedIconUrls.add(iconUrl);
        }
        final marker = composed.toMarker(icon: iconUrl);
        if (marker != null) {
          updatedMarkers.add(marker);
        }
      }

      log(
        'State Update - Matched: $matchedCount, Unmatched: $unmatchedCount, Position Changed: $positionChangedCount',
        name: 'HomeController.refreshStatuses',
        level: 800,
      );

      markers.value = updatedMarkers;
      objects.value = updatedStatuses;

      log(
        'State Update - Updated ${updatedStatuses.length} vehicle objects and ${updatedMarkers.length} map markers',
        name: 'HomeController.refreshStatuses',
        level: 800,
      );

      await _detectMovement(updatedStatuses);
      _precacheIcons(usedIconUrls);
      _updateWidgets();

      log(
        'Live Tracking - Refresh completed successfully',
        name: 'HomeController.refreshStatuses',
        level: 800,
      );
    } catch (e, st) {
      log(
        'Live Tracking - Error during refresh: ${e.toString()}',
        name: 'HomeController.refreshStatuses',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      // Ignore refresh errors to keep home map stable
    }
  }

  Future<void> _detectMovement(
    List<TraxrootObjectStatusModel> newStatuses,
  ) async {
    final now = DateTime.now();

    if (newStatuses.isEmpty) {
      return;
    }

    // Map trackerId -> latest status so we can attach events to objects
    final statusByTrackerId = <String, TraxrootObjectStatusModel>{};
    for (final status in newStatuses) {
      final tracker = status.trackerId?.trim();
      if (tracker != null && tracker.isNotEmpty) {
        statusByTrackerId[tracker] = status;
      }
    }

    if (statusByTrackerId.isEmpty) {
      return;
    }

    final events = await _objectsDatasource.getAllEvents();
    if (events.isEmpty) {
      // Just apply expiry if no events are available
      final expiry = now.subtract(const Duration(seconds: 3));
      movingObjects.removeWhere((status) {
        final objectId = status.id;
        if (objectId == null) {
          return true;
        }
        final ts = _lastMovementTimeByObjectId[objectId];
        return ts == null || ts.isBefore(expiry);
      });
      return;
    }

    for (final event in events) {
      final rawTrackerId =
          event['trackerid'] ?? event['trackerId'] ?? event['TrackerId'];
      if (rawTrackerId == null) {
        continue;
      }
      final trackerId = rawTrackerId.toString().trim();
      if (trackerId.isEmpty) {
        continue;
      }

      final status = statusByTrackerId[trackerId];
      if (status == null || status.id == null) {
        continue;
      }

      final rawTypeDesc =
          event['typedesc'] ?? event['typeDesc'] ?? event['TypeDesc'];
      final rawText = event['text'] ?? event['Text'];
      final typeDesc = rawTypeDesc?.toString().toUpperCase();
      final text = rawText?.toString().trim() ?? '';

      // Parse event time so we can drop stale events and timestamp notifications
      DateTime? eventTime;
      final rawTime = event['time'];
      if (rawTime is int) {
        try {
          eventTime = DateTime.fromMillisecondsSinceEpoch(rawTime);
        } catch (_) {}
      } else if (rawTime is String) {
        final millis = int.tryParse(rawTime.trim());
        if (millis != null && millis > 0) {
          try {
            eventTime = DateTime.fromMillisecondsSinceEpoch(millis);
          } catch (_) {}
        }
      }

      // Ignore events that are too old compared to now. We keep a generous
      // window (60 seconds) so we don't miss new events between polling
      // intervals, but still avoid replaying very old events on app start.
      final cutoff = now.subtract(const Duration(seconds: 60));
      if (eventTime != null && eventTime.isBefore(cutoff)) {
        continue;
      }

      final isMove =
          typeDesc == 'MOVE' || text.toLowerCase().contains('moving');
      if (!isMove) {
        continue;
      }

      final eventId = event['id']?.toString();
      final objectId = status.id!;
      if (eventId != null) {
        final lastEventId = _lastMovementEventIdByObjectId[objectId];
        if (lastEventId == eventId) {
          // Same event as before, skip to avoid duplicate notifications
          continue;
        }
        _lastMovementEventIdByObjectId[objectId] = eventId;
      }

      // Use the time we *saw* the event (now) for expiry, so notifications
      // disappear a few seconds after being shown, regardless of server time.
      _lastMovementTimeByObjectId[objectId] = now;
      if (text.isNotEmpty) {
        lastMovementTextByObjectId[objectId] = text;
      } else {
        lastMovementTextByObjectId[objectId] = 'is moving';
      }

      log(
        'Movement event: trackerId=$trackerId, objectId=$objectId, type=$typeDesc, text=${lastMovementTextByObjectId[objectId]}',
        name: 'HomeController._detectMovement',
        level: 800,
      );

      final index = movingObjects.indexWhere((e) => e.id == objectId);
      if (index >= 0) {
        movingObjects[index] = status;
        log(
          'Notification - Updated existing notification for vehicle objectId=$objectId',
          name: 'HomeController._detectMovement',
          level: 800,
        );
      } else {
        movingObjects.add(status);
        log(
          'Notification - Triggered new homepage notification for vehicle objectId=$objectId (${status.name ?? trackerId})',
          name: 'HomeController._detectMovement',
          level: 800,
        );
      }
    }

    // Expire notifications after 3 seconds from last detection
    final expiry = now.subtract(const Duration(seconds: 3));
    movingObjects.removeWhere((status) {
      final objectId = status.id;
      if (objectId == null) {
        return true;
      }
      final ts = _lastMovementTimeByObjectId[objectId];
      return ts == null || ts.isBefore(expiry);
    });
  }

  /// Clears the list of moving objects.
  void clearMovementNotification() {
    movingObjects.clear();
    lastMovementTextByObjectId.clear();
  }

  /// Finds the status model associated with a map marker.
  TraxrootObjectStatusModel? findStatusForMarker(MapMarkerModel marker) {
    final data = marker.data;
    if (data is TraxrootObjectStatusModel) {
      return data;
    }

    try {
      return objects.firstWhere(
        (obj) =>
            obj.geoPoint?.lat == marker.position.lat &&
            obj.geoPoint?.lng == marker.position.lng,
      );
    } catch (_) {
      return null;
    }
  }

  void _updateWidgets() {
    final widgetService = HomeWidgetService();

    // Prepare recent jobs (top 3 from all jobs)
    final recentJobs =
        allJobsResponse.value?.data
            ?.take(3)
            .map(
              (job) => {
                'title': job.jobName ?? 'Unknown Job',
                'status': job.typeJobName ?? 'Open',
                'time': job.jobDate?.toIso8601String() ?? '',
              },
            )
            .toList() ??
        [];

    // Update Job Stats
    widgetService.updateJobStats(
      open: openJobsCount,
      ongoing: ongoingJobsCount,
      complete: completedJobsCount,
      recentJobs: recentJobs,
    );

    // Update Map Stats
    widgetService.updateMapStats(
      activeVehicles: markers.length,
      markers: markers,
    );
  }

  void _handleWidgetNavigation(Uri? uri) {
    if (uri == null) return;

    try {
      final navController = Get.find<NavigationController>();

      if (uri.host == 'job') {
        // Navigate to Jobs tab (Index 2)
        navController.changeTab(2);
      } else if (uri.host == 'map') {
        // Navigate to Home/Map tab (Index 0)
        navController.changeTab(0);
      }
    } catch (e) {
      log('NavigationController not found: $e');
    }
  }

  /// Resets the controller state.
  void reset() {
    isLoading.value = false;
    error.value = '';
    markers.clear();
    zones.clear();
    objects.clear();
    iconUrlByObjectId.clear();
    allJobsResponse.value = null;
    ongoingJobsResponse.value = null;
    completedJobsResponse.value = null;
  }
}
