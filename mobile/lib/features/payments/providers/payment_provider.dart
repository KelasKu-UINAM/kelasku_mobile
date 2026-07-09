import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.classes}/$_classId/payments',
      );
      final data = extractData(response) as List<dynamic>;
      final payments = data
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(payments: payments, isLoading: false);
      _loaded = true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }

  /// Returns true on success; on failure sets [PaymentState.error] and
  /// returns false so callers can keep the form open.
  Future<bool> createPayments({
    required int paymentWeek,
    required double amount,
    String? note,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '${ApiConstants.classes}/$_classId/payments',
        data: {
          'amount': amount,
          'payment_week': paymentWeek,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final data = extractData(response) as Map<String, dynamic>;
      final newPayments = (data['payments'] as List<dynamic>?)
              ?.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      state = state.copyWith(
        payments: [...state.payments, ...newPayments],
      );
      // Refetch to get user JOINed fields.
      await fetchPayments(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> markPaymentPaid(int id) async {
    try {
      await ApiClient.instance.put(
        '/api/payments/$id/pay',
      );
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
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return false;
    }
  }

  /// Asks the backend for a wa.me reminder link built from the class's
  /// configured WhatsApp template. Returns null on failure (error set).
  Future<String?> getReminderLink(int paymentId) async {
    try {
      final response = await ApiClient.instance.post(
        '${ApiConstants.classes}/$_classId/send-payment-reminder',
        data: {'payment_id': paymentId},
      );
      final data = extractData(response) as Map<String, dynamic>;
      return data['whatsapp_link'] as String?;
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
      return null;
    } catch (_) {
      state = state.copyWith(error: 'Terjadi kesalahan. Coba lagi.');
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);
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
