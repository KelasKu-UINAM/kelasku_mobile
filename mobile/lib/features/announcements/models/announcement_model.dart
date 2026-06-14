import 'package:flutter/foundation.dart';

@immutable
class AnnouncementModel {
  final int id;
  final int classId;
  final int? subjectId;
  final String? subjectName;
  final String title;
  final String content;
  final int? createdBy;
  final String? creatorName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.classId,
    this.subjectId,
    this.subjectName,
    required this.title,
    required this.content,
    this.createdBy,
    this.creatorName,
    this.createdAt,
    this.updatedAt,
  });

  bool get isUmum => subjectId == null;

  String get chipLabel => isUmum ? 'Umum' : (subjectName ?? 'Umum');

  static const _months = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String get formattedDateShort {
    if (createdAt == null) return '';
    return '${createdAt!.day} ${_months[createdAt!.month]}';
  }

  String get formattedDateFull {
    if (createdAt == null) return '';
    final h = createdAt!.hour.toString().padLeft(2, '0');
    final m = createdAt!.minute.toString().padLeft(2, '0');
    return '${createdAt!.day} ${_months[createdAt!.month]} ${createdAt!.year} · $h:$m';
  }

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: (json['id'] as num).toInt(),
      classId: (json['class_id'] as num).toInt(),
      subjectId: json['subject_id'] != null
          ? (json['subject_id'] as num).toInt()
          : null,
      subjectName: json['subject_name'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdBy: json['created_by'] != null
          ? (json['created_by'] as num).toInt()
          : null,
      creatorName: json['creator_name'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  // updateAnnouncement requires explicit nullable subjectId → construct new instance directly
  // to avoid sentinel-value workarounds in copyWith.
  AnnouncementModel copyWith({
    int? id,
    int? classId,
    String? title,
    String? content,
    int? createdBy,
    String? creatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      subjectId: subjectId,
      subjectName: subjectName,
      title: title ?? this.title,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
