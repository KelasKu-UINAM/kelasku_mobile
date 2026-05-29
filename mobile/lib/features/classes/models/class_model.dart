import 'package:flutter/foundation.dart';

@immutable
class ClassModel {
  final int id;
  final String name;
  final String? faculty;
  final String? department;
  final int? semester;
  final String? academicYear;
  final String classCode;
  final int? createdBy;
  final String? roleInClass;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClassModel({
    required this.id,
    required this.name,
    this.faculty,
    this.department,
    this.semester,
    this.academicYear,
    required this.classCode,
    this.createdBy,
    this.roleInClass,
    this.createdAt,
    this.updatedAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      faculty: json['faculty'] as String?,
      department: json['department'] as String?,
      semester: json['semester'] != null ? (json['semester'] as num).toInt() : null,
      academicYear: json['academic_year'] as String?,
      classCode: json['class_code'] as String? ?? '',
      createdBy: json['created_by'] != null ? (json['created_by'] as num).toInt() : null,
      roleInClass: json['role_in_class'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  String get semesterLabel => semester != null ? 'Semester $semester' : '';

  String get subtitleLine =>
      [faculty, department].nonNulls.join(' · ');

  String get periodLine =>
      [if (semesterLabel.isNotEmpty) semesterLabel, academicYear]
          .nonNulls
          .join(' · ');

  ClassModel copyWith({
    int? id,
    String? name,
    String? faculty,
    String? department,
    int? semester,
    String? academicYear,
    String? classCode,
    int? createdBy,
    String? roleInClass,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      faculty: faculty ?? this.faculty,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      classCode: classCode ?? this.classCode,
      createdBy: createdBy ?? this.createdBy,
      roleInClass: roleInClass ?? this.roleInClass,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
