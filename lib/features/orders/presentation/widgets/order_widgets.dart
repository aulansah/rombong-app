import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/order.dart';

extension OrderStatusUi on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Menunggu pembayaran',
        OrderStatus.paid => 'Dibayar',
        OrderStatus.processing => 'Diproses',
        OrderStatus.shipped => 'Dikirim',
        OrderStatus.completed => 'Selesai',
        OrderStatus.cancelled => 'Dibatalkan',
        OrderStatus.unknown => 'Status lain',
      };

  (Color background, Color foreground) get colors => switch (this) {
        OrderStatus.pending => (AppColors.warningContainer, AppColors.warning),
        OrderStatus.cancelled => (AppColors.errorContainer, AppColors.error),
        OrderStatus.completed => (AppColors.successContainer, AppColors.success),
        OrderStatus.unknown => (AppColors.surfaceVariant, AppColors.textMuted),
        _ => (AppColors.primaryContainer, AppColors.onPrimaryContainer),
      };
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = status.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
      child: Text(status.label, style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

/// PENDING → PAID → PROCESSING → SHIPPED → COMPLETED. A cancelled order
/// shows a single red step instead.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.status});
  final OrderStatus status;

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.paid,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.completed,
  ];
  static const _short = ['Dibuat', 'Dibayar', 'Diproses', 'Dikirim', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled || status == OrderStatus.unknown) {
      return Row(
        children: [
          Icon(status == OrderStatus.cancelled ? Icons.cancel : Icons.help_outline,
              color: status == OrderStatus.cancelled ? AppColors.error : AppColors.textMuted, size: 20),
          const SizedBox(width: AppSizes.space8),
          Expanded(
            child: Text(
              status == OrderStatus.cancelled ? 'Pesanan dibatalkan. Stok sudah dikembalikan.' : status.label,
              style: AppTextStyles.body,
            ),
          ),
        ],
      );
    }

    final reached = _steps.indexOf(status);
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Icon(
                  i <= reached ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: i <= reached ? AppColors.primary : AppColors.border,
                ),
                const SizedBox(height: AppSizes.space4),
                Text(
                  _short[i],
                  style: AppTextStyles.caption.copyWith(color: i <= reached ? AppColors.text : AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
