import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/geo.dart';
import '../../../core/widgets/adaptive_map.dart';
import '../../../core/widgets/object_status_bottom_sheet.dart';
import '../../../data/models/traxroot_object_status_model.dart';
import '../../vehicles/presentation/vehicle_tracking_page.dart';
import '../controller/job_navigation_controller.dart';

/// A page for navigating to a job location using a map.
class JobNavigationPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String jobName;
  final String? address;
  const JobNavigationPage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.jobName,
    this.address,
  });

  @override
  State<JobNavigationPage> createState() => _JobNavigationPageState();
}

class _JobNavigationPageState extends State<JobNavigationPage> {
  late final JobNavigationController _controller;

  GeoPoint get _jobPoint => GeoPoint(widget.latitude, widget.longitude);

  @override
  void initState() {
    super.initState();
    _controller = Get.put(JobNavigationController());
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final warnings = await _controller.loadData(
      jobPoint: _jobPoint,
      jobName: widget.jobName,
      address: widget.address,
    );
    if (warnings.isNotEmpty && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(warnings.join('\n'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Navigation'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _controller.isLoading.value ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            final error = _controller.error.value;
            final markers = _controller.markers;
            final zones = _controller.zones;
            final loading = _controller.isLoading.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.jobName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.address != null) ...[
                  const SizedBox(height: 8),
                  Text(widget.address!, style: theme.textTheme.bodyMedium),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: Stack(
                    children: [
                      AdaptiveMap(
                        center: _jobPoint,
                        markers: markers,
                        zones: zones,
                        onMarkerTap: _handleMarkerTap,
                      ),
                      if (loading)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color(0x33000000),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Markers: ${markers.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Geozones: ${zones.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _handleMarkerTap(MapMarkerModel marker) {
    final status = marker.data;
    if (status is! TraxrootObjectStatusModel) {
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ObjectStatusBottomSheet(
        status: status,
        onTrack: status.id != null
            ? () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VehicleTrackingPage(vehicle: status),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
