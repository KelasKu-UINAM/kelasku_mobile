import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static final String baseUrl = dotenv.env['API_URL'] ?? 'http://10.0.2.2:3000';

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
