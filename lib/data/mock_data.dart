import 'package:fms/core/models/geo.dart';
import 'package:fms/data/models/vehicle.dart';
import 'package:fms/data/models/job.dart';

/// Class containing mock data for testing and development purposes.
class MockData {
  static const GeoPoint manila = GeoPoint(14.5995, 120.9842);

  static final vehicles = <Vehicle>[
    Vehicle(
      id: 'v1',
      name: 'Vehicle 1',
      plate: 'ABC-123',
      address: '421 St., Quezon City, Metro Manila, Philippines',
      status: 'Active',
      location: const GeoPoint(14.6500, 121.0300),
    ),
    Vehicle(
      id: 'v2',
      name: 'Vehicle 2',
      plate: 'XYZ-987',
      address: 'Makati Ave, Makati, Metro Manila, Philippines',
      status: 'Idle',
      location: const GeoPoint(14.5547, 121.0244),
    ),
  ];

  static final jobs = <JobItem>[
    const JobItem(
      id: 'j1',
      title: 'LINE INTERRUPT',
      address: '421 St., Quezon City, Metro Manila, Philippines',
      detail: 'Urgent line interruption reported in the area.',
    ),
    const JobItem(
      id: 'j2',
      title: 'RECONNECTION',
      address: 'Brgy. 609, Lot 12, P. Pizarro St, Taytay, Metro Manila',
      detail: 'Schedule reconnection for customer.',
    ),
    const JobItem(
      id: 'j3',
      title: 'SHORT CIRCUIT',
      address: 'JBH-1002, Quezon City, Metro Manila, Philippines',
      detail: 'Investigate short circuit incident.',
    ),
  ];
}
