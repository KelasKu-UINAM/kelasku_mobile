import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../../classes/providers/class_provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';

class PaymentListScreen extends ConsumerStatefulWidget {
  final int classId;

  const PaymentListScreen({super.key, required this.classId});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(paymentProvider(widget.classId).notifier).fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider(widget.classId));
    final kelas = ref.watch(classByIdProvider(widget.classId));
    final currentUser = ref.watch(currentUserProvider);
    final role = kelas?.roleInClass ?? 'mahasiswa';
    final isManager = role == 'admin_komting' || role == 'bendahara';

    if (paymentState.isLoading && paymentState.payments.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat data iuran...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Iuran Kelas')),
      floatingActionButton: isManager
          ? FloatingActionButton(
              heroTag: 'payment_fab',
              onPressed: () async {
                // createPayments refetches the list from API after creation;
                // no manual refresh needed here.
                await context.push<bool>(
                  '/iuran/tambah?classId=${widget.classId}',
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: paymentState.error != null && paymentState.payments.isEmpty
          ? ErrorStateWidget(
              message: paymentState.error!,
              onRetry: () => ref
                  .read(paymentProvider(widget.classId).notifier)
                  .fetchPayments(forceRefresh: true),
            )
          : isManager
              ? _AdminView(classId: widget.classId)
              : _MahasiswaView(
                  classId: widget.classId,
                  userId: currentUser?.id ?? 0,
                ),
    );
  }
}

// ── Admin / Bendahara View ─────────────────────────────────────

class _AdminView extends ConsumerWidget {
  final int classId;

  const _AdminView({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(paymentsByWeekProvider(classId));
    final summary = ref.watch(paymentSummaryProvider(classId));

    if (grouped.isEmpty) {
      return _EmptyState(classId: classId, isManager: true);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 88),
      children: [
        _SummaryCard(summary: summary),
        const SizedBox(height: 16),
        ...grouped.entries.map(
          (entry) => _WeekGroup(
            classId: classId,
            week: entry.key,
            payments: entry.value,
          ),
        ),
      ],
    );
  }
}

// ── Mahasiswa View ─────────────────────────────────────────────

class _MahasiswaView extends ConsumerWidget {
  final int classId;
  final int userId;

  const _MahasiswaView({required this.classId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPayments = ref.watch(
      myPaymentsProvider((classId: classId, userId: userId)),
    );

    if (myPayments.isEmpty) {
      return _EmptyState(classId: classId, isManager: false);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      itemCount: myPayments.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${myPayments.length} TAGIHAN IURAN',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
          );
        }
        return _MyPaymentRow(payment: myPayments[index - 1]);
      },
    );
  }
}

// ── Summary Card ───────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final PaymentSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 16,
                color: AppColors.accentDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Ringkasan Iuran',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentDark,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.formattedAmountPaid,
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total terkumpul',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        color: AppColors.accentDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${summary.totalPaid} / ${summary.total} lunas',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentDark,
                  ),
                ),
              ),
            ],
          ),
          if (summary.totalUnpaid > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${summary.totalUnpaid} tagihan belum dibayar',
              style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                color: AppColors.accentDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Week Group ─────────────────────────────────────────────────

class _WeekGroup extends ConsumerWidget {
  final int classId;
  final int week;
  final List<PaymentModel> payments;

  const _WeekGroup({
    required this.classId,
    required this.week,
    required this.payments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paid = payments.where((p) => p.isPaid).length;
    final sample = payments.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                'MINGGU KE-$week',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text(
                '$paid/${payments.length} lunas · ${sample.formattedAmount}',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        // Payment rows
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < payments.length; i++) ...[
                if (i > 0)
                  const Divider(height: 0, thickness: 0.5, indent: 52),
                _PaymentRow(
                  classId: classId,
                  payment: payments[i],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

// ── Admin Payment Row ──────────────────────────────────────────

class _PaymentRow extends ConsumerWidget {
  final int classId;
  final PaymentModel payment;

  const _PaymentRow({required this.classId, required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: payment.isPaid
                  ? AppColors.statusGreenBg
                  : AppColors.statusRedBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                payment.userInitial,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: payment.isPaid
                      ? AppColors.statusGreen
                      : AppColors.statusRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              payment.userName ?? '—',
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Status chip or actions
          if (payment.isPaid)
            _StatusChip(isPaid: true)
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(isPaid: false),
                const SizedBox(width: 8),
                // Mark as paid button
                GestureDetector(
                  onTap: () => _confirmMarkPaid(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOverlay,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Lunas',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                if (payment.userPhone != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _openWhatsApp(context, ref, payment),
                    child: const Icon(
                      Icons.chat_outlined,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _confirmMarkPaid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai Lunas?'),
        content: Text(
          '${payment.userName ?? "Anggota"} akan ditandai sudah membayar iuran minggu ke-${payment.paymentWeek}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tandai Lunas'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(paymentProvider(classId).notifier)
        .markPaymentPaid(payment.id);
    if (!ok) {
      final error = ref.read(paymentProvider(classId)).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal menandai lunas. Coba lagi.'),
        ),
      );
    }
  }

  /// The wa.me link is built by the backend from the class's configured
  /// notification template (whatsapp-config), not a hardcoded message.
  Future<void> _openWhatsApp(
    BuildContext context,
    WidgetRef ref,
    PaymentModel p,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final link = await ref
        .read(paymentProvider(classId).notifier)
        .getReminderLink(p.id);

    if (link == null) {
      final error = ref.read(paymentProvider(classId)).error;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal membuat pengingat WhatsApp.'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
      );
    }
  }
}

// ── Mahasiswa Payment Row ──────────────────────────────────────

class _MyPaymentRow extends StatelessWidget {
  final PaymentModel payment;

  const _MyPaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Week badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: payment.isPaid
                  ? AppColors.statusGreenBg
                  : AppColors.statusRedBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${payment.paymentWeek}',
                style: AppTextStyles.h2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: payment.isPaid
                      ? AppColors.statusGreen
                      : AppColors.statusRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minggu ke-${payment.paymentWeek}',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.formattedAmount,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _StatusChip(isPaid: payment.isPaid),
        ],
      ),
    );
  }
}

// ── Status Chip ────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isPaid;

  const _StatusChip({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPaid ? AppColors.statusGreenBg : AppColors.statusRedBg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        isPaid ? 'Lunas' : 'Belum',
        style: AppTextStyles.caption.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isPaid ? AppColors.statusGreen : AppColors.statusRed,
        ),
      ),
    );
  }
}

// ── Empty State (Screen 30) ────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final int classId;
  final bool isManager;

  const _EmptyState({required this.classId, required this.isManager});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: const BoxDecoration(
                color: AppColors.primaryOverlay,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Belum ada tagihan iuran',
              style: AppTextStyles.h2.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isManager
                  ? 'Buat tagihan iuran mingguan untuk semua anggota kelas.'
                  : 'Tagihan iuran kelas akan muncul di sini.',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12.5,
                color: AppColors.textMuted,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            if (isManager) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () =>
                    context.push('/iuran/tambah?classId=$classId'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Text(
                      'Buat Iuran Mingguan',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
