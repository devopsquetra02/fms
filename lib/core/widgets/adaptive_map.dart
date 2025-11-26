import 'package:flutter/material.dart';
import 'package:fms/core/config/app_config.dart';
import 'package:fms/core/models/geo.dart';
import 'package:fms/core/widgets/flutter_map_widget.dart';
import 'package:fms/core/widgets/google_map_widget.dart';

/// A map widget that adapts between Google Maps and Flutter Map (OpenStreetMap)
/// based on configuration.
class AdaptiveMap extends StatelessWidget {
  final GeoPoint center;
  final double zoom;
  final List<MapMarkerModel> markers;
  final List<MapZoneModel> zones;
  final void Function(MapMarkerModel marker)? onMarkerTap;
  const AdaptiveMap({
    super.key,
    required this.center,
    this.zoom = 14,
    this.markers = const [],
    this.zones = const [],
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasKey = AppConfig.hasGoogleMapsKey;
    if (hasKey) {
      return GoogleMapWidget(
        center: center,
        zoom: zoom,
        markers: markers,
        zones: zones,
        onMarkerTap: onMarkerTap,
      );
    } else {
      return FlutterMapWidget(
        center: center,
        zoom: zoom,
        markers: markers,
        zones: zones,
        onMarkerTap: onMarkerTap,
      );
    }
  }
}
