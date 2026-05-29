class Validators {
  Validators._();

  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final pattern = RegExp(r"^[\w.!#$%&'*+/=?^`{|}~-]+@[\w-]+(?:\.[\w-]+)+$");
    if (!pattern.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < minLength) {
      return 'Password minimal $minLength karakter';
    }
    return null;
  }

  static String? Function(String?) passwordMatch(String Function() original) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Konfirmasi password tidak boleh kosong';
      }
      if (value != original()) {
        return 'Password tidak cocok';
      }
      return null;
    };
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'No HP tidak boleh kosong';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s+\-()]'), '');
    final pattern = RegExp(r'^(62|0)8[1-9]\d{6,11}$');
    if (!pattern.hasMatch(cleaned)) {
      return 'Format no HP tidak valid';
    }
    return null;
  }

  static String? name(String? value, {int minLength = 3}) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.trim().length < minLength) {
      return 'Nama minimal $minLength karakter';
    }
    return null;
  }

  static String? academicYear(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final pattern = RegExp(r'^\d{4}\/\d{4}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Format: 2025/2026 (tahun akademik)';
    }
    final parts = value.trim().split('/');
    final y1 = int.parse(parts[0]);
    final y2 = int.parse(parts[1]);
    if (y2 != y1 + 1) return 'Format: 2025/2026 (tahun akademik)';
    return null;
  }

  static String normalizePhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\s+\-()]'), '');
    if (cleaned.startsWith('0')) {
      return '62${cleaned.substring(1)}';
    }
    if (cleaned.startsWith('62')) {
      return cleaned;
    }
    return cleaned;
  }
}
