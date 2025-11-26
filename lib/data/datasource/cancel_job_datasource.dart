import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/network/http_error_handler.dart';
import '../models/response/cancel_job_response_model.dart';

/// Datasource for cancelling a job.
class CancelJobDatasource {
  /// Cancels a job with a reason.
  Future<CancelJobResponseModel> cancelJob({
    required int jobId,
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final uri = Uri.parse(
      '${Variables.cancelJobEndpoint}/$jobId',
    ).replace(queryParameters: {'x-key': apiKey});

    final response = await ApiClient.post(uri, body: {'reason': reason});

    log(
      'status: ${response.statusCode}',
      name: 'CancelJobDatasource',
      level: 800,
    );

    if (response.statusCode == 200) {
      return CancelJobResponseModel.fromJson(response.body);
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      log(response.body, name: 'CancelJobDatasource', level: 1200);

      // Try to parse error message from server response
      String errorMessage = 'Failed to cancel job';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['Message'] != null) {
          errorMessage = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {
        errorMessage =
            'Failed to cancel job'; // If parsing fails, use default message
      }
      if (errorMessage.toLowerCase().contains(
        'company subscription mismatch',
      )) {
        ApiClient.resetLogoutFlag();
      }

      return CancelJobResponseModel(success: false, message: errorMessage);
    }
  }
}
