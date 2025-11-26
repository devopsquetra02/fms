import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/http_error_handler.dart';
import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';
import '../models/response/get_job_ongoing_response_model.dart';

/// Datasource for fetching ongoing jobs.
class GetJobOngoingDatasource {
  /// Fetches the list of jobs currently in progress for the current user.
  Future<GetJobOngoingResponseModel> getOngoingJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);
    final userId = prefs.getString(Variables.prefUserID);

    if (apiKey == null) {
      throw 'API Key not found';
    }

    if (userId == null) {
      throw 'User ID not found';
    }

    final endpoint = Variables.getOngoingJobEndpoint(userId);
    final uri = Uri.parse(endpoint).replace(queryParameters: {'x-key': apiKey});

    final response = await ApiClient.get(uri);
    if (await SessionService.handleUnauthorizedResponse(prefs, response)) {
      SessionService;
    }
    log(
      response.statusCode.toString(),
      name: 'GetJobOngoingDatasource',
      level: 800,
    );

    if (response.statusCode == 200) {
      return GetJobOngoingResponseModel.fromJson(response.body);
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      log(response.body, name: 'GetJobOngoingDatasource', level: 1200);
      String errorMessage = 'Failed to load ongoing jobs';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['Message'] != null) {
          errorMessage = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {
        errorMessage =
            'Failed to load ongoing jobs'; // If parsing fails, use default message
      }
      if (errorMessage.toLowerCase().contains(
        'company subscription mismatch',
      )) {
        ApiClient.resetLogoutFlag();
      }
      return GetJobOngoingResponseModel();
    }
  }
}
