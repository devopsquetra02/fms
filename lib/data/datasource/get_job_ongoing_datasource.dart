import 'dart:developer';

import 'package:fms/core/network/http_error_handler.dart';
import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/services/session_service.dart';
import '../models/response/get_job_response_model.dart';

class GetJobOngoingDatasource {
  Future<GetJobResponseModel> getOngoingJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);
    final userId = prefs.getString(Variables.prefUserID);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    if (userId == null) {
      throw Exception('User ID not found');
    }

    final endpoint = Variables.getOngoingJobEndpoint(userId);
    final uri = Uri.parse(endpoint).replace(queryParameters: {'x-key': apiKey});

    final response = await ApiClient.get(uri);
    if (await SessionService.handleUnauthorizedResponse(prefs, response)) {
      throw Exception('Unauthorized');
    }
    log(
      response.statusCode.toString(),
      name: 'GetJobOngoingDatasource',
      level: 800,
    );

    if (response.statusCode == 200) {
      return GetJobResponseModel.fromJson(response.body);
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      log(response.body, name: 'GetJobOngoingDatasource', level: 1200);
      throw Exception('Failed to load ongoing jobs');
    }
  }
}
