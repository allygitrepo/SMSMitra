class ApiConstants {
  // static const String baseUrl = 'https://silverapi.allysoftsolutions.com/smsmitra/v1';
  static const String baseUrl = 'http://172.24.56.111:5000/smsmitra/v1';

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String updateToken = '/auth/update-token';
  static const String updateProfile = '/auth/update-profile';

  // SMS Endpoints
  static const String syncSims = '/sms/sync';
  static const String updateStatus = '/sms/update-status';
  static const String createLog = '/sms/log';
  static const String getReports = '/sms/reports';

  // Schedule Endpoints
  static const String schedules = '/schedules';
  static const String frequent = '/frequent';

  // Templates & Bulk Endpoints
  static const String templates = '/templates';
  static const String bulk = '/bulk';
}
