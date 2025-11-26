import 'package:fms/core/constants/variables.dart';

/// Model representing an icon from Traxroot.
class TraxrootIconModel {
  final int? id;
  final String? url;
  final String? urlCross;
  final String? urlDisabled;
  final int? width;
  final int? height;
  final String? color;

  const TraxrootIconModel({
    this.id,
    this.url,
    this.urlCross,
    this.urlDisabled,
    this.width,
    this.height,
    this.color,
  });

  static String? normalizeUrl(String? path) {
    if (path == null) {
      return null;
    }
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }
    final formatted = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '${Variables.traxrootIconBaseUrl}$formatted';
  }

  factory TraxrootIconModel.fromMap(Map<String, dynamic> map) {
    String? _asString(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is String) {
        return value;
      }
      return value.toString();
    }

    int? _asInt(dynamic value) {
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

    return TraxrootIconModel(
      id: _asInt(map['id']),
      url: normalizeUrl(_asString(map['url'])),
      urlCross: normalizeUrl(_asString(map['urlCross'])),
      urlDisabled: normalizeUrl(_asString(map['urlDisabled'])),
      width: map['width'] is int
          ? map['width'] as int?
          : int.tryParse('${map['width']}'),
      height: map['height'] is int
          ? map['height'] as int?
          : int.tryParse('${map['height']}'),
      color: map['color'] as String?,
    );
  }
}
