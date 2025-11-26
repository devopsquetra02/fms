/// Model representing a sensor attached to a Traxroot object.
class TraxrootSensorModel {
  final String? id;
  final String? trackerId;
  final String? name;
  final String? itemId;
  final String? units;
  final String? value;
  final String? flags;

  const TraxrootSensorModel({
    this.id,
    this.trackerId,
    this.name,
    this.itemId,
    this.units,
    this.value,
    this.flags,
  });

  factory TraxrootSensorModel.fromMap(Map<String, dynamic> map) {
    String? _parseString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return TraxrootSensorModel(
      id: _parseString(map['id'] ?? map['Id']),
      trackerId: _parseString(
        map['trackerid'] ?? map['TrackerId'] ?? map['trackerId'],
      ),
      name: _parseString(map['name'] ?? map['Name']),
      // Handle both 'itemid' (profile endpoint) and 'input' (Objects endpoint)
      itemId: _parseString(
        map['itemid'] ??
            map['ItemId'] ??
            map['itemId'] ??
            map['input'] ??
            map['Input'],
      ),
      units: _parseString(map['units'] ?? map['Units']),
      value: _parseString(map['value'] ?? map['Value']),
      flags: _parseString(map['flags'] ?? map['Flags']),
    );
  }

  /// Returns formatted display value with units
  String get displayValue {
    if (value == null || value!.isEmpty) return 'N/A';
    if (units != null && units!.isNotEmpty) {
      return '$value $units';
    }
    return value!;
  }

  /// Check if this is a boolean sensor (0/1 values)
  bool get isBoolean {
    return value == '0' || value == '1';
  }

  /// Get boolean value as Yes/No
  String get booleanDisplay {
    if (value == '1') return 'Yes';
    if (value == '0') return 'No';
    if (value == null || value!.isEmpty) return 'N/A';
    return value!;
  }

  /// Check if sensor is available (has metadata)
  bool get isAvailable => name != null && name!.isNotEmpty;
}
