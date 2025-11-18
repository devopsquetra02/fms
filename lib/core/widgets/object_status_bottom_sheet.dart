import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fms/data/models/traxroot_object_status_model.dart';
import 'package:fms/data/models/traxroot_sensor_model.dart';

class ObjectStatusBottomSheet extends StatefulWidget {
  final TraxrootObjectStatusModel status;
  final VoidCallback? onTrack;
  final VoidCallback? onNavigate;
  final String? iconUrl;
  const ObjectStatusBottomSheet({
    super.key,
    required this.status,
    this.onTrack,
    this.onNavigate,
    this.iconUrl,
  });

  @override
  State<ObjectStatusBottomSheet> createState() =>
      _ObjectStatusBottomSheetState();
}

class _ObjectStatusBottomSheetState extends State<ObjectStatusBottomSheet> {
  bool _showAllSensors = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.status;
    final subtitle = <String>[
      if (status.status != null && status.status!.isNotEmpty) status.status!,
      if (status.speed != null)
        'Speed: ${status.speed!.toStringAsFixed(1)} km/h',
      if (status.course != null)
        'Heading: ${status.course!.toStringAsFixed(0)}°',
    ].join(' • ');

    final updatedLabel = status.updatedAt != null
        ? _formatDateTime(status.updatedAt!)
        : 'Unknown';

    final coordinatesLabel = status.geoPoint != null
        ? '${status.geoPoint!.lat.toStringAsFixed(5)}, ${status.geoPoint!.lng.toStringAsFixed(5)}'
        : 'Not available';

    // Get priority sensors to display
    final sensors = status.sensors ?? [];
    final prioritySensors = _getPrioritySensors(sensors);
    final hasMoreSensors = sensors.length > prioritySensors.length;

    // Debug: Print sensor count
    print(
      'ObjectStatusBottomSheet - Total sensors: ${sensors.length}, Priority: ${prioritySensors.length}',
    );

    return SafeArea(
      top: false,
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusAvatar(iconUrl: widget.iconUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status.name ?? status.trackerId ?? 'Vehicle',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  subtitle,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Last update: $updatedLabel',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Tracker ID',
                    value: status.trackerId ?? '-',
                  ),
                  _DetailRow(label: 'Coordinates', value: coordinatesLabel),
                  _DetailRow(
                    label: 'Altitude',
                    value: status.altitude != null
                        ? '${status.altitude!.toStringAsFixed(1)} m'
                        : '-',
                  ),
                  _DetailRow(
                    label: 'Satellites',
                    value: status.satellites?.toString() ?? '-',
                  ),
                  _DetailRow(
                    label: 'Accuracy',
                    value: status.accuracy != null
                        ? '${status.accuracy!.toStringAsFixed(1)} m'
                        : '-',
                  ),
                  // Display priority sensors
                  if (prioritySensors.isNotEmpty)
                    ..._buildSensorRows(prioritySensors),
                  // Show more/less button
                  if (hasMoreSensors)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllSensors = !_showAllSensors;
                        });
                      },
                      child: Text(
                        _showAllSensors ? 'Show Less' : 'Show More Sensors',
                      ),
                    ),
                  // Display all sensors when expanded
                  if (_showAllSensors)
                    ..._buildSensorRows(
                      sensors.skip(prioritySensors.length).toList(),
                    ),
                  if (status.address != null && status.address!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Address',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(status.address!, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 16),
                  if (widget.onTrack != null || widget.onNavigate != null)
                    Row(
                      children: [
                        if (widget.onTrack != null)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onTrack,
                              icon: const Icon(Icons.near_me_outlined),
                              label: const Text('Track Vehicle'),
                            ),
                          ),
                        if (widget.onTrack != null && widget.onNavigate != null)
                          const SizedBox(width: 12),
                        if (widget.onNavigate != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onNavigate,
                              icon: const Icon(Icons.navigation_outlined),
                              label: const Text('Navigate'),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  /// Get priority sensors to display first
  List<TraxrootSensorModel> _getPrioritySensors(
    List<TraxrootSensorModel> sensors,
  ) {
    const priorityNames = [
      'Moving',
      'GSM Signal',
      'Ignition',
      'Ignition Sensor',
      'Ignition sensor',
      'Coolant Temp',
      'Coolant temp',
      'Device Battery',
      'Device Unplugged',
      'Fuel',
      'Vehicle Battery',
      'RPM',
      'Intake Air Temp',
      'Idling',
      'Crash Detection',
      'Crash Detected',
    ];

    final priority = <TraxrootSensorModel>[];
    final seen = <String>{};

    for (final name in priorityNames) {
      final sensor = sensors.firstWhere(
        (s) => s.name?.toLowerCase() == name.toLowerCase(),
        orElse: () => const TraxrootSensorModel(),
      );
      if (sensor.name != null && !seen.contains(sensor.name!.toLowerCase())) {
        priority.add(sensor);
        seen.add(sensor.name!.toLowerCase());
      }
    }

    return priority;
  }

  /// Build sensor rows
  List<Widget> _buildSensorRows(List<TraxrootSensorModel> sensors) {
    return sensors.map((sensor) {
      final name = sensor.name ?? 'Unknown';
      final value = _formatSensorValue(sensor);
      return _DetailRow(label: name, value: value);
    }).toList();
  }

  /// Format sensor value based on type
  String _formatSensorValue(TraxrootSensorModel sensor) {
    if (sensor.value == null || sensor.value!.isEmpty) {
      return '-';
    }

    final value = sensor.value!;
    final units = sensor.units;
    final name = sensor.name?.toLowerCase() ?? '';

    // Check if it's a boolean sensor (0/1)
    if (sensor.isBoolean) {
      return sensor.booleanDisplay;
    }

    // Format based on sensor type
    if (name.contains('gsm signal')) {
      return '$value/5';
    }

    if (name.contains('coolant') || name.contains('intake air')) {
      return '$value°C';
    }

    if (name.contains('battery') && !name.contains('vehicle')) {
      return '${value}V';
    }

    if (name.contains('vehicle battery')) {
      final numValue = double.tryParse(value);
      if (numValue != null && numValue > 100) {
        return '${(numValue / 1000).toStringAsFixed(1)}V';
      }
      return '${value}V';
    }

    // Return value with units if available
    if (units != null && units.isNotEmpty) {
      return '$value $units';
    }

    return value;
  }
}

class _StatusAvatar extends StatelessWidget {
  const _StatusAvatar({this.iconUrl});

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(Icons.directions_bus_filled);

    if (iconUrl == null || iconUrl!.isEmpty) {
      return const CircleAvatar(child: fallback);
    }

    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: CachedNetworkImage(
          imageUrl: iconUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(child: fallback),
          errorWidget: (_, __, ___) => const Center(child: fallback),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
