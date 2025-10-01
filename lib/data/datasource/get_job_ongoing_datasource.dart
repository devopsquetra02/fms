import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
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

    final response = await http.get(uri);
    log(
      response.statusCode.toString(),
      name: 'GetJobOngoingDatasource',
      level: 800,
    );

    if (response.statusCode == 200) {
      return GetJobResponseModel.fromJson(response.body);
    } else {
      log(response.body, name: 'GetJobOngoingDatasource', level: 1200);
      throw Exception('Failed to load ongoing jobs');
    }
  }
}
