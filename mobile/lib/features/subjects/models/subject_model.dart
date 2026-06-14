import 'package:flutter/foundation.dart';

@immutable
class SubjectModel {
  final int id;
  final int classId;
  final String name;
  final String? lecturer;
  final String? code;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubjectModel({
    required this.id,
    required this.classId,
    required this.name,
    this.lecturer,
    this.code,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: (json['id'] as num).toInt(),
      classId: (json['class_id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      lecturer: json['lecturer'] as String?,
      code: json['code'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  SubjectModel copyWith({
    int? id,
    int? classId,
    String? name,
    String? lecturer,
    String? code,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
