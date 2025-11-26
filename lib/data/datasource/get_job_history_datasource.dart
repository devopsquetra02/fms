import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/http_error_handler.dart';
import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';
import '../models/response/get_job_history__response_model.dart';

/// Datasource for fetching job history.
class GetJobHistoryDatasource {
  /// Fetches the history of completed jobs for the current user.
  Future<GetJobHistoryResponseModel> getJobHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);
    final userId = prefs.getString(Variables.prefUserID);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    if (userId == null) {
      throw Exception('User ID not found');
    }

    final endpoint = Variables.getJobHistoryEndpoint(userId);
    final uri = Uri.parse(endpoint).replace(queryParameters: {'x-key': apiKey});
    final response = await ApiClient.get(uri);
    if (await SessionService.handleUnauthorizedResponse(prefs, response)) {
      SessionService;
    }
    log(
      response.statusCode.toString(),
      name: 'GetJobFinishedHistoryDatasource',
      level: 800,
    );
    // log(response.body, name: 'GetJobFinishedHistoryDatasource', level: 800);

    if (response.statusCode == 200) {
      return GetJobHistoryResponseModel.fromJson(response.body);
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      log(response.body, name: 'GetJobHistoryDatasource', level: 1200);
      String errorMessage = 'Failed to load data';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['Message'] != null) {
          errorMessage = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {
        errorMessage =
            'Failed to load data'; // If parsing fails, use default message
      }
      if (errorMessage.toLowerCase().contains(
        'company subscription mismatch',
      )) {
        ApiClient.resetLogoutFlag();
      }
      return GetJobHistoryResponseModel();
    }
  }
}
