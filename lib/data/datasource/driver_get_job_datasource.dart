import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/http_error_handler.dart';
import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../models/response/driver_get_job_response_model.dart';

/// Datasource for a driver to claim/start a job.
class DriverGetJobDatasource {
  /// Attempts to claim/start a job for the current driver.
  Future<DriverGetJobResponseModel> driverGetJob({required int jobId}) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);
    final userId = prefs.getString(Variables.prefUserID);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    if (userId == null) {
      throw Exception('User ID not found');
    }

    final uri = Uri.parse(
      Variables.driverGetJobEndpoint,
    ).replace(queryParameters: {'x-key': apiKey});

    final response = await ApiClient.post(
      uri,
      body: {'user_id': userId, 'job_id': jobId.toString()},
    );

    log(
      'status: ${response.statusCode}',
      name: 'DriverGetJobDatasource',
      level: 800,
    );

    if (response.statusCode == 200) {
      return DriverGetJobResponseModel.fromJson(response.body);
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      log(response.body, name: 'DriverGetJobDatasource', level: 1200);

      // Try to parse error message from server response
      String errorMessage = 'Failed to start job';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['Message'] != null) {
          errorMessage = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {}
      if (errorMessage.toLowerCase().contains(
        'company subscription mismatch',
      )) {
        ApiClient.resetLogoutFlag();
      }
      return DriverGetJobResponseModel(success: false, message: errorMessage);
    }
  }
}
