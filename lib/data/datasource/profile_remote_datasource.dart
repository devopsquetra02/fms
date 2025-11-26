import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/http_error_handler.dart';
import 'package:fms/data/models/response/profile_response_model.dart';
import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';

/// Datasource for fetching user profile data.
class ProfileRemoteDataSource {
  /// Fetches the current user's profile information.
  Future<ProfileResponseModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);
    final userId = prefs.getString(Variables.prefUserID);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    if (userId == null) {
      throw Exception('User ID not found');
    }

    final endpoint = Variables.getProfileEndpoint(userId);
    final uri = Uri.parse(endpoint).replace(queryParameters: {'x-key': apiKey});
    final response = await ApiClient.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    log(
      response.statusCode.toString(),
      name: 'ProfileRemoteDataSource',
      level: 800,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final model = ProfileResponseModel.fromJson(response.body);
      if (model.success == true && model.data != null) {
        return model;
      } else {
        throw 'Failed to load profile: invalid response';
      }
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      String message = 'Failed to load profile (${response.statusCode})';
      log(response.body, name: 'ProfileRemoteDataSource', level: 1200);
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['message'] != null) message = decoded['message'].toString();
      } catch (_) {}
      if (message.toLowerCase().contains('company subscription mismatch')) {
        ApiClient.resetLogoutFlag();
      }
      return ProfileResponseModel();
    }
  }
}
