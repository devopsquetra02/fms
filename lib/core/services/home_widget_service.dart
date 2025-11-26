import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fms/core/models/geo.dart';
import 'package:home_widget/home_widget.dart';
import 'package:fms/core/widgets/widget_map_snapshot.dart';

/// Service for updating home screen widgets (Android/iOS).
class HomeWidgetService {
  static const String appGroupId = 'group.com.querta.fms';
  static const String androidWidgetName = 'JobWidgetProvider';

  /// Updates the job statistics widget.
  ///
  /// [open] - Number of open jobs.
  /// [ongoing] - Number of ongoing jobs.
  /// [complete] - Number of completed jobs.
  /// [recentJobs] - List of recent jobs to display.
  Future<void> updateJobStats({
    required int open,
    required int ongoing,
    required int complete,
    required List<Map<String, String>> recentJobs,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('job_open_count', open);
      await HomeWidget.saveWidgetData<int>('job_ongoing_count', ongoing);
      await HomeWidget.saveWidgetData<int>('job_complete_count', complete);

      await HomeWidget.saveWidgetData<String>(
        'job_recent_list',
        jsonEncode(recentJobs),
      );

      await HomeWidget.updateWidget(
        name: 'JobWidgetProvider',
        androidName: 'JobWidgetProvider',
        iOSName: 'JobWidget',
      );
    } catch (e) {
      print('Error updating Job Widget: $e');
    }
  }

  /// Updates the map statistics widget.
  ///
  /// [activeVehicles] - Number of active vehicles.
  /// [markers] - List of map markers to render in the snapshot.
  Future<void> updateMapStats({
    required int activeVehicles,
    required List<MapMarkerModel> markers,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('map_active_count', activeVehicles);

      // Render Map Snapshot
      final path = await HomeWidget.renderFlutterWidget(
        WidgetMapSnapshot(markers: markers, activeCount: activeVehicles),
        key: 'map_snapshot',
        logicalSize: const Size(300, 150),
      );

      await HomeWidget.saveWidgetData<String>('map_image_path', path);

      await HomeWidget.updateWidget(
        name: 'MapWidgetProvider',
        androidName: 'MapWidgetProvider',
        iOSName: 'MapWidget',
      );
    } catch (e) {
      print('Error updating Map Widget: $e');
    }
  }
}
