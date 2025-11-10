import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/constants/variables.dart';
import 'package:fms/core/network/http_error_handler.dart';
import 'package:fms/data/models/response/auth_response_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Note: Auth endpoints use http directly, not ApiClient, 
// because company validation is not needed for login/logout
class AuthRemoteDataSource {
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
      log(response.body, name: 'AuthRemoteDataSource.forgotPassword', level: 1200);
      String message = 'Failed to send reset password (${response.statusCode})';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['message'] != null) message = decoded['message'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  //logout to remove all data from shared preferences
  Future<String> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    log('All shared preferences cleared', name: 'AuthRemoteDataSource', level: 800);
    return 'Logout successful';
  }
}
