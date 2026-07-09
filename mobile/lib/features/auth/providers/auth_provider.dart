import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_client.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String token;

  const AuthAuthenticated({required this.user, required this.token});
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthInitial());

  /// Try to restore a previous session from stored token.
  Future<bool> tryAutoLogin() async {
    final token = await TokenStorage.instance.load();
    if (token == null || token.isEmpty) return false;

    state = const AuthLoading();
    try {
      final user = await _service.getProfile();
      state = AuthAuthenticated(user: user, token: token);
      return true;
    } catch (_) {
      // Token expired or invalid — clear and go to login.
      await TokenStorage.instance.clear();
      state = const AuthInitial();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _service.login(email: email, password: password);
      state = AuthAuthenticated(user: result.user, token: result.token);
      return true;
    } on AuthException catch (e) {
      state = AuthFailure(e.message);
      return false;
    } catch (_) {
      state = const AuthFailure('Terjadi kesalahan. Coba lagi.');
      return false;
    }
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _service.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = const AuthInitial();
      return user;
    } on AuthException catch (e) {
      state = AuthFailure(e.message);
      return null;
    } catch (_) {
      state = const AuthFailure('Terjadi kesalahan. Coba lagi.');
      return null;
    }
  }

  Future<void> logout() async {
    await TokenStorage.instance.clear();
    state = const AuthInitial();
  }

  /// Invoked by the global 401 interceptor: the token is already cleared,
  /// so just drop the in-memory session. The router listens to auth state
  /// and will redirect to /login.
  void handleSessionExpired() {
    if (state is AuthAuthenticated || state is AuthLoading) {
      state = const AuthInitial();
    }
  }

  void clearError() {
    if (state is AuthFailure) {
      state = const AuthInitial();
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);

final currentUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthAuthenticated ? state.user : null;
});

final authTokenProvider = Provider<String?>((ref) {
  final state = ref.watch(authProvider);
  return state is AuthAuthenticated ? state.token : null;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});
