import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../catalog/presentation/widgets/catalog_widgets.dart';
import '../controllers/order_controllers.dart';

/// Review the cart and place the order. Prices shown are the current ones;
/// the backend snapshots them into the order.
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  Future<void> _place(BuildContext context, WidgetRef ref) async {
    final order = await ref.read(checkoutControllerProvider.notifier).placeOrder();
    if (order == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Back from the order goes to the catalog, not to an empty cart.
    context.go('/home');
    context.push('/orders/${order.id}');
    messenger.showSnackBar(SnackBar(content: Text('Pesanan ${order.orderNumber} dibuat')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final checkout = ref.watch(checkoutControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: switch (cart) {
        AsyncValue(:final value?) when value.isEmpty => StateView(
            icon: Icons.shopping_cart_outlined,
            title: 'Keranjang kosong',
            message: 'Tambahkan produk dulu sebelum checkout.',
            actionLabel: 'Lihat katalog',
            onAction: () => context.go('/home'),
          ),
        AsyncValue(:final value?) => _Review(cart: value, error: checkout.error),
        AsyncError(:final error) => StateView.error(error, onRetry: () => ref.invalidate(cartControllerProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: switch (cart.value) {
        final value? when !value.isEmpty => SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PrimaryButton(
                label: 'Buat pesanan · ${formatRupiah(value.totalAmount)}',
                loading: checkout.isLoading,
                onPressed: value.hasUnavailableItems || cart.isLoading ? null : () => _place(context, ref),
              ),
            ),
          ),
        _ => null,
      },
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({required this.cart, required this.error});
  final Cart cart;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.space16),
      children: [
        if (error != null) ...[ErrorBanner.fromError(error!), const SizedBox(height: AppSizes.space12)],
        if (cart.hasUnavailableItems)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Stok beberapa produk berubah. Sesuaikan keranjang dulu.',
                    style: AppTextStyles.body.copyWith(color: AppColors.error),
                  ),
                ),
                TextButton(onPressed: () => context.pop(), child: const Text('Ke keranjang')),
              ],
            ),
          ),
        const Text('Ringkasan pesanan', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSizes.space8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final item in cart.items)
                ListTile(
                  title: Text(item.productName, style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    item.available ? '${item.quantity} × ${formatRupiah(item.unitPrice)}' : 'Stok tidak mencukupi',
                    style: AppTextStyles.caption.copyWith(color: item.available ? AppColors.textMuted : AppColors.error),
                  ),
                  trailing: Text(formatRupiah(item.subtotal), style: AppTextStyles.bodyMedium),
                ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(AppSizes.space16),
                child: Row(
                  children: [
                    Text('Total (${cart.totalItems} barang)', style: AppTextStyles.body),
                    const Spacer(),
                    Text(formatRupiah(cart.totalAmount), style: AppTextStyles.priceLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.space16),
        Container(
          padding: const EdgeInsets.all(AppSizes.space12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSizes.radius12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
              const SizedBox(width: AppSizes.space8),
              Expanded(
                child: Text(
                  'Harga dan stok dikunci saat pesanan dibuat. Kalau batal sebelum bayar, stok dikembalikan.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
