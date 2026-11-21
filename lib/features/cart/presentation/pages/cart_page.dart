import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../catalog/presentation/widgets/catalog_widgets.dart';
import '../../domain/entities/cart.dart';
import '../controllers/cart_controller.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  static void _report(BuildContext context, Failure? failure) {
    if (failure == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kosongkan keranjang?'),
        content: const Text('Semua produk akan dihapus dari keranjang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kosongkan')),
        ],
      ),
    );
    if (ok != true) return;
    final failure = await ref.read(cartControllerProvider.notifier).clear();
    if (context.mounted) _report(context, failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final hasItems = cart.value?.isEmpty == false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          if (hasItems)
            IconButton(
              tooltip: 'Kosongkan',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: switch (cart) {
        AsyncValue(:final value?) when value.isEmpty => StateView(
            icon: Icons.shopping_cart_outlined,
            title: 'Keranjang masih kosong',
            message: 'Yuk, cari produk yang kamu butuhkan.',
            actionLabel: 'Lihat katalog',
            onAction: () => context.go('/home'),
          ),
        AsyncValue(:final value?) => RefreshIndicator(
            onRefresh: () => ref.refresh(cartControllerProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                if (value.hasUnavailableItems) const _UnavailableBanner(),
                for (final item in value.items) ...[
                  _CartItemTile(
                    item: item,
                    onQuantity: (q) async {
                      final failure = await ref.read(cartControllerProvider.notifier).updateQuantity(item.id, q);
                      if (context.mounted) _report(context, failure);
                    },
                    onRemove: () async {
                      final failure = await ref.read(cartControllerProvider.notifier).remove(item.id);
                      if (context.mounted) _report(context, failure);
                    },
                  ),
                  const SizedBox(height: AppSizes.space12),
                ],
              ],
            ),
          ),
        AsyncError(:final error) => StateView.error(error, onRetry: () => ref.invalidate(cartControllerProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: switch (cart.value) {
        final value? when !value.isEmpty => _SummaryBar(cart: value),
        _ => null,
      },
    );
  }
}

class _UnavailableBanner extends StatelessWidget {
  const _UnavailableBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.space12),
      padding: const EdgeInsets.all(AppSizes.space12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radius12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: AppSizes.space8),
          Expanded(
            child: Text(
              'Ada produk yang stoknya kurang atau sudah tidak dijual. Kurangi jumlahnya atau hapus sebelum checkout.',
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.onQuantity, required this.onRemove});

  final CartItem item;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.space24),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(AppSizes.radius12)),
        child: const Icon(Icons.delete_outline, color: AppColors.onPrimary),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.space12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radius12),
          border: Border.all(color: item.available ? AppColors.border : AppColors.error),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.push('/products/${item.productId}'),
              borderRadius: BorderRadius.circular(AppSizes.radius8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radius8),
                child: SizedBox(
                  width: 64,
                  child: ProductImage(soldOut: !item.available, height: 64, iconSize: 28),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: AppTextStyles.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSizes.space4),
                  Text(formatRupiah(item.unitPrice), style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                  if (!item.available) ...[
                    const SizedBox(height: AppSizes.space4),
                    Text('Stok tidak mencukupi', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
                  ],
                  const SizedBox(height: AppSizes.space8),
                  Row(
                    children: [
                      QuantityStepper(compact: true, value: item.quantity, onChanged: onQuantity),
                      const Spacer(),
                      Text(formatRupiah(item.subtotal), style: AppTextStyles.price),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.cart});
  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Total (${cart.totalItems} barang)', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                const Spacer(),
                Text(formatRupiah(cart.totalAmount), style: AppTextStyles.priceLarge),
              ],
            ),
            const SizedBox(height: AppSizes.space12),
            PrimaryButton(
              label: 'Checkout',
              loading: false,
              onPressed: cart.hasUnavailableItems ? null : () => context.push('/checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
