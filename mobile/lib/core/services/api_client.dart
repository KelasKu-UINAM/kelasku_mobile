import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

/// Persistent token storage backed by flutter_secure_storage.
/// Also holds the token in-memory for fast interceptor access.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _keyToken = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;

  String? get token => _token;

  Future<void> save(String token) async {
    _token = token;
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> load() async {
    _token = await _storage.read(key: _keyToken);
    return _token;
  }

  Future<void> clear() async {
    _token = null;
    await _storage.delete(key: _keyToken);
  }
}

/// Singleton Dio HTTP client configured for the KelasKu backend.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth interceptor — attaches Bearer token from TokenStorage.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = TokenStorage.instance.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;

  Dio get dio => _dio;

  // ── Convenience wrappers ──────────────────────────────────────

  /// GET [path] with optional [queryParameters].
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  /// POST [path] with [data].
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
  }) =>
      _dio.post<T>(path, data: data);

  /// PUT [path] with [data].
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) =>
      _dio.put<T>(path, data: data);

  /// DELETE [path].
  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}

/// Extracts the `data` field from a standard backend response.
/// Backend always returns: { success, message, data }
dynamic extractData(Response response) {
  final body = response.data;
  if (body is Map<String, dynamic> && body.containsKey('data')) {
    return body['data'];
  }
  return body;
}

/// Extracts error message from DioException.
String extractErrorMessage(DioException e) {
  if (e.response?.data is Map<String, dynamic>) {
    final data = e.response!.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Terjadi kesalahan';
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'Koneksi timeout. Periksa jaringan Anda.';
  }
  if (e.type == DioExceptionType.connectionError) {
    return 'Tidak dapat terhubung ke server.';
  }
  return 'Terjadi kesalahan. Coba lagi.';
}
