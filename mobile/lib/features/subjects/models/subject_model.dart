import 'package:flutter/foundation.dart';

@immutable
class SubjectModel {
  final int id;
  final int classId;
  final String name;
  final String? lecturer;
  final String? code;

  /// Whether the current user marked this subject as one they take.
  /// Comes from the backend's per-user `is_followed` flag.
  final bool isFollowed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubjectModel({
    required this.id,
    required this.classId,
    required this.name,
    this.lecturer,
    this.code,
    this.isFollowed = false,
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
      isFollowed: json['is_followed'] == true,
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
    bool? isFollowed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      code: code ?? this.code,
      isFollowed: isFollowed ?? this.isFollowed,
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
