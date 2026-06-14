import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_model.dart';

@immutable
class PaymentState {
  final List<PaymentModel> payments;
  final bool isLoading;
  final String? error;

  const PaymentState({
    this.payments = const [],
    this.isLoading = false,
    this.error,
  });

  PaymentState copyWith({
    List<PaymentModel>? payments,
    bool? isLoading,
    String? error,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier(this._classId) : super(const PaymentState());

  final int _classId;
  bool _loaded = false;

  Future<void> fetchPayments({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (_classId != 1) {
      state = state.copyWith(payments: const [], isLoading: false);
      _loaded = true;
      return;
    }

    state = state.copyWith(payments: _buildDummy(), isLoading: false);
    _loaded = true;
  }

  List<PaymentModel> _buildDummy() {
    const amount = 10000.0;
    const note = 'Iuran mingguan kelas';
    final now = DateTime.now();
    final week1 = now.subtract(const Duration(days: 7));

    return [
      PaymentModel(
        id: 1,
        classId: 1,
        userId: 1,
        amount: amount,
        paymentWeek: 1,
        status: 'paid',
        paidAt: week1.add(const Duration(days: 1)),
        note: note,
        userName: 'Admin Kelas',
        userPhone: '6281111111111',
        createdAt: week1,
      ),
      PaymentModel(
        id: 2,
        classId: 1,
        userId: 2,
        amount: amount,
        paymentWeek: 1,
        status: 'paid',
        paidAt: week1.add(const Duration(days: 2)),
        note: note,
        userName: 'Bendahara Kelas',
        userPhone: '6281222222222',
        createdAt: week1,
      ),
      PaymentModel(
        id: 3,
        classId: 1,
        userId: 3,
        amount: amount,
        paymentWeek: 1,
        status: 'unpaid',
        note: note,
        userName: 'Mahasiswa Kelas',
        userPhone: '6281333333333',
        createdAt: week1,
      ),
      PaymentModel(
        id: 4,
        classId: 1,
        userId: 1,
        amount: amount,
        paymentWeek: 2,
        status: 'unpaid',
        note: note,
        userName: 'Admin Kelas',
        userPhone: '6281111111111',
        createdAt: now,
      ),
      PaymentModel(
        id: 5,
        classId: 1,
        userId: 2,
        amount: amount,
        paymentWeek: 2,
        status: 'paid',
        paidAt: now,
        note: note,
        userName: 'Bendahara Kelas',
        userPhone: '6281222222222',
        createdAt: now,
      ),
      PaymentModel(
        id: 6,
        classId: 1,
        userId: 3,
        amount: amount,
        paymentWeek: 2,
        status: 'unpaid',
        note: note,
        userName: 'Mahasiswa Kelas',
        userPhone: '6281333333333',
        createdAt: now,
      ),
    ];
  }

  Future<void> createPayments({
    required int paymentWeek,
    required double amount,
    String? note,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Respect UNIQUE(class_id, user_id, payment_week) — skip if week exists
    final existingWeeks =
        state.payments.map((p) => p.paymentWeek).toSet();
    if (existingWeeks.contains(paymentWeek)) return;

    final members = [
      (userId: 1, name: 'Admin Kelas', phone: '6281111111111'),
      (userId: 2, name: 'Bendahara Kelas', phone: '6281222222222'),
      (userId: 3, name: 'Mahasiswa Kelas', phone: '6281333333333'),
    ];

    var nextId = state.payments.isEmpty
        ? 1
        : state.payments.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

    final newPayments = members
        .map(
          (m) => PaymentModel(
            id: nextId++,
            classId: _classId,
            userId: m.userId,
            amount: amount,
            paymentWeek: paymentWeek,
            status: 'unpaid',
            note: note,
            userName: m.name,
            userPhone: m.phone,
            createdAt: DateTime.now(),
          ),
        )
        .toList();

    state = state.copyWith(
      payments: [...state.payments, ...newPayments],
    );
  }

  Future<void> markPaymentPaid(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      payments: state.payments.map((p) {
        if (p.id != id) return p;
        return p.copyWith(
          status: 'paid',
          paidAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList(),
    );
  }
}

final paymentProvider =
    StateNotifierProvider.family<PaymentNotifier, PaymentState, int>(
  (ref, classId) => PaymentNotifier(classId),
);

// Grouped by week (week ASC), each group sorted by name ASC.
final paymentsByWeekProvider =
    Provider.family<Map<int, List<PaymentModel>>, int>((ref, classId) {
  final payments = ref.watch(paymentProvider(classId)).payments;
  final grouped = <int, List<PaymentModel>>{};
  for (final p in payments) {
    (grouped[p.paymentWeek] ??= []).add(p);
  }
  for (final list in grouped.values) {
    list.sort((a, b) => (a.userName ?? '').compareTo(b.userName ?? ''));
  }
  final sorted = Map.fromEntries(
    grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
  return sorted;
});

// Current user's own payments sorted by week ASC.
final myPaymentsProvider =
    Provider.family<List<PaymentModel>, ({int classId, int userId})>(
  (ref, params) {
    final payments = ref.watch(paymentProvider(params.classId)).payments;
    return payments
        .where((p) => p.userId == params.userId)
        .toList()
      ..sort((a, b) => a.paymentWeek.compareTo(b.paymentWeek));
  },
);

// Aggregate summary computed from the full list.
final paymentSummaryProvider =
    Provider.family<PaymentSummary, int>((ref, classId) {
  final payments = ref.watch(paymentProvider(classId)).payments;
  final paid = payments.where((p) => p.isPaid).toList();
  final unpaid = payments.where((p) => !p.isPaid).toList();
  return PaymentSummary(
    totalPaid: paid.length,
    totalUnpaid: unpaid.length,
    totalAmountPaid: paid.fold(0.0, (s, p) => s + p.amount),
    totalAmountUnpaid: unpaid.fold(0.0, (s, p) => s + p.amount),
  );
});
