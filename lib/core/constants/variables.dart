class Variables {
  static const String baseUrl =
      // 'http://192.168.1.11:8000'; //or replace with your website url as backend
      'http://quetraverse.pro/efms/api/myapi';
  static const String imageBaseUrl = '$baseUrl/public/storage//';

  // API endpoints helper methods
  static String getProfileEndpoint(String userId) =>
      '$baseUrl/get-user/$userId';
  static String getJobHistoryEndpoint(String userId) =>
      '$baseUrl/get-job-by-user/$userId';
  static String getOngoingJobEndpoint(String userId) =>
      '$baseUrl/get-job-ongoing/$userId';
  // API endpoints
  static const String loginEndpoint = '$baseUrl/login';
  static const String logoutEndpoint = '$baseUrl/logout';
  static const String getJobEndpoint = '$baseUrl/get-job';

  static const String driverGetJobEndpoint = '$baseUrl/driver-get-job';
  static const String driverGetJob = '$baseUrl/driver-get-job?';
  static const String finishedJobEndpoint = '$baseUrl/finished-job';

  // Shared Preferences keys
  static const String prefApiKey = 'apiKey';
  static const String prefUserID = 'UserID';
}
