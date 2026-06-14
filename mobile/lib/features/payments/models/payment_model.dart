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
    this.createdAt,
    this.updatedAt,
    this.userName,
    this.userEmail,
    this.userPhone,
  });

  bool get isPaid => status == 'paid';

  String get formattedAmount {
    final s = amount.toInt().toString();
    final formatted =
        s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
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
      amount: (json['amount'] as num).toDouble(),
      paymentWeek: (json['payment_week'] as num).toInt(),
      status: json['status'] as String? ?? 'unpaid',
      paidAt: _parseDate(json['paid_at']),
      note: json['note'] as String?,
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
