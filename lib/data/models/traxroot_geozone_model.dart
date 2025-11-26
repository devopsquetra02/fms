import 'package:fms/core/models/geo.dart';

/// Model representing a geozone (geofence) from Traxroot.
class TraxrootGeozoneModel {
  final int? id;
  final String? name;
  final String? comment;
  final String? points;
  final TraxrootGeozoneStyle? style;
  final String? flags;
  final int? radius;
  final int? maxSpeed;
  final int? iconId;

  const TraxrootGeozoneModel({
    this.id,
    this.name,
    this.comment,
    this.points,
    this.style,
    this.flags,
    this.radius,
    this.maxSpeed,
    this.iconId,
  });

  factory TraxrootGeozoneModel.fromMap(Map<String, dynamic> map) {
    int? _toInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    return TraxrootGeozoneModel(
      id: map['id'] as int?,
      name: map['name'] as String?,
      comment: map['comment'] as String?,
      points: map['points'] as String?,
      style: map['style'] == null
          ? null
          : TraxrootGeozoneStyle.fromMap(
              Map<String, dynamic>.from(map['style'] as Map),
            ),
      flags: map['flags'] as String?,
      radius: _toInt(map['radius']),
      maxSpeed: _toInt(map['maxSpeed']),
      iconId: _toInt(map['iconId']),
    );
  }

  List<GeoPoint> toGeoPoints() {
    if (points == null || points!.trim().isEmpty) {
      return <GeoPoint>[];
    }
    final tokens = points!.trim().split(RegExp(r'\s+'));
    final coordinates = <GeoPoint>[];
    for (var i = 0; i + 1 < tokens.length; i += 2) {
      final lat = double.tryParse(tokens[i]);
      final lng = double.tryParse(tokens[i + 1]);
      if (lat != null && lng != null) {
        coordinates.add(GeoPoint(lat, lng));
      }
    }
    return coordinates;
  }

  MapZoneModel? toZoneModel() {
    final pointsList = toGeoPoints();
    if (pointsList.isEmpty) {
      return null;
    }

    final typeString = style?.type?.toLowerCase() ?? 'polygon';
    final zoneType = typeString == 'polyline'
        ? MapZoneType.polyline
        : MapZoneType.polygon;
    final minimumPoints = zoneType == MapZoneType.polyline ? 2 : 3;
    if (pointsList.length < minimumPoints) {
      return null;
    }

    final zoneId =
        id?.toString() ??
        (name != null && name!.isNotEmpty
            ? name!
            : 'zone-${DateTime.now().microsecondsSinceEpoch}');

    return MapZoneModel(
      id: zoneId,
      type: zoneType,
      points: pointsList,
      name: name,
      style: style?.toMapZoneStyle(),
    );
  }
}

/// Style configuration for a Traxroot geozone.
class TraxrootGeozoneStyle {
  final String? type;
  final String? fillColor;
  final double? fillOpacity;
  final String? strokeColor;
  final String? strokeDashstyle;
  final double? strokeWidth;
  final double? strokeOpacity;

  const TraxrootGeozoneStyle({
    this.type,
    this.fillColor,
    this.fillOpacity,
    this.strokeColor,
    this.strokeDashstyle,
    this.strokeWidth,
    this.strokeOpacity,
  });

  factory TraxrootGeozoneStyle.fromMap(Map<String, dynamic> map) {
    double? _toDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    return TraxrootGeozoneStyle(
      type: map['type'] as String?,
      fillColor: map['fillColor'] as String?,
      fillOpacity: _toDouble(map['fillOpacity']),
      strokeColor: map['strokeColor'] as String?,
      strokeDashstyle: map['strokeDashstyle'] as String?,
      strokeWidth: _toDouble(map['strokeWidth']),
      strokeOpacity: _toDouble(map['strokeOpacity']),
    );
  }

  MapZoneStyle toMapZoneStyle() {
    return MapZoneStyle(
      fillColorHex: fillColor,
      fillOpacity: fillOpacity,
      strokeColorHex: strokeColor,
      strokeWidth: strokeWidth,
      strokeOpacity: strokeOpacity,
    );
  }
}
