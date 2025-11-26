import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Storage wrapper that automatically switches between:
/// - Debug mode: SharedPreferences (easy to debug)
/// - Release mode: FlutterSecureStorage (secure)
class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  // FlutterSecureStorage instance (untuk release)
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // SharedPreferences instance (untuk debug)
  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    if (kDebugMode && _prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// Writes a value to storage.
  ///
  /// [key] - The key to store the value under.
  /// [value] - The value to store.
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

  /// Reads a value from storage.
  ///
  /// [key] - The key to read the value from.
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

  /// Deletes a value from storage.
  ///
  /// [key] - The key to delete.
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

  /// Clears all data from storage.
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

  /// Checks if a key exists in storage.
  ///
  /// [key] - The key to check.
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

  /// Gets all keys from storage.
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
