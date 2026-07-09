import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
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
  bool? _requestedMineOnly;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(classProvider.notifier).fetchClasses();
      _loadPayments(mineOnly: true);
    });
  }

  Future<void> _loadPayments({required bool mineOnly}) async {
    _requestedMineOnly = mineOnly;
    await ref
        .read(paymentProvider(widget.classId).notifier)
        .fetchPayments(forceRefresh: true, mineOnly: mineOnly);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider(widget.classId));
    final kelas = ref.watch(classByIdProvider(widget.classId));
    final role = kelas?.roleInClass ?? 'mahasiswa';
    final isTreasurer = role == 'bendahara';
    final desiredMineOnly = !isTreasurer;

    if (_requestedMineOnly != null && _requestedMineOnly != desiredMineOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadPayments(mineOnly: desiredMineOnly);
        }
      });
    }

    if (paymentState.isLoading && paymentState.payments.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingWidget(message: 'Memuat data iuran...'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Iuran Kelas')),
      floatingActionButton: isTreasurer
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
                  .fetchPayments(forceRefresh: true, mineOnly: desiredMineOnly),
            )
          : isTreasurer
          ? _AdminView(classId: widget.classId)
          : _MahasiswaView(classId: widget.classId),
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

  const _MahasiswaView({required this.classId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPayments = [...ref.watch(paymentProvider(classId)).payments]
      ..sort((a, b) => a.paymentWeek.compareTo(b.paymentWeek));

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
        return _MyPaymentRow(classId: classId, payment: myPayments[index - 1]);
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
                if (i > 0) const Divider(height: 0, thickness: 0.5, indent: 52),
                _PaymentRow(classId: classId, payment: payments[i]),
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
                      horizontal: 8,
                      vertical: 4,
                    ),
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
        SnackBar(content: Text(error ?? 'Gagal menandai lunas. Coba lagi.')),
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
        SnackBar(content: Text(error ?? 'Gagal membuat pengingat WhatsApp.')),
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

class _MyPaymentRow extends ConsumerStatefulWidget {
  final int classId;
  final PaymentModel payment;

  const _MyPaymentRow({required this.classId, required this.payment});

  @override
  ConsumerState<_MyPaymentRow> createState() => _MyPaymentRowState();
}

class _MyPaymentRowState extends ConsumerState<_MyPaymentRow> {
  bool _isCreatingQris = false;

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;

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
          payment.isPaid
              ? _StatusChip(isPaid: true)
              : GestureDetector(
                  onTap: _isCreatingQris ? null : _startPayment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      _isCreatingQris ? '...' : 'Bayar',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _startPayment() async {
    setState(() => _isCreatingQris = true);
    final messenger = ScaffoldMessenger.of(context);
    final qris = await ref
        .read(paymentProvider(widget.classId).notifier)
        .createPaymentQris(widget.payment.id);

    if (!mounted) return;
    setState(() => _isCreatingQris = false);

    if (qris == null) {
      final error = ref.read(paymentProvider(widget.classId)).error;
      messenger.showSnackBar(
        SnackBar(content: Text(error ?? 'Gagal membuat QRIS Iuran.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _QrisPaymentSheet(
        classId: widget.classId,
        payment: widget.payment,
        qris: qris,
      ),
    );
  }
}

class _QrisPaymentSheet extends ConsumerStatefulWidget {
  final int classId;
  final PaymentModel payment;
  final PaymentQrisModel qris;

  const _QrisPaymentSheet({
    required this.classId,
    required this.payment,
    required this.qris,
  });

  @override
  ConsumerState<_QrisPaymentSheet> createState() => _QrisPaymentSheetState();
}

class _QrisPaymentSheetState extends ConsumerState<_QrisPaymentSheet>
    with SingleTickerProviderStateMixin {
  Timer? _pollTimer;
  Timer? _countdownTimer;
  bool _checking = false;
  bool _paid = false;
  bool _countdownReady = false;
  int _remainingSeconds = -1;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _initCountdown();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
    Future.microtask(_checkStatus);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _initCountdown() {
    if (widget.qris.expiredAt == null) return;
    _updateRemaining();
    _countdownReady = true;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final diff = widget.qris.expiredAt!.difference(DateTime.now());
    _remainingSeconds = diff.isNegative ? 0 : diff.inSeconds;
    if (_remainingSeconds == 0) _countdownTimer?.cancel();
    if (mounted) setState(() {});
  }

  bool get _isExpired => _countdownReady && _remainingSeconds == 0;

  String get _countdownText {
    if (!_countdownReady) return '--:--';
    if (_isExpired) return 'Kedaluwarsa';
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _checkStatus() async {
    if (_checking || !mounted || _paid) return;
    setState(() => _checking = true);
    final paid = await ref
        .read(paymentProvider(widget.classId).notifier)
        .checkPaymentQrisStatus(widget.payment.id);

    if (!mounted) return;
    setState(() => _checking = false);

    if (!paid) return;
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseCtrl.stop();
    setState(() => _paid = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pembayaran berhasil. Iuran lunas.'),
        backgroundColor: AppColors.statusGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPaymentUrl() async {
    final url = widget.qris.paymentUrl;
    final messenger = ScaffoldMessenger.of(context);
    final uri = url == null ? null : Uri.tryParse(url);

    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka halaman pembayaran')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final qris = widget.qris;
    final expired = _isExpired;
    final showQr = qris.qrString != null && qris.qrString!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.qr_code_2, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bayar Iuran Minggu ke-${widget.payment.paymentWeek}',
                  style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                ),
              ),
              _StatusChip(isPaid: false),
            ],
          ),
          const SizedBox(height: 14),

          // ── Amount ───────────────────────────────────────────
          Text(
            widget.payment.formattedAmount,
            style: AppTextStyles.h2.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // ── QR / Success / Expired / Fallback ────────────────
          if (_paid)
            _buildSuccess()
          else if (showQr && !expired)
            _buildQrCode(qris.qrString!)
          else if (expired)
            _buildExpired()
          else
            _buildFallback(qris),

          const SizedBox(height: 16),

          // ── Payment URL ──────────────────────────────────────
          if (qris.paymentUrl != null && !expired)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openPaymentUrl,
                icon: const Icon(Icons.open_in_new, size: 17),
                label: const Text('Buka Halaman Pembayaran'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── Countdown ────────────────────────────────────────
          if (widget.qris.expiredAt != null && _countdownReady) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: expired
                    ? AppColors.statusRedBg
                    : AppColors.primaryOverlay,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    expired ? Icons.timer_off : Icons.timer_outlined,
                    size: 16,
                    color: expired ? AppColors.statusRed : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expired
                          ? 'Waktu pembayaran habis'
                          : 'Sisa waktu $_countdownText',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: expired ? AppColors.statusRed : AppColors.primary,
                      ),
                    ),
                  ),
                  if (!expired)
                    Text(
                      _countdownText,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Polling status bar ───────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: _checking
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Icon(
                          _paid ? Icons.check_circle : Icons.sync,
                          size: 16,
                          color: _paid ? AppColors.statusGreen : AppColors.textMuted,
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _paid
                        ? 'Pembayaran terdeteksi'
                        : expired
                            ? 'Pembayaran tidak terdeteksi'
                            : 'Menunggu pembayaran…',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.5,
                      color: _paid ? AppColors.statusGreen : AppColors.textMuted,
                      fontWeight: _paid ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (!expired && !_paid)
                  TextButton(
                    onPressed: _checking ? null : _checkStatus,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cek', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  // ── QR Section builders ─────────────────────────────────────

  Widget _buildSuccess() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 - _pulseCtrl.value * 0.05,
          child: child,
        );
      },
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.statusGreenBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.statusGreen),
            SizedBox(height: 8),
            Text(
              'PEMBAYARAN\nBERHASIL',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.statusGreen,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCode(String qrData) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(8 + _pulseCtrl.value * 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary
                  .withValues(alpha: 0.3 + _pulseCtrl.value * 0.2),
              width: 2,
            ),
          ),
          child: child,
        );
      },
      child: QrImageView(
        data: qrData,
        version: QrVersions.auto,
        size: 200,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: Color(0xFF1A3A2A),
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: Color(0xFF1A3A2A),
        ),
      ),
    );
  }

  Widget _buildExpired() {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.statusRedBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.timer_off_outlined, size: 56, color: AppColors.statusRed),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'QRIS telah kedaluwarsa',
          style: AppTextStyles.caption.copyWith(
            fontSize: 11,
            color: AppColors.statusRed,
          ),
        ),
      ],
    );
  }

  Widget _buildFallback(PaymentQrisModel qris) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.primaryOverlay,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payments_outlined, size: 48, color: AppColors.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 8),
          Text(
            'Bayar melalui tautan\ndi bawah ini',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
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
                onTap: () => context.push('/iuran/tambah?classId=$classId'),
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
