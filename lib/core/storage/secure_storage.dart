import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage wrapper yang otomatis switch antara:
/// - Debug mode: SharedPreferences (mudah di-debug)
/// - Release mode: FlutterSecureStorage (aman)
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  // FlutterSecureStorage instance (untuk release)
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // SharedPreferences instance (untuk debug)
  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    if (kDebugMode && _prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// Write data
  Future<void> write(String key, String value) async {
    if (kDebugMode) {
      // Debug mode: gunakan SharedPreferences
      await _initPrefs();
      await _prefs!.setString(key, value);
      debugPrint('🔓 [DEBUG] Saved to SharedPreferences: $key');
    } else {
      // Release mode: gunakan FlutterSecureStorage
      await _secureStorage.write(key: key, value: value);
      debugPrint('🔐 [RELEASE] Saved to SecureStorage: $key');
    }
  }

  /// Read data
  Future<String?> read(String key) async {
    if (kDebugMode) {
      // Debug mode: gunakan SharedPreferences
      await _initPrefs();
      final value = _prefs!.getString(key);
      debugPrint('🔓 [DEBUG] Read from SharedPreferences: $key = $value');
      return value;
    } else {
      // Release mode: gunakan FlutterSecureStorage
      final value = await _secureStorage.read(key: key);
      debugPrint('🔐 [RELEASE] Read from SecureStorage: $key');
      return value;
    }
  }

  /// Delete data
  Future<void> delete(String key) async {
    if (kDebugMode) {
      // Debug mode: gunakan SharedPreferences
      await _initPrefs();
      await _prefs!.remove(key);
      debugPrint('🔓 [DEBUG] Deleted from SharedPreferences: $key');
    } else {
      // Release mode: gunakan FlutterSecureStorage
      await _secureStorage.delete(key: key);
      debugPrint('🔐 [RELEASE] Deleted from SecureStorage: $key');
    }
  }

  /// Clear all data
  Future<void> deleteAll() async {
    if (kDebugMode) {
      // Debug mode: gunakan SharedPreferences
      await _initPrefs();
      await _prefs!.clear();
      debugPrint('🔓 [DEBUG] Cleared all SharedPreferences');
    } else {
      // Release mode: gunakan FlutterSecureStorage
      await _secureStorage.deleteAll();
      debugPrint('🔐 [RELEASE] Cleared all SecureStorage');
    }
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    if (kDebugMode) {
      // Debug mode: gunakan SharedPreferences
      await _initPrefs();
      return _prefs!.containsKey(key);
    } else {
      // Release mode: gunakan FlutterSecureStorage
      final value = await _secureStorage.read(key: key);
      return value != null;
    }
  }

  /// Get all keys
  Future<Set<String>> getAllKeys() async {
    if (kDebugMode) {
      // Debug mode: gunakan SharedPreferences
      await _initPrefs();
      return _prefs!.getKeys();
    } else {
      // Release mode: gunakan FlutterSecureStorage
      final all = await _secureStorage.readAll();
      return all.keys.toSet();
    }
  }
}
