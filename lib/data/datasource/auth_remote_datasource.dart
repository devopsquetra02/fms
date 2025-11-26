import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/constants/variables.dart';
import 'package:fms/core/network/http_error_handler.dart';
import 'package:fms/data/models/response/auth_response_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';

/// Remote datasource for authentication-related operations.
///
/// Note: Auth endpoints use http directly, not ApiClient,
/// because company validation is not needed for login/logout.
class AuthRemoteDataSource {
  /// Logs in the user with email and password.
  ///
  /// Returns [AuthResponseModel] if successful.
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(Variables.loginEndpoint);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'email': email, 'password': password}),
    );
    log(
      response.statusCode.toString(),
      name: 'AuthRemoteDataSource',
      level: 800,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final model = AuthResponseModel.fromJson(response.body);
      if (model.success == true && model.data?.apiKey != null) {
        return model;
      } else {
        throw Exception('Login failed: invalid response');
      }
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      String message = 'Login failed, please try again later';
      log(response.body, name: 'AuthRemoteDataSource', level: 1200);
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['Message'] != null) {
          message = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Sends a forgot password request.
  Future<String> forgotPassword({required String email}) async {
    final uri = Uri.parse(Variables.forgotPasswordEndpoint);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, dynamic>{'email': email}),
    );

    log(
      response.statusCode.toString(),
      name: 'AuthRemoteDataSource.forgotPassword',
      level: 800,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final message = decoded['message'] ?? decoded['Message'];
        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      } catch (_) {}
      return 'Reset password email sent.';
    } else {
      log(
        response.body,
        name: 'AuthRemoteDataSource.forgotPassword',
        level: 1200,
      );
      String message = 'Failed to send reset password (${response.statusCode})';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['message'] != null) message = decoded['message'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  /// Logs out the user and clears local data.
  Future<String> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    log(
      'All shared preferences cleared',
      name: 'AuthRemoteDataSource',
      level: 800,
    );
    return 'Logout successful';
  }

  /// Updates the FCM token for push notifications.
  Future<void> updateFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }
    final url = Uri.parse(
      '${Variables.baseUrl}/api/update-fcm-token',
    ).replace(queryParameters: {'x-key': apiKey});
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );
    log(
      response.statusCode.toString(),
      name: 'AuthRemoteDataSource.updateFcmToken',
      level: 800,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      log(response.body, name: 'GetJobDatasource', level: 1200);
      String errorMessage = 'Failed to load data';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['Message'] != null) {
          errorMessage = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {
        errorMessage = 'Failed to cancel job';
      }
      if (errorMessage.toLowerCase().contains(
        'company subscription mismatch',
      )) {
        ApiClient.resetLogoutFlag();
      }

      return;
    }
  }
}
