import 'package:flutter/foundation.dart';

@immutable
class PaymentModel {
  final int id;
  final int classId;
  final int userId;
  final double amount;
  final int paymentWeek;
  final String status;
  final DateTime? paidAt;
  final String? note;
  final String? pakasirOrderId;
  final String? pakasirPaymentUrl;
  final String? pakasirQrString;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // From JOIN users (getClassPayments only — null in getMyPayments)
  final String? userName;
  final String? userEmail;
  final String? userPhone;

  const PaymentModel({
    required this.id,
    required this.classId,
    required this.userId,
    required this.amount,
    required this.paymentWeek,
    required this.status,
    this.paidAt,
    this.note,
    this.pakasirOrderId,
    this.pakasirPaymentUrl,
    this.pakasirQrString,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  bool get isPaid => status == 'paid';

  String get formattedAmount {
    final s = amount.toInt().toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  String get userInitial {
    final n = (userName ?? '').trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as num).toInt(),
      classId: (json['class_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      amount: (json['amount'] is String
          ? double.parse(json['amount'] as String)
          : (json['amount'] as num))
          .toDouble(),
      paymentWeek: (json['payment_week'] as num).toInt(),
      status: json['status'] as String? ?? 'unpaid',
      paidAt: _parseDate(json['paid_at']),
      note: json['note'] as String?,
      pakasirOrderId: json['pakasir_order_id'] as String?,
      pakasirPaymentUrl: json['pakasir_payment_url'] as String?,
      pakasirQrString: json['pakasir_qr_string'] as String?,
      expiresAt: _parseDate(json['expires_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      userPhone: json['user_phone'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  PaymentModel copyWith({
    String? status,
    DateTime? paidAt,
    String? pakasirOrderId,
    String? pakasirPaymentUrl,
    String? pakasirQrString,
    DateTime? expiresAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id,
      classId: classId,
      userId: userId,
      amount: amount,
      paymentWeek: paymentWeek,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      note: note,
      pakasirOrderId: pakasirOrderId ?? this.pakasirOrderId,
      pakasirPaymentUrl: pakasirPaymentUrl ?? this.pakasirPaymentUrl,
      pakasirQrString: pakasirQrString ?? this.pakasirQrString,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PaymentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class PaymentQrisModel {
  final int paymentId;
  final String orderId;
  final double amount;
  final String? paymentUrl;
  final String? qrString;
  final DateTime? expiredAt;
  final String? expiredTime;

  const PaymentQrisModel({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    this.paymentUrl,
    this.qrString,
    this.expiredAt,
    this.expiredTime,
  });

  factory PaymentQrisModel.fromJson(Map<String, dynamic> json) {
    return PaymentQrisModel(
      paymentId: (json['payment_id'] as num).toInt(),
      orderId: json['order_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentUrl: json['payment_url'] as String?,
      qrString: json['qr_string'] as String?,
      expiredAt: PaymentModel._parseDate(json['expired_at']),
      expiredTime: json['expired_time'] as String?,
    );
  }
}

@immutable
class PaymentSummary {
  final int totalPaid;
  final int totalUnpaid;
  final double totalAmountPaid;
  final double totalAmountUnpaid;

  const PaymentSummary({
    required this.totalPaid,
    required this.totalUnpaid,
    required this.totalAmountPaid,
    required this.totalAmountUnpaid,
  });

  int get total => totalPaid + totalUnpaid;

  String get formattedAmountPaid {
    final s = totalAmountPaid.toInt().toString();
    return 'Rp ${s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
  }
}
