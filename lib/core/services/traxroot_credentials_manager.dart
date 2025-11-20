import 'package:shared_preferences/shared_preferences.dart';

import '../constants/variables.dart';

/// Handles cached access to Traxroot credentials to avoid repeated
/// SharedPreferences lookups on resource-constrained devices.
class TraxrootCredentialsManager {
  const TraxrootCredentialsManager._();

  static String? _username;
  static String? _password;
  static bool _hasLoaded = false;

  static Future<void> _ensureLoaded({SharedPreferences? prefs}) async {
    if (_hasLoaded && _username != null && _password != null) {
      return;
    }
    final storage = prefs ?? await SharedPreferences.getInstance();
    _username = storage.getString(Variables.prefTraxrootUsername);
    _password = storage.getString(Variables.prefTraxrootPassword);
    _hasLoaded = true;
  }

  static Future<String> getUsername({SharedPreferences? prefs}) async {
    await _ensureLoaded(prefs: prefs);
    final username = _username;
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return Variables.traxrootUsername;
  }

  static Future<String> getPassword({SharedPreferences? prefs}) async {
    await _ensureLoaded(prefs: prefs);
    final password = _password;
    if (password != null && password.isNotEmpty) {
      return password;
    }
    return Variables.traxrootPassword;
  }

  static Future<void> cache({
    String? username,
    String? password,
    SharedPreferences? prefs,
  }) async {
    if ((username == null || username.isEmpty) &&
        (password == null || password.isEmpty)) {
      return;
    }
    final storage = prefs ?? await SharedPreferences.getInstance();
    var updated = false;
    if (username != null && username.isNotEmpty) {
      await storage.setString(Variables.prefTraxrootUsername, username);
      _username = username;
      updated = true;
    }
    if (password != null && password.isNotEmpty) {
      await storage.setString(Variables.prefTraxrootPassword, password);
      _password = password;
      updated = true;
    }
    if (updated) {
      _hasLoaded = true;
    }
  }

  static void invalidateCache() {
    _hasLoaded = false;
    _username = null;
    _password = null;
  }
}
