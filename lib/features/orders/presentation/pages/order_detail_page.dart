import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../admin/admin_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../catalog/presentation/widgets/catalog_widgets.dart';
import '../../domain/entities/order.dart';
import '../controllers/order_controllers.dart';
import '../widgets/order_widgets.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _cancelling = false;
  bool _advancing = false;

  Future<void> _advance(Order order) async {
    setState(() => _advancing = true);
    final failure = await ref.read(adminActionsProvider).advanceOrder(order);
    if (!mounted) return;
    setState(() => _advancing = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure?.message ?? 'Status diperbarui')));
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text('Stok produk akan dikembalikan dan pesanan tidak bisa dibayar lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Batalkan')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling = true);
    final failure = await ref.read(orderDetailControllerProvider(widget.orderId).notifier).cancel();
    if (!mounted) return;
    setState(() => _cancelling = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure?.message ?? 'Pesanan dibatalkan')));
  }

  @override
  Widget build(BuildContext context) {
    final provider = orderDetailControllerProvider(widget.orderId);
    final order = ref.watch(provider);
    final isAdmin = ref.watch(authControllerProvider.select((a) => a.value?.isAdmin ?? false));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail pesanan')),
      body: switch (order) {
        AsyncValue(:final value?) => RefreshIndicator(
            onRefresh: () => ref.refresh(provider.future),
            child: _Body(order: value),
          ),
        AsyncError(:final error) => StateView.error(error, onRetry: () => ref.invalidate(provider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: switch (order.value) {
        // Admin: move a paid order through fulfilment.
        final value? when isAdmin && value.status.nextForAdmin != null => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: PrimaryButton(
                label: 'Ubah status ke "${value.status.nextForAdmin!.label}"',
                loading: _advancing,
                onPressed: () => _advance(value),
              ),
            ),
          ),
        final value? when value.status.canPay => SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius12)),
                    ),
                    onPressed: _cancelling ? null : _cancel,
                    child: _cancelling
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Batalkan'),
                  ),
                  const SizedBox(width: AppSizes.space12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _cancelling ? null : () => context.push('/orders/${widget.orderId}/pay'),
                      child: Text('Bayar ${formatRupiah(value.totalAmount)}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _ => null,
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final muted = AppTextStyles.caption.copyWith(color: AppColors.textMuted);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.space16),
      children: [
        Row(
          children: [
            Expanded(child: Text(order.orderNumber, style: AppTextStyles.title)),
            OrderStatusChip(status: order.status),
          ],
        ),
        const SizedBox(height: AppSizes.space4),
        Text(formatDateTime(order.createdAt), style: muted),
        const SizedBox(height: AppSizes.space24),
        OrderTimeline(status: order.status),
        const SizedBox(height: AppSizes.space24),
        const Text('Produk', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSizes.space8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final item in order.items)
                ListTile(
                  title: Text(item.productName, style: AppTextStyles.bodyMedium),
                  // Snapshot price: what the customer agreed to pay, even if
                  // the product price changed later.
                  subtitle: Text('${item.quantity} × ${formatRupiah(item.unitPrice)}', style: muted),
                  trailing: Text(formatRupiah(item.subtotal), style: AppTextStyles.bodyMedium),
                ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Row(
                  children: [
                    const Text('Total', style: AppTextStyles.body),
                    const Spacer(),
                    Text(formatRupiah(order.totalAmount), style: AppTextStyles.priceLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (order.status == OrderStatus.pending) ...[
          const SizedBox(height: AppSizes.space12),
          Text('Selesaikan pembayaran agar pesanan diproses.', style: muted),
        ],
      ],
    );
  }
}
