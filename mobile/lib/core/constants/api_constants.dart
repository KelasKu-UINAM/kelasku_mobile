class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://localhost:3000';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String auth = '/api/auth';
  static const String classes = '/api/classes';
  static const String subjects = '/api/subjects';
  static const String schedules = '/api/schedules';
  static const String announcements = '/api/announcements';
  static const String tasks = '/api/tasks';
  static const String payments = '/api/payments';
  static const String forums = '/api/forums';
}
