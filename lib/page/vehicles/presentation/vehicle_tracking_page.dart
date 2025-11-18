import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/widgets/adaptive_map.dart';
import '../../../core/widgets/object_status_bottom_sheet.dart';
import '../../../data/datasource/traxroot_datasource.dart';
import '../../../data/models/traxroot_object_status_model.dart';

class VehicleTrackingPage extends StatefulWidget {
  final TraxrootObjectStatusModel vehicle;
  final String? iconUrl;
  const VehicleTrackingPage({super.key, required this.vehicle, this.iconUrl});

  @override
  State<VehicleTrackingPage> createState() => _VehicleTrackingPageState();
}

class _VehicleTrackingPageState extends State<VehicleTrackingPage> {
  final _objectsDatasource = TraxrootObjectsDatasource(
    TraxrootAuthDatasource(),
  );
  TraxrootObjectStatusModel? _vehicle;
  bool _loading = false;
  String? _error;
  bool _autoRefresh = false;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _refreshLatestStatus();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshLatestStatus() async {
    final id = _vehicle?.id;
    if (id == null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Try to get object with sensors first, fallback to regular status
      final latest = await _objectsDatasource
          .getObjectWithSensors(objectId: id)
          .catchError((_) => _objectsDatasource.getObjectStatus(objectId: id));
      if (!mounted) return;
      setState(() {
        _vehicle = latest;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vehicle: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicle;
    final marker = vehicle?.toMarker(icon: widget.iconUrl);
    final hasLocation = marker != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicle?.name ?? 'Vehicle Tracking'),
        actions: [
          IconButton(
            tooltip: _autoRefresh ? 'Auto refresh: ON' : 'Auto refresh: OFF',
            onPressed: _toggleAutoRefresh,
            icon: Icon(
              Icons.autorenew,
              color: _autoRefresh
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refreshLatestStatus,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: hasLocation
                  ? AdaptiveMap(
                      center: marker.position,
                      zoom: 15,
                      markers: [marker],
                      onMarkerTap: (_) => _showVehicleDetail(vehicle!),
                    )
                  : Center(
                      child: Text(
                        'Vehicle location is unavailable',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            //card display
            Card(
              child: ListTile(
                leading: SizedBox(
                  width: 20,
                  child: Center(child: _VehicleAvatar(iconUrl: widget.iconUrl)),
                ),
                title: Text(vehicle?.name ?? 'Vehicle'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (vehicle?.status != null)
                      Text('Status: ${vehicle!.status}'),
                    if (vehicle?.speed != null)
                      Text('Speed: ${vehicle!.speed!.toStringAsFixed(1)} km/h'),
                    if (vehicle?.address != null &&
                        vehicle!.address!.isNotEmpty)
                      Text(vehicle.address!),
                    if (vehicle?.updatedAt != null)
                      Text(
                        'Updated: ${vehicle!.updatedAt!.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
                isThreeLine: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleDetail(TraxrootObjectStatusModel vehicle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ObjectStatusBottomSheet(status: vehicle),
    );
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
    });
    if (_autoRefresh) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      if (!_loading) {
        _refreshLatestStatus();
      }
    });
  }

  void _stopAutoRefresh() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }
}

class _VehicleAvatar extends StatelessWidget {
  const _VehicleAvatar({required this.iconUrl});

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(8);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.2);

    Widget fallbackIcon() => const Icon(Icons.directions_car, size: 18);

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: (iconUrl == null || iconUrl!.isEmpty)
            ? Center(child: fallbackIcon())
            : CachedNetworkImage(
                imageUrl: iconUrl!,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
                placeholder: (_, __) => Center(child: fallbackIcon()),
                errorWidget: (_, __, ___) => Center(child: fallbackIcon()),
              ),
      ),
    );
  }
}
