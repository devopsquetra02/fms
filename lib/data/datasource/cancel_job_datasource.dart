import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/network/http_error_handler.dart';
import '../models/response/cancel_job_response_model.dart';

class CancelJobDatasource {
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

    final response = await http.post(uri, body: {'reason': reason});

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
      throw Exception('Failed to cancel job');
    }
  }
}
