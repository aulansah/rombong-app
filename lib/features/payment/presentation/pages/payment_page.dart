import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../catalog/presentation/widgets/catalog_widgets.dart';
import '../../domain/entities/payment.dart';
import '../controllers/payment_controller.dart';

class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the Midtrans page: read the new status right away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final payment = ref.read(paymentControllerProvider(widget.orderId)).value;
    if (payment != null && payment.usesGateway && payment.status == PaymentStatus.pending && !_busy) {
      _run((c) => c.checkStatus());
    }
  }

  Future<void> _openGateway(String url) async {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Halaman pembayaran tidak bisa dibuka')));
    }
  }

  Future<void> _run(Future<Failure?> Function(PaymentController c) action) async {
    setState(() => _busy = true);
    final failure = await action(ref.read(paymentControllerProvider(widget.orderId).notifier));
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = paymentControllerProvider(widget.orderId);
    final payment = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: switch (payment) {
        AsyncData(:final value) => switch (value.status) {
            PaymentStatus.success => _Result(
                icon: Icons.check_circle,
                color: AppColors.success,
                title: 'Pembayaran berhasil',
                message: value.paidAt == null ? value.reference : 'Dibayar ${formatDateTime(value.paidAt!)}',
                actionLabel: 'Lihat pesanan',
                onAction: () => context.pop(),
              ),
            PaymentStatus.failed || PaymentStatus.expired => _Result(
                icon: Icons.cancel,
                color: AppColors.error,
                title: value.status == PaymentStatus.failed ? 'Pembayaran gagal' : 'Waktu pembayaran habis',
                message: 'Pesanan masih menunggu pembayaran. Kamu bisa mencoba lagi.',
                actionLabel: 'Coba bayar lagi',
                onAction: () => ref.read(provider.notifier).retry(),
              ),
            _ => _Pending(
                payment: value,
                busy: _busy,
                onPay: () => _run((c) => c.confirm()),
                onDecline: () => _run((c) => c.decline()),
                onOpenGateway: () => _openGateway(value.redirectUrl!),
                onCheck: () => _run((c) => c.checkStatus()),
                onExpired: () => ref.read(provider.notifier).retry(),
              ),
          },
        AsyncError(:final error) => StateView.error(
            error,
            // Safe to retry: the stored Idempotency-Key returns the same payment.
            onRetry: () => ref.invalidate(provider),
          ),
        _ => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Menyiapkan pembayaran…')],
            ),
          ),
      },
    );
  }
}

class _Pending extends StatelessWidget {
  const _Pending({
    required this.payment,
    required this.busy,
    required this.onPay,
    required this.onDecline,
    required this.onOpenGateway,
    required this.onCheck,
    required this.onExpired,
  });

  final Payment payment;
  final bool busy;
  final VoidCallback onPay;
  final VoidCallback onDecline;
  final VoidCallback onOpenGateway;
  final VoidCallback onCheck;
  final VoidCallback onExpired;

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.caption.copyWith(color: AppColors.textMuted);
    return ListView(
      padding: const EdgeInsets.all(AppSizes.space24),
      children: [
        Text('Total pembayaran', style: muted, textAlign: TextAlign.center),
        const SizedBox(height: AppSizes.space4),
        Text(formatRupiah(payment.amount), style: AppTextStyles.headline, textAlign: TextAlign.center),
        const SizedBox(height: AppSizes.space8),
        Center(child: _Countdown(key: ValueKey(payment.id), expiresAt: payment.expiresAt, onExpired: onExpired)),
        const SizedBox(height: AppSizes.space24),
        Container(
          padding: const EdgeInsets.all(AppSizes.space16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor referensi', style: muted),
                    const SizedBox(height: AppSizes.space4),
                    Text(payment.reference, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Salin',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payment.reference));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(const SnackBar(content: Text('Nomor referensi disalin')));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.space16),
        Container(
          padding: const EdgeInsets.all(AppSizes.space12),
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppSizes.radius12)),
          child: Text(
            payment.usesGateway
                ? 'Pembayaran diproses oleh Midtrans. Pilih metode (QRIS, transfer bank, e-wallet) di halaman '
                    'Midtrans, lalu kembali ke aplikasi. Status diperbarui otomatis.'
                : 'Ini simulasi payment gateway. Tombol di bawah meniru hasil dari bank: berhasil atau ditolak. '
                    'Menutup layar ini aman, pembayaran yang sama akan dilanjutkan.',
            style: muted,
          ),
        ),
        const SizedBox(height: AppSizes.space24),
        if (payment.usesGateway) ...[
          PrimaryButton(label: 'Bayar di Midtrans', loading: false, onPressed: busy ? null : onOpenGateway),
          const SizedBox(height: AppSizes.space8),
          TextButton(
            onPressed: busy ? null : onCheck,
            child: const Text('Saya sudah bayar, cek status'),
          ),
        ] else ...[
          PrimaryButton(label: 'Bayar sekarang', loading: busy, onPressed: onPay),
          const SizedBox(height: AppSizes.space8),
          TextButton(
            onPressed: busy ? null : onDecline,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Simulasikan pembayaran ditolak'),
          ),
        ],
      ],
    );
  }
}

/// "Bayar dalam 14:59". Calls [onExpired] once when time is up.
class _Countdown extends StatefulWidget {
  const _Countdown({super.key, required this.expiresAt, required this.onExpired});
  final DateTime expiresAt;
  final VoidCallback onExpired;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _left = _remaining();
    if (_left == Duration.zero) {
      _expire();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  Duration _remaining() {
    final left = widget.expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    setState(() => _left = _remaining());
    if (_left == Duration.zero) _expire();
  }

  void _expire() {
    _timer?.cancel();
    // Never change providers while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onExpired();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _left.inMinutes.toString().padLeft(2, '0');
    final s = (_left.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.warningContainer, borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
      child: Text('Bayar dalam $m:$s', style: AppTextStyles.label.copyWith(color: AppColors.warning)),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Icon(icon, size: 72, color: color),
            ),
            const SizedBox(height: AppSizes.space16),
            Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.space4),
            Text(message, style: AppTextStyles.body.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.space24),
            PrimaryButton(label: actionLabel, loading: false, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
