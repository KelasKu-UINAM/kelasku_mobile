import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static final String baseUrl = _resolveBaseUrl();

  // `??` alone is not enough: a `.env` line like `API_URL=` yields an empty
  // string (not null), which would silently produce an empty baseUrl.
  static String _resolveBaseUrl() {
    final url = dotenv.env['API_URL']?.trim();
    if (url == null || url.isEmpty) return 'http://10.0.2.2:3000';
    return url;
  }

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
