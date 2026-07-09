import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthService {
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '${ApiConstants.auth}/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = extractData(response) as Map<String, dynamic>;
      final result = AuthResult.fromJson(data);

      // Persist token for subsequent authenticated requests.
      await TokenStorage.instance.save(result.token);

      return result;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = extractErrorMessage(e);
      throw AuthException(message, statusCode: statusCode);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('Terjadi kesalahan. Coba lagi.');
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '${ApiConstants.auth}/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );

      final data = extractData(response) as Map<String, dynamic>;
      return User.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = extractErrorMessage(e);
      throw AuthException(message, statusCode: statusCode);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('Terjadi kesalahan. Coba lagi.');
    }
  }

  /// Fetches the current user profile using the stored token.
  Future<User> getProfile() async {
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.auth}/profile',
      );

      final data = extractData(response) as Map<String, dynamic>;
      return User.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = extractErrorMessage(e);
      throw AuthException(message, statusCode: statusCode);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('Terjadi kesalahan. Coba lagi.');
    }
  }

  /// Updates name/phone of the logged-in user. Email cannot be changed.
  Future<User> updateProfile({required String name, String? phone}) async {
    try {
      final response = await ApiClient.instance.put(
        '${ApiConstants.auth}/profile',
        data: {
          'name': name,
          'phone': (phone == null || phone.isEmpty) ? null : phone,
        },
      );

      final data = extractData(response) as Map<String, dynamic>;
      return User.fromJson(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = extractErrorMessage(e);
      throw AuthException(message, statusCode: statusCode);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('Terjadi kesalahan. Coba lagi.');
    }
  }

  /// Changes the password; the backend verifies [oldPassword] first.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await ApiClient.instance.put(
        '${ApiConstants.auth}/password',
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = extractErrorMessage(e);
      throw AuthException(message, statusCode: statusCode);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw const AuthException('Terjadi kesalahan. Coba lagi.');
    }
  }
}
