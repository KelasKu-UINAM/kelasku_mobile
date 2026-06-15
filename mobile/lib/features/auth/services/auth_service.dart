import '../models/user_model.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthService {
  static const _dummyAdminEmail = 'admin@kelasku-uinam.test';
  static const _dummyBendaharaEmail = 'bendahara@kelasku-uinam.test';
  static const _dummyMahasiswaEmail = 'mahasiswa@kelasku-uinam.test';
  static const _dummyPassword = 'password123';

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (password != _dummyPassword) {
      throw const AuthException('Email atau password salah', statusCode: 401);
    }

    final user = switch (email) {
      _dummyAdminEmail => const User(
          id: 1,
          name: 'Admin Kelas',
          email: _dummyAdminEmail,
          phone: '6281111111111',
        ),
      _dummyBendaharaEmail => const User(
          id: 2,
          name: 'Bendahara Kelas',
          email: _dummyBendaharaEmail,
          phone: '6281222222222',
        ),
      _dummyMahasiswaEmail => const User(
          id: 3,
          name: 'Mahasiswa Kelas',
          email: _dummyMahasiswaEmail,
          phone: '6281333333333',
        ),
      _ => throw const AuthException('Email atau password salah', statusCode: 401),
    };

    return AuthResult(
      token: 'dummy-jwt-${user.id}-${DateTime.now().millisecondsSinceEpoch}',
      user: user,
    );
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    const reservedEmails = {
      _dummyAdminEmail,
      _dummyBendaharaEmail,
      _dummyMahasiswaEmail,
    };
    if (reservedEmails.contains(email.toLowerCase())) {
      throw const AuthException('Email sudah terdaftar', statusCode: 409);
    }

    // Backend treats phone as optional — send null when empty.
    final normalizedPhone = (phone == null || phone.isEmpty) ? null : phone;

    return User(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      name: name,
      email: email,
      phone: normalizedPhone,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
