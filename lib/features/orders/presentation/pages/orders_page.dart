import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/date_format.dart';
import '../../../catalog/presentation/widgets/catalog_widgets.dart';
import '../../domain/entities/order.dart';
import '../controllers/order_controllers.dart';
import '../widgets/order_widgets.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Pesanan saya')), body: const OrderListView());
  }
}

/// Paginated order list. Customers see their own orders; for an admin the
/// same endpoint returns every order, so the admin screen reuses this view.
class OrderListView extends ConsumerStatefulWidget {
  const OrderListView({super.key});

  @override
  ConsumerState<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends ConsumerState<OrderListView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) ref.read(orderListControllerProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(orderListControllerProvider);

    return switch (orders) {
        AsyncValue(:final value?) when value.items.isEmpty => StateView(
            icon: Icons.receipt_long_outlined,
            title: 'Belum ada pesanan',
            message: 'Pesanan yang kamu buat akan muncul di sini.',
            actionLabel: 'Mulai belanja',
            onAction: () => context.go('/home'),
          ),
        AsyncValue(:final value?) => RefreshIndicator(
            onRefresh: () => ref.refresh(orderListControllerProvider.future),
            child: ListView.separated(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.space16),
              itemCount: value.items.length + 1,
              separatorBuilder: (context, i) => const SizedBox(height: AppSizes.space12),
              itemBuilder: (context, i) {
                if (i == value.items.length) return _Footer(state: value);
                final order = value.items[i];
                return _OrderTile(order: order, onTap: () => context.push('/orders/${order.id}'));
              },
            ),
          ),
        AsyncError(:final error) => StateView.error(error, onRetry: () => ref.invalidate(orderListControllerProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      };
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});
  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final first = order.items.isEmpty ? '' : order.items.first.productName;
    final more = order.items.length > 1 ? ' +${order.items.length - 1} lainnya' : '';
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radius12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(order.orderNumber, style: AppTextStyles.titleSmall)),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: AppSizes.space4),
              Text(formatDateTime(order.createdAt), style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: AppSizes.space12),
              Text('$first$more', style: AppTextStyles.body, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSizes.space8),
              Row(
                children: [
                  Text('${order.totalItems} barang', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                  const Spacer(),
                  Text(formatRupiah(order.totalAmount), style: AppTextStyles.price),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.state});
  final OrderListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = AppTextStyles.caption.copyWith(color: AppColors.textMuted);
    final Widget child;
    if (state.isLoadingMore) {
      child = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (state.loadMoreError != null) {
      child = TextButton(
        onPressed: () => ref.read(orderListControllerProvider.notifier).loadMore(),
        child: const Text('Gagal memuat. Coba lagi'),
      );
    } else if (!state.hasMore) {
      child = Text('${state.totalItems} pesanan', style: muted);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.symmetric(vertical: AppSizes.space16), child: Center(child: child));
  }
}
