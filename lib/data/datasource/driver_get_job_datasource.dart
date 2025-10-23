import 'dart:developer';

import 'package:fms/core/network/http_error_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../models/response/driver_get_job_response_model.dart';

class DriverGetJobDatasource {
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

    final uri = Uri.parse(Variables.driverGetJobEndpoint)
        .replace(queryParameters: {'x-key': apiKey});

    final response = await http.post(
      uri,
      body: {
        'user_id': userId,
        'job_id': jobId.toString(),
      },
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
      throw Exception('Failed to start job');
    }
  }
}
