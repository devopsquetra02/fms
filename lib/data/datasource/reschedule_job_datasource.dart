import 'dart:convert';
import 'dart:developer';

import 'package:fms/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../../core/network/http_error_handler.dart';
import '../models/response/reschedule_job_response_model.dart';

class RescheduleJobDatasource {
  Future<RescheduleJobResponseModel> rescheduleJob({
    required int jobId,
    required DateTime newDate,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final uri = Uri.parse(
      '${Variables.rescheduleJobEndpoint}/$jobId',
    ).replace(queryParameters: {'x-key': apiKey});

    final body = {
      'new_date': newDate.toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await ApiClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    log(
      'status: ${response.statusCode}',
      name: 'RescheduleJobDatasource',
      level: 800,
    );

    if (response.statusCode == 200) {
      return RescheduleJobResponseModel.fromJson(response.body);
    } else {
      HttpErrorHandler.handleResponse(response.statusCode, response.body);
      log(response.body, name: 'RescheduleJobDatasource', level: 1200);

      // Try to parse error message from server response
      String errorMessage = 'Failed to reschedule job';
      try {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (decoded['Message'] != null) {
          errorMessage = decoded['Message'].toString();
        } else if (decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {
        // If parsing fails, use default message
      }

      throw Exception(errorMessage);
    }
  }
}
