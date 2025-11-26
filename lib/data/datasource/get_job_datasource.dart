import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/http_error_handler.dart';
import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';
import '../models/response/get_job_response_model.dart';

/// Datasource for fetching the list of jobs.
class GetJobDatasource {
  /// Fetches the list of jobs available for the user.
  Future<GetJobResponseModel> getJob() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);

    if (apiKey == null) {
      SessionService;
    }

    final uri = Uri.parse(
      Variables.getJobEndpoint,
    ).replace(queryParameters: {'x-key': apiKey});
    final response = await ApiClient.get(uri);
    if (await SessionService.handleUnauthorizedResponse(prefs, response)) {
      SessionService;
    }
    log(
      response.statusCode.toString(),
      name: 'GetAllJobDatasource',
      level: 800,
    );
    if (response.statusCode == 200) {
      // log(response.statusCode.toString(), name: 'GetJobDatasource', level: 800);
      return GetJobResponseModel.fromJson(response.body);
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
        errorMessage =
            'Failed to cancel job'; // If parsing fails, use default message
      }
      if (errorMessage.toLowerCase().contains(
        'company subscription mismatch',
      )) {
        ApiClient.resetLogoutFlag();
      }

      return GetJobResponseModel();
    }
  }
}
