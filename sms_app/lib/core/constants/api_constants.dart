class ApiConstants {
  static const String baseUrl =
      'http://192.168.1.9:3000/smsmitra/v1'; // Replace with your server IP

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String updateToken = '/auth/update-token';

  // SMS Endpoints
  static const String triggerSms = '/sms/trigger';
  static const String syncSims = '/sms/sync';
  static const String updateStatus = '/sms/update-status';
  static const String createLog = '/sms/log';
  static const String getReports = '/sms/reports';
}
