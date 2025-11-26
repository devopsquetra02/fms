import 'package:fms/core/models/geo.dart';
import 'package:fms/data/models/traxroot_sensor_model.dart';

/// Model representing the real-time status of a Traxroot object.
class TraxrootObjectStatusModel {
  final int? id;
  final String? name;
  final String? trackerId;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? course;
  final double? altitude;
  final String? status;
  final String? address;
  final DateTime? updatedAt;
  final int? satellites;
  final double? accuracy;
  final int? iconId;
  final List<TraxrootSensorModel>? sensors;

  const TraxrootObjectStatusModel({
    this.id,
    this.name,
    this.trackerId,
    this.latitude,
    this.longitude,
    this.speed,
    this.course,
    this.altitude,
    this.status,
    this.address,
    this.updatedAt,
    this.satellites,
    this.accuracy,
    this.iconId,
    this.sensors,
  });

  GeoPoint? get geoPoint => latitude != null && longitude != null
      ? GeoPoint(latitude!, longitude!)
      : null;

  MapMarkerModel? toMarker({String? icon}) {
    final point = geoPoint;
    if (point == null) {
      return null;
    }
    final statusText = status?.trim().isNotEmpty == true
        ? status!.trim()
        : null;
    final speedText = speed != null
        ? '${speed!.toStringAsFixed(1)} km/h'
        : null;
    final subtitleParts = <String>[
      if (statusText != null) statusText,
      if (speedText != null) speedText,
    ];
    final subtitle = subtitleParts.join(' • ');
    return MapMarkerModel(
      id: 'object-${id ?? name ?? point.hashCode}',
      position: point,
      title: name ?? trackerId ?? 'Object',
      iconUrl: icon,
      subtitle: subtitle.isEmpty ? null : subtitle,
      data: this,
      rotation: course, // Use course (ang from API) for marker rotation
    );
  }

  TraxrootObjectStatusModel copyWith({
    int? id,
    String? name,
    String? trackerId,
    double? latitude,
    double? longitude,
    double? speed,
    double? course,
    double? altitude,
    String? status,
    String? address,
    DateTime? updatedAt,
    int? satellites,
    double? accuracy,
    int? iconId,
    List<TraxrootSensorModel>? sensors,
  }) {
    return TraxrootObjectStatusModel(
      id: id ?? this.id,
      name: name ?? this.name,
      trackerId: trackerId ?? this.trackerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      course: course ?? this.course,
      altitude: altitude ?? this.altitude,
      status: status ?? this.status,
      address: address ?? this.address,
      updatedAt: updatedAt ?? this.updatedAt,
      satellites: satellites ?? this.satellites,
      accuracy: accuracy ?? this.accuracy,
      iconId: iconId ?? this.iconId,
      sensors: sensors ?? this.sensors,
    );
  }

  factory TraxrootObjectStatusModel.fromMap(Map<String, dynamic> map) {
    double? _parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

    DateTime? _parseDate(dynamic value) {
      if (value is int) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (_) {
          return null;
        }
      }
      if (value is String) {
        final trimmed = value.trim();
        final millis = int.tryParse(trimmed);
        if (millis != null && millis > 0) {
          try {
            return DateTime.fromMillisecondsSinceEpoch(millis);
          } catch (_) {
            return null;
          }
        }
        return DateTime.tryParse(value);
      }
      return null;
    }

    int? _parseInt(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value);
      }
      return null;
    }

    String? _parseString(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is String) {
        return value;
      }
      return value.toString();
    }

    List<TraxrootSensorModel>? _parseSensors(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value
            .where((item) => item is Map)
            .map(
              (item) => TraxrootSensorModel.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
      return null;
    }

    return TraxrootObjectStatusModel(
      // Only treat actual object id fields as id to avoid mismatching with tracker id
      id: _parseInt(
        map['Id'] ?? map['id'] ?? map['ObjectId'] ?? map['objectId'],
      ),
      name: _parseString(
        map['Name'] ?? map['name'] ?? map['ObjectName'] ?? map['objectName'],
      ),
      trackerId: _parseString(
        map['trackerid'] ?? map['TrackerId'] ?? map['trackerId'],
      ),
      latitude: _parseDouble(
        map['Latitude'] ?? map['latitude'] ?? map['Lat'] ?? map['lat'],
      ),
      longitude: _parseDouble(
        map['Longitude'] ??
            map['longitude'] ??
            map['Lon'] ??
            map['lon'] ??
            map['Lng'] ??
            map['lng'],
      ),
      speed: _parseDouble(map['Speed'] ?? map['speed']),
      course: _parseDouble(map['Course'] ?? map['course'] ?? map['ang']),
      altitude: _parseDouble(map['Altitude'] ?? map['altitude'] ?? map['alt']),
      status: _parseString(map['Status'] ?? map['status']),
      address: _parseString(
        map['Address'] ?? map['address'] ?? map['Location'] ?? map['location'],
      ),
      updatedAt: _parseDate(
        map['UpdatedOn'] ?? map['updatedOn'] ?? map['time'],
      ),
      satellites: _parseInt(
        map['Sat'] ?? map['sat'] ?? map['Satellites'] ?? map['satellites'],
      ),
      accuracy: _parseDouble(map['Accuracy'] ?? map['accuracy']),
      iconId: _parseInt(
        map['IconId'] ??
            map['iconId'] ??
            map['IconID'] ??
            map['iconID'] ??
            map['iconid'] ??
            map['icon_id'],
      ),
      sensors: _parseSensors(
        map['trends'] ?? map['Trends'] ?? map['sensors'] ?? map['Sensors'],
      ),
    );
  }
}
