import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';

import '../../../core/models/geo.dart';
import '../../../data/datasource/traxroot_datasource.dart';
import '../../../data/models/traxroot_geozone_model.dart';
import '../../../data/models/traxroot_object_status_model.dart';

/// Controller for handling navigation to a job location.
class JobNavigationController extends GetxController {
  final _objectsDatasource = TraxrootObjectsDatasource(
    TraxrootAuthDatasource(),
  );
  final _internalDatasource = TraxrootInternalDatasource();

  final RxBool isLoading = false.obs;
  final RxList<MapMarkerModel> markers = <MapMarkerModel>[].obs;
  final RxList<MapZoneModel> zones = <MapZoneModel>[].obs;
  final RxnString error = RxnString();

  /// Loads navigation data, including the job marker and surrounding objects/zones.
  Future<List<String>> loadData({
    required GeoPoint jobPoint,
    required String jobName,
    String? address,
  }) async {
    if (isLoading.value) return const [];

    isLoading.value = true;
    error.value = null;

    final jobMarker = MapMarkerModel(
      id: 'job-destination',
      position: jobPoint,
      title: jobName,
      subtitle: address,
    );

    markers.assignAll([jobMarker]);
    zones.clear();

    final objectsStatusFuture = _objectsDatasource.getAllObjectsStatus();
    final geozonesFuture = _internalDatasource.getGeozones();

    final warnings = <String>[];

    List<TraxrootObjectStatusModel> objectsStatus = const [];
    List<TraxrootGeozoneModel> geozones = const [];

    try {
      try {
        objectsStatus = await objectsStatusFuture.timeout(
          const Duration(seconds: 12),
        );
      } on TimeoutException catch (_) {
        warnings.add('Fetching vehicle data takes longer than usual.');
      } catch (e, st) {
        warnings.add('Failed to load vehicle data.');
        log(
          'Failed to load Traxroot object status list',
          name: 'JobNavigationController',
          error: e,
          stackTrace: st,
        );
      }

      try {
        geozones = await geozonesFuture.timeout(const Duration(seconds: 12));
      } on TimeoutException catch (_) {
        warnings.add('Fetching geozone data takes longer than usual.');
      } catch (e, st) {
        warnings.add('Failed to load geozone data.');
        log(
          'Failed to load Traxroot geozones',
          name: 'JobNavigationController',
          error: e,
          stackTrace: st,
        );
      }

      final allMarkers = <MapMarkerModel>[jobMarker];
      for (final object in objectsStatus) {
        final marker = object.toMarker();
        if (marker != null) {
          allMarkers.add(marker);
        }
      }

      final allZones = <MapZoneModel>[];
      for (final geozone in geozones) {
        final zone = geozone.toZoneModel();
        if (zone != null) {
          allZones.add(zone);
        }
      }

      markers.assignAll(allMarkers);
      zones.assignAll(allZones);
      isLoading.value = false;
      error.value = warnings.isEmpty ? null : warnings.join('\n');

      return warnings;
    } catch (e, st) {
      log(
        'Unexpected error while loading navigation data',
        name: 'JobNavigationController',
        error: e,
        stackTrace: st,
      );
      isLoading.value = false;
      error.value = 'Failed to load map data';
      return ['Failed to load map data'];
    }
  }
}
