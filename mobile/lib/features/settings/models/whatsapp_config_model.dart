import 'package:flutter/foundation.dart';

/// Default reminder template — mirrors backend `defaultTemplate` in
/// whatsapp.service.js so the UI matches what the server falls back to.
const String kDefaultWhatsappTemplate =
    'Assalamu alaikum {name}, mohon membayar iuran minggu ke-{payment_week} '
    'sebesar Rp{amount}. Terima kasih.';

@immutable
class WhatsappConfigModel {
  final int? id; // null when no row exists yet (backend returns default object)
  final int classId;
  final String? adminPhone;
  final String? treasurerPhone;
  final String notificationTemplate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WhatsappConfigModel({
    this.id,
    required this.classId,
    this.adminPhone,
    this.treasurerPhone,
    this.notificationTemplate = kDefaultWhatsappTemplate,
    this.createdAt,
    this.updatedAt,
  });

  factory WhatsappConfigModel.fromJson(Map<String, dynamic> json) {
    return WhatsappConfigModel(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      classId: (json['class_id'] as num).toInt(),
      adminPhone: json['admin_phone'] as String?,
      treasurerPhone: json['treasurer_phone'] as String?,
      notificationTemplate:
          json['notification_template'] as String? ?? kDefaultWhatsappTemplate,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'admin_phone': adminPhone,
        'treasurer_phone': treasurerPhone,
        'notification_template': notificationTemplate,
      };

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  WhatsappConfigModel copyWith({
    int? id,
    String? adminPhone,
    String? treasurerPhone,
    String? notificationTemplate,
    DateTime? updatedAt,
  }) {
    return WhatsappConfigModel(
      id: id ?? this.id,
      classId: classId,
      adminPhone: adminPhone ?? this.adminPhone,
      treasurerPhone: treasurerPhone ?? this.treasurerPhone,
      notificationTemplate: notificationTemplate ?? this.notificationTemplate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Renders the template with sample values for the live preview.
  String previewMessage() {
    return notificationTemplate
        .replaceAll('{name}', 'Budi')
        .replaceAll('{payment_week}', '3')
        .replaceAll('{amount}', '10.000')
        .replaceAll('{status}', 'belum bayar');
  }
}
