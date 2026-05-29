import 'package:flutter/foundation.dart';

@immutable
class ClassMember {
  final int id;
  final int classId;
  final int userId;
  final String name;
  final String email;
  final String? phone;
  final String roleInClass;
  final DateTime? joinedAt;

  const ClassMember({
    required this.id,
    required this.classId,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.roleInClass,
    this.joinedAt,
  });

  factory ClassMember.fromJson(Map<String, dynamic> json) {
    return ClassMember(
      id: (json['id'] as num).toInt(),
      classId: (json['class_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      roleInClass: json['role_in_class'] as String? ?? 'mahasiswa',
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString())
          : null,
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get roleLabel {
    switch (roleInClass) {
      case 'admin_komting':
        return 'Komting';
      case 'bendahara':
        return 'Bendahara';
      default:
        return 'Mahasiswa';
    }
  }

  bool get isAdmin => roleInClass == 'admin_komting';
  bool get isBendahara => roleInClass == 'bendahara';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassMember && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
