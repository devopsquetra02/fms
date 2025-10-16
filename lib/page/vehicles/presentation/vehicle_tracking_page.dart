import 'package:flutter/material.dart';

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
  final _objectsDatasource = TraxrootObjectsDatasource(TraxrootAuthDatasource());
  TraxrootObjectStatusModel? _vehicle;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _refreshLatestStatus();
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
      final latest = await _objectsDatasource.getObjectStatus(objectId: id);
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
        SnackBar(content: Text('Gagal memperbarui kendaraan: ${e.toString()}')),
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
                        'Lokasi kendaraan tidak tersedia',
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
                  child: Center(
                    child: _VehicleAvatar(iconUrl: widget.iconUrl),
                  ),
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
                    if (vehicle?.address != null && vehicle!.address!.isNotEmpty)
                      Text(vehicle.address!),
                    if (vehicle?.updatedAt != null)
                      Text(
                        'Updated: ${vehicle!.updatedAt!.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.error),
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
      builder: (_) => ObjectStatusBottomSheet(
        status: vehicle,
      ),
    );
  }
}

class _VehicleAvatar extends StatelessWidget {
  const _VehicleAvatar({required this.iconUrl});

  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    if (iconUrl == null || iconUrl!.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.directions_car));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        iconUrl!,
        width: 30,
        height: 30,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const CircleAvatar(child: Icon(Icons.directions_car)),
      ),
    );
  }
}
