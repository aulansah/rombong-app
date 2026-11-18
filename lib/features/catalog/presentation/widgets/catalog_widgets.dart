import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../domain/entities/catalog_entities.dart';

/// Figma component "ProductCard" (variants: In stock / Sold out).
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soldOut = !product.inStock;
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductImage(soldOut: soldOut, height: 120, iconSize: 40),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: AppTextStyles.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSizes.space4),
                  Text(formatRupiah(product.price), style: AppTextStyles.price),
                  const SizedBox(height: AppSizes.space4),
                  StockBadge(stock: product.stock),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The backend has no product photos yet, so the card shows a colored tile
/// with an icon (the "Image" layer of the Figma component).
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.soldOut, required this.height, required this.iconSize});

  final bool soldOut;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: soldOut ? AppColors.surfaceVariant : AppColors.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.shopping_bag_outlined,
        size: iconSize,
        color: soldOut ? AppColors.textMuted : AppColors.onPrimaryContainer,
      ),
    );
  }
}

class StockBadge extends StatelessWidget {
  const StockBadge({super.key, required this.stock});
  final int stock;

  @override
  Widget build(BuildContext context) {
    final available = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: available ? AppColors.successContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(
        available ? 'Stok $stock' : 'Stok habis',
        style: AppTextStyles.caption.copyWith(color: available ? AppColors.success : AppColors.error),
      ),
    );
  }
}

/// Figma component "CategoryChip" (Selected = true / false).
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.primary : AppColors.border)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label, style: AppTextStyles.label.copyWith(color: selected ? AppColors.onPrimary : AppColors.text)),
        ),
      ),
    );
  }
}

/// Full-area message for empty and error states.
class StateView extends StatelessWidget {
  const StateView({super.key, required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});

  factory StateView.error(Object error, {required VoidCallback onRetry}) {
    final offline = error is NetworkFailure;
    return StateView(
      icon: offline ? Icons.cloud_off_outlined : Icons.error_outline,
      title: offline ? 'Tidak ada koneksi' : 'Terjadi kesalahan',
      message: error is Failure ? error.message : 'Silakan coba lagi.',
      actionLabel: 'Coba lagi',
      onAction: onRetry,
    );
  }

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSizes.space16),
            Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSizes.space4),
            Text(message, style: AppTextStyles.body.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSizes.space16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
