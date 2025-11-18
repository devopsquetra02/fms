import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/core/widgets/adaptive_map.dart';
import 'package:fms/core/widgets/object_status_bottom_sheet.dart';
import 'package:fms/controllers/home_controller.dart';
import 'package:fms/page/vehicles/presentation/vehicle_tracking_page.dart';
import 'package:fms/core/services/subscription.dart';

import '../../../core/models/geo.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isMarkerLoading = false;

  Future<void> _handleMarkerTap(
    BuildContext context,
    HomeController controller,
    MapMarkerModel marker,
  ) async {
    if (_isMarkerLoading) return;

    final status = controller.findStatusForMarker(marker);
    if (status == null) return;

    if (mounted) {
      setState(() => _isMarkerLoading = true);
    }

    // Fetch sensor data if object ID is available
    var statusWithSensors = status;
    if (status.id != null) {
      try {
        final withSensors = await controller.getObjectWithSensors(status.id!);
        if (withSensors != null) {
          statusWithSensors = withSensors;
        }
      } catch (e) {
        print('Failed to fetch sensors: $e');
        // Continue with status without sensors
      }
    }

    if (!mounted) return;

    final enrichedStatus =
        statusWithSensors.name != null && statusWithSensors.name!.isNotEmpty
        ? statusWithSensors
        : statusWithSensors.copyWith(name: marker.title);

    final resolvedIconUrl =
        marker.iconUrl ??
        (enrichedStatus.id != null
            ? controller.iconUrlByObjectId[enrichedStatus.id!]
            : null);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ObjectStatusBottomSheet(
        status: enrichedStatus,
        iconUrl: resolvedIconUrl,
        onTrack: enrichedStatus.id != null
            ? () {
                Get.back();
                Get.to(
                  () => VehicleTrackingPage(
                    vehicle: enrichedStatus,
                    iconUrl: resolvedIconUrl,
                  ),
                );
              }
            : null,
      ),
    );

    if (mounted) {
      setState(() => _isMarkerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final isPro = subscriptionService.currentPlan == Plan.pro;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RefreshIndicator(
        onRefresh: controller.loadData,
        child: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.loadData,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              // Only show map for Pro users
              // if (isPro)
              Expanded(
                child: controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          AdaptiveMap(
                            center: controller.mapCenter,
                            zoom: 12.5,
                            markers: controller.markers,
                            zones: controller.zones,
                            onMarkerTap: (marker) =>
                                _handleMarkerTap(context, controller, marker),
                          ),
                          if (_isMarkerLoading)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              // For basic users, show upgrade message
              // if (!isPro)
              //   Expanded(
              //     child: Center(
              //       child: Column(
              //         mainAxisAlignment: MainAxisAlignment.center,
              //         children: [
              //           Icon(
              //             Icons.map_outlined,
              //             size: 80,
              //             color: Colors.grey.shade400,
              //           ),
              //           const SizedBox(height: 16),
              //           Text(
              //             'Map View',
              //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
              //               color: Colors.grey.shade700,
              //             ),
              //           ),
              //           const SizedBox(height: 8),
              //           Text(
              //             'Upgrade to Pro to access map view\nand vehicle tracking',
              //             textAlign: TextAlign.center,
              //             style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              //               color: Colors.grey.shade600,
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              if (controller.error.value.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  controller.error.value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (isPro) ...[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Open Jobs',
                        value: controller.openJobsCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Ongoing',
                        value: controller.ongoingJobsCount.toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Complete',
                        value: controller.completedJobsCount.toString(),
                      ),
                    ),
                  ],
                ),
              ],
              if (!isPro) ...[
                const SizedBox(height: 8),
                Text(
                  'Upgrade to Pro to access Job',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
