import 'package:fms/core/models/geo.dart';

/// Model representing a vehicle in the fleet.
class Vehicle {
  final String id;
  final String name;
  final String plate;
  final String address;
  final String status; // e.g. Active / Idle / Maintenance
  final GeoPoint location;

  const Vehicle({
    required this.id,
    required this.name,
    required this.plate,
    required this.address,
    required this.status,
    required this.location,
  });
}
