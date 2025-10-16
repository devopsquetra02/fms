import 'package:flutter/material.dart';
import 'package:fms/core/models/geo.dart';
import 'package:fms/core/widgets/adaptive_map.dart';
import 'package:fms/core/widgets/object_status_bottom_sheet.dart';
import 'package:fms/data/datasource/get_job_datasource.dart';
import 'package:fms/data/datasource/get_job_ongoing_datasource.dart';
import 'package:fms/data/datasource/get_job_history_datasource.dart';
import 'package:fms/data/datasource/traxroot_datasource.dart';
import 'package:fms/data/models/response/get_job_response_model.dart';
import 'package:fms/data/models/traxroot_icon_model.dart';
import 'package:fms/data/models/traxroot_object_status_model.dart';
import 'package:fms/page/vehicles/presentation/vehicle_tracking_page.dart';
import 'package:fms/data/models/response/get_job_history__response_model.dart'
    as history;

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _objectsDatasource = TraxrootObjectsDatasource(TraxrootAuthDatasource());
  final _internalDatasource = TraxrootInternalDatasource();

  bool _loading = false;
  String? _error;
  List<MapMarkerModel> _markers = const [];
  List<MapZoneModel> _zones = const [];
  List<TraxrootObjectStatusModel> _objects = const [];
  Map<int, String> _iconUrlByObjectId = const {};
  GetJobResponseModel? _allJobsResponse;
  GetJobResponseModel? _ongoingJobsResponse;
  history.GetJobHistoryResponseModel? _completedJobsResponse;

  static const GeoPoint _defaultCenter = GeoPoint(14.5995, 120.9842); // Manila fallback

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final statusesFuture = _objectsDatasource.getAllObjectsStatus();
      final objectsFuture = _objectsDatasource.getObjects();
      final iconsFuture = _objectsDatasource.getObjectIcons();
      final geozonesFuture = _internalDatasource.getGeozones();
      final allJobsFuture = GetJobDatasource().getJob();
      final ongoingJobsFuture = GetJobOngoingDatasource().getOngoingJobs();
      final completedJobsFuture = GetJobHistoryDatasource().getJobHistory();

      final statuses = await statusesFuture;
      final objects = await objectsFuture;
      final icons = await iconsFuture;
      final geozones = await geozonesFuture;
      final allJobs = await allJobsFuture;
      final ongoingJobs = await ongoingJobsFuture;
      final completedJobs = await completedJobsFuture;

      final iconsById = <int, TraxrootIconModel>{
        for (final icon in icons)
          if (icon.id != null) icon.id!: icon,
      };

      final iconUrlByObjectId = <int, String>{};
      for (final object in objects) {
        final objectId = object.id;
        if (objectId == null) {
          continue;
        }
        final iconId = object.iconId;
        if (iconId == null) {
          continue;
        }
        final iconUrl = iconsById[iconId]?.url;
        if (iconUrl != null && iconUrl.isNotEmpty) {
          iconUrlByObjectId[objectId] = iconUrl;
        }
      }

      final markers = <MapMarkerModel>[];
      for (final status in statuses) {
        final iconUrl = status.id != null ? iconUrlByObjectId[status.id!] : null;
        final marker = status.toMarker(icon: iconUrl);
        if (marker != null) {
          markers.add(marker);
        }
      }

      final zones = <MapZoneModel>[];
      for (final geozone in geozones) {
        final zoneModel = geozone.toZoneModel();
        if (zoneModel != null) {
          zones.add(zoneModel);
        }
      }

      if (!mounted) return;
      setState(() {
        _markers = markers;
        _zones = zones;
        _objects = statuses;
        _iconUrlByObjectId = iconUrlByObjectId;
        _allJobsResponse = allJobs;
        _ongoingJobsResponse = ongoingJobs;
        _completedJobsResponse = completedJobs;
        _loading = false;
      });

      if (iconUrlByObjectId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final precacheTargets = iconUrlByObjectId.values.toSet();
          for (final url in precacheTargets) {
            precacheImage(NetworkImage(url), context);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load map data.')), 
      );
    }
  }

  GeoPoint get _mapCenter {
    if (_markers.isNotEmpty) {
      return _markers.first.position;
    }
    return _defaultCenter;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _loadData,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : AdaptiveMap(
                      center: _mapCenter,
                      zoom: 12.5,
                      markers: _markers,
                      zones: _zones,
                      onMarkerTap: _handleMarkerTap,
                    ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Open Jobs',
                    value: (_allJobsResponse?.data?.length ?? 0).toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Ongoing',
                    value: (_ongoingJobsResponse?.data?.length ?? 0).toString(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Complete',
                    value: (_completedJobsResponse?.data?.length ?? 0).toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMarkerTap(MapMarkerModel marker) {
    final data = marker.data;
    TraxrootObjectStatusModel? status;
    if (data is TraxrootObjectStatusModel) {
      status = data;
    } else {
      status = _objects.firstWhere(
        (obj) => obj.geoPoint?.lat == marker.position.lat && obj.geoPoint?.lng == marker.position.lng,
        orElse: () => const TraxrootObjectStatusModel(),
      );
      if (status.id == null && status.name == null) {
        status = null;
      }
    }
    if (status == null) {
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ObjectStatusBottomSheet(
        status: status!,
        onTrack: status.id != null
            ? () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VehicleTrackingPage(
                      vehicle: status!,
                      iconUrl: status.id != null ? _iconUrlByObjectId[status.id!] : null,
                    ),
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
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
