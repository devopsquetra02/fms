/// Comprehensive model representing a Traxroot object with all its details.
class TraxrootObjectModel {
  final TraxrootObjectMain? main;
  final TraxrootObjectService? service;
  final TraxrootObjectSafety? safety;
  final TraxrootObjectOdometer? odometer;
  final List<Map<String, dynamic>> trends;
  final List<Map<String, dynamic>> sensors;
  final List<dynamic> groups;
  final Map<String, dynamic> raw;

  const TraxrootObjectModel({
    this.main,
    this.service,
    this.safety,
    this.odometer,
    this.trends = const [],
    this.sensors = const [],
    this.groups = const [],
    this.raw = const {},
  });

  int? get id => main?.id;
  String? get name => main?.name;
  double? get latitude => main?.latitude;
  double? get longitude => main?.longitude;
  String? get address => main?.address;
  int? get iconId => main?.iconId;

  factory TraxrootObjectModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? _asMap(dynamic value) {
      if (value is Map<String, dynamic>) {
        return Map<String, dynamic>.from(value);
      }
      if (value is Map) {
        final result = <String, dynamic>{};
        value.forEach((key, v) {
          result['$key'] = v;
        });
        return result;
      }
      return null;
    }

    List<Map<String, dynamic>> _asMapList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    }

    List<dynamic> _asList(dynamic value) {
      if (value is List) {
        return List<dynamic>.from(value);
      }
      return const [];
    }

    final raw = Map<String, dynamic>.from(map);
    final mainMap = _asMap(map['main']);
    final serviceMap = _asMap(map['service']);
    final safetyMap = _asMap(map['safety']);
    final odometerMap = _asMap(map['odometer']);

    return TraxrootObjectModel(
      main: mainMap != null ? TraxrootObjectMain.fromMap(mainMap) : null,
      service: serviceMap != null
          ? TraxrootObjectService.fromMap(serviceMap)
          : null,
      safety: safetyMap != null
          ? TraxrootObjectSafety.fromMap(safetyMap)
          : null,
      odometer: odometerMap != null
          ? TraxrootObjectOdometer.fromMap(odometerMap)
          : null,
      trends: _asMapList(map['trends']),
      sensors: _asMapList(map['sensors']),
      groups: _asList(map['groups']),
      raw: raw,
    );
  }
}

/// Main details of a Traxroot object.
class TraxrootObjectMain {
  final int? id;
  final String? name;
  final String? comment;
  final String? inventoryNumber;
  final String? color;
  final String? timeZone;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? phone;
  final String? phoneAlt;
  final String? model;
  final String? flags;
  final int? iconId;

  const TraxrootObjectMain({
    this.id,
    this.name,
    this.comment,
    this.inventoryNumber,
    this.color,
    this.timeZone,
    this.latitude,
    this.longitude,
    this.address,
    this.phone,
    this.phoneAlt,
    this.model,
    this.flags,
    this.iconId,
  });

  factory TraxrootObjectMain.fromMap(Map<String, dynamic> map) {
    double? _toDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    }

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

    String? _toString(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is String) {
        return value;
      }
      return value.toString();
    }

    return TraxrootObjectMain(
      id: _toInt(map['id']),
      name: _toString(map['name']),
      comment: _toString(map['comment']),
      inventoryNumber: _toString(map['inventoryNumber']),
      color: _toString(map['color']),
      timeZone: _toString(map['timeZone']),
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      address: _toString(map['address']),
      phone: _toString(map['phone']),
      phoneAlt: _toString(map['phone1']),
      model: _toString(map['model']),
      flags: _toString(map['flags']),
      iconId: _toInt(map['iconId']),
    );
  }
}

/// Service details of a Traxroot object.
class TraxrootObjectService {
  final int? createdAt;
  final int? installedAt;
  final String? installer;
  final String? comment;
  final int? status;
  final String? serverGroup;
  final int? payedTill;

  const TraxrootObjectService({
    this.createdAt,
    this.installedAt,
    this.installer,
    this.comment,
    this.status,
    this.serverGroup,
    this.payedTill,
  });

  factory TraxrootObjectService.fromMap(Map<String, dynamic> map) {
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

    String? _toString(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is String) {
        return value;
      }
      return value.toString();
    }

    return TraxrootObjectService(
      createdAt: _toInt(map['createdAt']),
      installedAt: _toInt(map['installedAt']),
      installer: _toString(map['installer']),
      comment: _toString(map['comment']),
      status: _toInt(map['status']),
      serverGroup: _toString(map['serverGroup']),
      payedTill: _toInt(map['payedTill']),
    );
  }
}

/// Safety details of a Traxroot object.
class TraxrootObjectSafety {
  final String? contract;
  final String? password;
  final String? passwordAlt;
  final List<dynamic> accountOrder;
  final List<dynamic> zones;

  const TraxrootObjectSafety({
    this.contract,
    this.password,
    this.passwordAlt,
    this.accountOrder = const [],
    this.zones = const [],
  });

  factory TraxrootObjectSafety.fromMap(Map<String, dynamic> map) {
    String? _toString(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is String) {
        return value;
      }
      return value.toString();
    }

    List<dynamic> _toList(dynamic value) {
      if (value is List) {
        return List<dynamic>.from(value);
      }
      return const [];
    }

    return TraxrootObjectSafety(
      contract: _toString(map['contract']),
      password: _toString(map['password']),
      passwordAlt: _toString(map['password1']),
      accountOrder: _toList(map['accountOrder']),
      zones: _toList(map['zones']),
    );
  }
}

/// Odometer details of a Traxroot object.
class TraxrootObjectOdometer {
  final int? distance;
  final int? engineTime;

  const TraxrootObjectOdometer({this.distance, this.engineTime});

  factory TraxrootObjectOdometer.fromMap(Map<String, dynamic> map) {
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

    return TraxrootObjectOdometer(
      distance: _toInt(map['distance']),
      engineTime: _toInt(map['engineTime']),
    );
  }
}
