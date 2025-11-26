/// Global variables and constants used throughout the application.
///
/// This class contains API endpoints, shared preferences keys, and other constant values.
class Variables {
  /// The base URL for the main API.
  static const String baseUrl = 'http://quetraverse.pro/efms/api/myapi';
  static const String imageBaseUrl = '$baseUrl/public/storage//';

  // API endpoints helper methods
  static String getProfileEndpoint(String userId) =>
      '$baseUrl/get-user/$userId';
  static String getJobHistoryEndpoint(String userId) =>
      '$baseUrl/get-job-by-user/$userId';
  static String getOngoingJobEndpoint(String userId) =>
      '$baseUrl/get-job-ongoing/$userId';
  static String getCheckTypeCompanyEndpoint(int companyId) =>
      '$baseUrl/check-type-company/$companyId';
  // API endpoints
  static const String loginEndpoint = '$baseUrl/login';
  static const String logoutEndpoint = '$baseUrl/logout';
  static const String forgotPasswordEndpoint = '$baseUrl/forgot-password';
  static const String getJobEndpoint = '$baseUrl/get-job';

  static const String driverGetJobEndpoint = '$baseUrl/driver-get-job';
  static const String driverGetJob = '$baseUrl/driver-get-job?';
  static const String finishedJobEndpoint = '$baseUrl/finished-job';
  static const String reportJobEndpoint = '$baseUrl/report-job';
  static const String postponeJobEndpoint = '$baseUrl/postpone-job';
  static const String cancelJobEndpoint = '$baseUrl/cancel-job';
  static const String rescheduleJobEndpoint = '$baseUrl/reschedule-job';

  // Traxroot endpoints
  /// Base URL for Traxroot API.
  static const String traxrootBaseUrl = 'https://connect.traxroot.com/api';
  static const String traxrootTokenEndpoint = '$traxrootBaseUrl/Token';
  // static const String traxrootUsername = 'euodoo';
  // static const String traxrootPassword = 'euodoo360';
  static const int traxrootSubUserId = 0;
  static const String traxrootLanguage = 'en';
  static const String traxrootIconBaseUrl = 'https://connect.traxroot.com';
  static const String traxrootInternalBaseUrl =
      'http://quetraverse.pro/efms/internal/v1/api/traxroot';
  static const String traxrootObjectsStatusEndpoint =
      '$traxrootBaseUrl/ObjectsStatus';
  static String getTraxrootObjectStatusEndpoint(int objectId) =>
      '$traxrootBaseUrl/ObjectsStatus/$objectId';
  static const String traxrootObjectIconsEndpoint =
      '$traxrootBaseUrl/Objects/Icons';
  static const String traxrootObjectsEndpoint = '$traxrootBaseUrl/Objects';
  static const String traxrootDriversEndpoint = '$traxrootBaseUrl/Drivers';
  static String getTraxrootDriverEndpoint(int driverId) =>
      '$traxrootBaseUrl/Drivers/$driverId';
  static const String traxrootGeozonesEndpoint = '$traxrootBaseUrl/Geozones';
  static const String traxrootGeozoneIconsEndpoint =
      '$traxrootBaseUrl/Geozones/Icons';
  static const String traxrootProfileEndpoint = '$traxrootBaseUrl/profile';
  // static const String traxrootInternalDriversEndpoint =
  //     '$traxrootInternalBaseUrl/getDrivers';
  // static String traxrootInternalDriverByIdEndpoint(int driverId) =>
  //     '$traxrootInternalBaseUrl/getDrivers/$driverId';
  // static String traxrootInternalGeozoneByIdEndpoint(int geozoneId) =>
  //     '$traxrootInternalBaseUrl/getGeozones/$geozoneId';
  // static const String traxrootInternalGeozonesEndpoint =
  //     '$traxrootInternalBaseUrl/getGeozones';
  // static const String traxrootInternalGeozoneIconsEndpoint =
  //     '$traxrootInternalBaseUrl/getGeozoneIcons';

  // Shared Preferences keys
  /// Key for storing API Key in Shared Preferences.
  static const String prefApiKey = 'apiKey';
  static const String prefUserID = 'UserID';
  static const String prefCompany = 'Company';
  static const String prefCompanyID = 'CompanyID';
  static const String prefCompanyType = 'CompanyType';
  static const String prefCompanyLabel = 'CompanyLabel';
  static const String prefTraxrootUsername = 'TraxrootUsername';
  static const String prefTraxrootPassword = 'TraxrootPassword';

  static const String prefTraxrootToken = 'TraxrootAccessToken';
  static const String prefTraxrootTokenExpiry = 'TraxrootAccessTokenExpiry';
}
