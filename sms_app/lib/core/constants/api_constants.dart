class ApiConstants {
  static const String baseUrl =
      'https://silverapi.allysoftsolutions.com/smsmitra/v1'; // Replace with your server IP

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String updateToken = '/auth/update-token';
  static const String updateProfile = '/auth/update-profile';

  // SMS Endpoints
  static const String triggerSms = '/sms/trigger';
  static const String syncSims = '/sms/sync';
  static const String updateStatus = '/sms/update-status';
  static const String createLog = '/sms/log';
  static const String getReports = '/sms/reports';
}
