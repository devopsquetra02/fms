import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/variables.dart';
import '../models/response/get_job_response_model.dart';

class GetJobDatasource {
  Future<GetJobResponseModel> getJob() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(Variables.prefApiKey);

    if (apiKey == null) {
      throw Exception('API Key not found');
    }

    final uri = Uri.parse(
      Variables.getJobEndpoint,
    ).replace(queryParameters: {'x-key': apiKey});
    final response = await http.get(uri);
    log(response.statusCode.toString(), name: 'GetAllJobDatasource', level: 800);
    if (response.statusCode == 200) {
      // log(response.statusCode.toString(), name: 'GetJobDatasource', level: 800);
      return GetJobResponseModel.fromJson(response.body);
    } else {
      log(response.body, name: 'GetJobDatasource', level: 1200);
      throw Exception('Failed to load data');
    }
  }
}
