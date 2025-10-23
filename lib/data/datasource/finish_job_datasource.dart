import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/http_error_handler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../models/response/finish_job_response_model.dart';

class FinishJobDatasource {
  Future<FinishJobResponseModel> finishJob({
    required int jobId,
    required List<String> imagesBase64,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final uri = Uri.parse(Variables.finishedJobEndpoint)
        .replace(queryParameters: {'x-key': apiKey});

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'job_id': jobId,
        'images': imagesBase64,
        'notes': notes ?? '',
      }),
    );

    log('status: ${response.statusCode}', name: 'FinishJobDatasource', level: 800);

    if (response.statusCode == 200) {
      return FinishJobResponseModel.fromJson(response.body);
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      log(response.body, name: 'FinishJobDatasource', level: 1200);
      throw Exception('Failed to finish job');
    }
  }
}
