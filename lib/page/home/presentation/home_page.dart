import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fms/core/widgets/adaptive_map.dart';
import 'package:fms/core/widgets/object_status_bottom_sheet.dart';
import 'package:fms/controllers/home_controller.dart';
import 'package:fms/page/vehicles/presentation/vehicle_tracking_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());

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
              Expanded(
                child: controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : AdaptiveMap(
                        center: controller.mapCenter,
                        zoom: 12.5,
                        markers: controller.markers,
                        zones: controller.zones,
                        onMarkerTap: (marker) =>
                            _handleMarkerTap(context, controller, marker),
                      ),
              ),
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
              Text('Overview', style: Theme.of(context).textTheme.titleMedium),
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
          ),
        ),
      ),
    );
  }

  void _handleMarkerTap(
    BuildContext context,
    HomeController controller,
    dynamic marker,
  ) {
    final status = controller.findStatusForMarker(marker);
    if (status == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ObjectStatusBottomSheet(
        status: status,
        onTrack: status.id != null
            ? () {
                Get.back();
                Get.to(
                  () => VehicleTrackingPage(
                    vehicle: status,
                    iconUrl: status.id != null
                        ? controller.iconUrlByObjectId[status.id!]
                        : null,
                  ),
                );
              }
            : null,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

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
