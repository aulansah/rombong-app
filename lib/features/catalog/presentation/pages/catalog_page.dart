import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../cart/presentation/widgets/cart_icon_button.dart';
import '../controllers/catalog_filter_controller.dart';
import '../controllers/catalog_queries.dart';
import '../controllers/product_list_controller.dart';
import '../widgets/catalog_widgets.dart';

/// Home screen: search, category filter and an infinitely scrolling grid.
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Infinite scroll: ask for the next page when the user is within 400px of
  /// the bottom. loadMore() itself ignores duplicate calls.
  void _maybeLoadMore() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 400) {
      ref.read(productListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListControllerProvider);

    // A short first page may not fill the screen, so no scroll event would
    // ever fire. Check once after layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeLoadMore();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog'),
        actions: [
          if (ref.watch(authControllerProvider.select((a) => a.value?.isAdmin ?? false)))
            IconButton(
              tooltip: 'Admin',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            tooltip: 'Pesanan saya',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push('/orders'),
          ),
          const CartIconButton(),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(productListControllerProvider.future),
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _SearchField(controller: _search)),
            const SliverToBoxAdapter(child: _CategoryChips()),
            ..._content(products),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(AsyncValue<ProductListState> products) {
    if (products.hasError && !products.isLoading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateView.error(products.error!, onRetry: () => ref.invalidate(productListControllerProvider)),
        ),
      ];
    }

    final data = products.value;
    if (data == null) {
      return [const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))];
    }

    // A reload with old data still shown (filter changed / pull to refresh).
    final reloading = products.isLoading
        ? const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2))
        : null;

    if (data.items.isEmpty) {
      return [
        if (reloading != null) reloading,
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateView(
            icon: Icons.search_off,
            title: 'Produk tidak ditemukan',
            message: data.filter.search.isEmpty
                ? 'Belum ada produk di kategori ini.'
                : 'Tidak ada produk untuk "${data.filter.search}".',
          ),
        ),
      ];
    }

    return [
      if (reloading != null) reloading,
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSizes.space16,
            crossAxisSpacing: AppSizes.space16,
            mainAxisExtent: 236,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final product = data.items[i];
              return ProductCard(product: product, onTap: () => context.push('/products/${product.id}'));
            },
            childCount: data.items.length,
          ),
        ),
      ),
      SliverToBoxAdapter(child: _ListFooter(state: data)),
    ];
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.read(catalogFilterProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ValueListenableBuilder(
        valueListenable: controller,
        builder: (context, value, _) => TextField(
          controller: controller,
          onChanged: filter.setSearch,
          textInputAction: TextInputAction.search,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: 'Cari produk',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      controller.clear();
                      filter.setSearch('');
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(catalogFilterProvider.select((f) => f.categoryId));
    final notifier = ref.read(catalogFilterProvider.notifier);

    // Categories are optional: if they fail to load, the catalog still works
    // without the filter row.
    final items = categories.value;
    if (items == null) {
      return const SizedBox(height: 56, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))));
    }

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        itemCount: items.length + 1,
        separatorBuilder: (context, i) => const SizedBox(width: AppSizes.space8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return CategoryChip(label: 'Semua', selected: selected == null, onTap: () => notifier.selectCategory(null));
          }
          final c = items[i - 1];
          return CategoryChip(label: c.name, selected: selected == c.id, onTap: () => notifier.selectCategory(c.id));
        },
      ),
    );
  }
}

class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.state});
  final ProductListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = AppTextStyles.caption.copyWith(color: AppColors.textMuted);
    Widget child;
    if (state.isLoadingMore) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text('Memuat produk lainnya…', style: muted),
        ],
      );
    } else if (state.loadMoreError != null) {
      child = Column(
        children: [
          Text(state.loadMoreError!.message, style: muted, textAlign: TextAlign.center),
          TextButton(
            onPressed: () => ref.read(productListControllerProvider.notifier).loadMore(),
            child: const Text('Coba lagi'),
          ),
        ],
      );
    } else if (!state.hasMore) {
      child = Text('Semua produk sudah ditampilkan (${state.totalItems})', style: muted);
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), child: Center(child: child));
  }
}
