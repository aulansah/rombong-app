import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../domain/entities/catalog_entities.dart';
import '../controllers/catalog_queries.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../widgets/catalog_widgets.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail produk'), actions: const [CartIconButton()]),
      body: switch (product) {
        AsyncData(:final value) => _DetailBody(product: value),
        AsyncError(:final error) => StateView.error(error, onRetry: () => ref.invalidate(productDetailProvider(productId))),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: switch (product) {
        AsyncData(:final value) => _AddToCartBar(product: value),
        _ => null,
      },
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryName = ref
        .watch(categoriesProvider)
        .value
        ?.where((c) => c.id == product.categoryId)
        .firstOrNull
        ?.name;

    return ListView(
      children: [
        ProductImage(soldOut: !product.inStock, height: 280, iconSize: 72),
        Padding(
          padding: const EdgeInsets.all(AppSizes.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (categoryName != null) ...[
                Text(categoryName.toUpperCase(), style: AppTextStyles.label.copyWith(color: AppColors.primary, letterSpacing: 0.6)),
                const SizedBox(height: AppSizes.space8),
              ],
              Text(product.name, style: AppTextStyles.title),
              const SizedBox(height: AppSizes.space8),
              Text(formatRupiah(product.price), style: AppTextStyles.priceLarge),
              const SizedBox(height: AppSizes.space8),
              StockBadge(stock: product.stock),
              const SizedBox(height: AppSizes.space24),
              const Text('Deskripsi', style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSizes.space8),
              Text(
                product.description.isEmpty ? 'Belum ada deskripsi.' : product.description,
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddToCartBar extends ConsumerStatefulWidget {
  const _AddToCartBar({required this.product});
  final Product product;

  @override
  ConsumerState<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends ConsumerState<_AddToCartBar> {
  int _qty = 1;
  bool _adding = false;

  Future<void> _add() async {
    setState(() => _adding = true);
    final failure = await ref.read(cartControllerProvider.notifier).add(widget.product.id, _qty);
    if (!mounted) return;
    setState(() => _adding = false);

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (failure != null) {
      // e.g. "Only 3 unit(s) of this product are available" when the cart
      // already holds some of this product.
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text('$_qty × ${widget.product.name} masuk keranjang'),
      action: SnackBarAction(label: 'Lihat', onPressed: () => context.push('/cart')),
    ));
    setState(() => _qty = 1);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            QuantityStepper(
              value: _qty,
              max: p.stock < 1 ? 1 : p.stock,
              onChanged: p.inStock && !_adding ? (v) => setState(() => _qty = v) : null,
            ),
            const SizedBox(width: AppSizes.space12),
            Expanded(
              child: PrimaryButton(
                label: p.inStock ? 'Tambah ke keranjang' : 'Stok habis',
                loading: _adding,
                onPressed: p.inStock ? _add : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
