import 'package:flutter/foundation.dart';

@immutable
class ScheduleModel {
  final int id;
  final int subjectId;
  final String subjectName;
  final String? lecturer;
  final String? subjectCode;
  final String day;
  final String startTime;
  final String endTime;
  final String? room;
  final int reminderMinutesBefore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ScheduleModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    this.lecturer,
    this.subjectCode,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.room,
    this.reminderMinutesBefore = 15,
    this.createdAt,
    this.updatedAt,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: (json['id'] as num).toInt(),
      subjectId: (json['subject_id'] as num).toInt(),
      subjectName: json['subject_name'] as String? ?? '',
      lecturer: json['lecturer'] as String?,
      subjectCode: json['subject_code'] as String?,
      day: json['day'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      room: json['room'] as String?,
      reminderMinutesBefore: json['reminder_minutes_before'] != null
          ? (json['reminder_minutes_before'] as num).toInt()
          : 15,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  int get dayOrder {
    const order = {
      'senin': 1,
      'selasa': 2,
      'rabu': 3,
      'kamis': 4,
      'jumat': 5,
      'sabtu': 6,
      'minggu': 7,
    };
    return order[day.toLowerCase()] ?? 8;
  }

  String get dayLabel {
    const labels = {
      'senin': 'Senin',
      'selasa': 'Selasa',
      'rabu': 'Rabu',
      'kamis': 'Kamis',
      'jumat': 'Jumat',
      'sabtu': 'Sabtu',
      'minggu': 'Minggu',
    };
    return labels[day.toLowerCase()] ?? day;
  }

  bool isOngoing(DateTime now) {
    if (_weekdayToDay(now.weekday) != day.toLowerCase()) return false;
    final start = _parseTimeMinutes(startTime);
    final end = _parseTimeMinutes(endTime);
    if (start == null || end == null) return false;
    final nowMins = now.hour * 60 + now.minute;
    return nowMins >= start && nowMins < end;
  }

  bool isPast(DateTime now) {
    if (_weekdayToDay(now.weekday) != day.toLowerCase()) return false;
    final end = _parseTimeMinutes(endTime);
    if (end == null) return false;
    return now.hour * 60 + now.minute >= end;
  }

  static int? _parseTimeMinutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _weekdayToDay(int weekday) {
    const map = {
      1: 'senin',
      2: 'selasa',
      3: 'rabu',
      4: 'kamis',
      5: 'jumat',
      6: 'sabtu',
      7: 'minggu',
    };
    return map[weekday] ?? '';
  }

  ScheduleModel copyWith({
    int? id,
    int? subjectId,
    String? subjectName,
    String? lecturer,
    String? subjectCode,
    String? day,
    String? startTime,
    String? endTime,
    String? room,
    int? reminderMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      lecturer: lecturer ?? this.lecturer,
      subjectCode: subjectCode ?? this.subjectCode,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
