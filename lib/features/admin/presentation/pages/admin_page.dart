import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../catalog/presentation/controllers/catalog_filter_controller.dart';
import '../../../catalog/presentation/controllers/catalog_queries.dart';
import '../../../catalog/presentation/controllers/product_list_controller.dart';
import '../../../catalog/presentation/widgets/catalog_widgets.dart';
import '../../../orders/presentation/pages/orders_page.dart';
import '../../admin_providers.dart';

void showResult(BuildContext context, Failure? failure, String success) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(failure?.message ?? success)));
}

Future<bool> confirm(BuildContext context, {required String title, required String message, required String action}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Admin area: products, categories and every customer's orders.
/// Only reachable by admins (router redirect), and every call is checked by
/// the backend again.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          bottom: const TabBar(tabs: [Tab(text: 'Produk'), Tab(text: 'Kategori'), Tab(text: 'Pesanan')]),
        ),
        body: const TabBarView(children: [_ProductsTab(), _CategoriesTab(), OrderListView()]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Products
// ---------------------------------------------------------------------------

class _ProductsTab extends ConsumerStatefulWidget {
  const _ProductsTab();

  @override
  ConsumerState<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<_ProductsTab> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) ref.read(productListControllerProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _editStock(Product p) async {
    final controller = TextEditingController(text: '${p.stock}');
    final stock = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stok ${p.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Jumlah stok'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, int.tryParse(controller.text)), child: const Text('Simpan')),
        ],
      ),
    );
    controller.dispose();
    if (stock == null || !mounted) return;
    final failure = await ref.read(adminActionsProvider).updateStock(p.id, stock);
    if (mounted) showResult(context, failure, 'Stok diperbarui');
  }

  Future<void> _delete(Product p) async {
    final ok = await confirm(
      context,
      title: 'Hapus produk?',
      message: '${p.name} akan dihapus dari katalog. Pesanan lama tetap menyimpan nama dan harganya.',
      action: 'Hapus',
    );
    if (!ok || !mounted) return;
    final failure = await ref.read(adminActionsProvider).deleteProduct(p.id);
    if (mounted) showResult(context, failure, 'Produk dihapus');
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListControllerProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Produk'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: ref.read(catalogFilterProvider.notifier).setSearch,
              decoration: const InputDecoration(hintText: 'Cari produk', prefixIcon: Icon(Icons.search, size: 20)),
            ),
          ),
          Expanded(
            child: switch (products) {
              AsyncValue(:final value?) => RefreshIndicator(
                  onRefresh: () => ref.refresh(productListControllerProvider.future),
                  child: ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: value.items.length,
                    itemBuilder: (context, i) {
                      final p = value.items[i];
                      return ListTile(
                        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${formatRupiah(p.price)} · stok ${p.stock}'),
                        onTap: () => context.push('/admin/products/${p.id}'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) => switch (action) {
                            'stock' => _editStock(p),
                            'delete' => _delete(p),
                            _ => null,
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'stock', child: Text('Ubah stok')),
                            PopupMenuItem(value: 'delete', child: Text('Hapus')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              AsyncError(:final error) =>
                StateView.error(error, onRetry: () => ref.invalidate(productListControllerProvider)),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Categories
// ---------------------------------------------------------------------------

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  Future<void> _edit(BuildContext context, WidgetRef ref, {Category? category}) async {
    final controller = TextEditingController(text: category?.name ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Kategori baru' : 'Ubah kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama kategori'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Simpan')),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !context.mounted) return;
    if (name.length < 2) return showResult(context, const UnexpectedFailure('Nama minimal 2 karakter'), '');
    final failure = await ref.read(adminActionsProvider).saveCategory(name, id: category?.id);
    if (context.mounted) showResult(context, failure, 'Kategori disimpan');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category c) async {
    final ok = await confirm(context, title: 'Hapus kategori?', message: c.name, action: 'Hapus');
    if (!ok || !context.mounted) return;
    // The backend refuses (409) while products still use the category.
    final failure = await ref.read(adminActionsProvider).deleteCategory(c.id);
    if (context.mounted) showResult(context, failure, 'Kategori dihapus');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Kategori'),
      ),
      body: switch (categories) {
        AsyncValue(:final value?) => ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final c in value)
                ListTile(
                  title: Text(c.name),
                  subtitle: Text(c.slug),
                  onTap: () => _edit(context, ref, category: c),
                  trailing: IconButton(
                    tooltip: 'Hapus',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, ref, c),
                  ),
                ),
            ],
          ),
        AsyncError(:final error) => StateView.error(error, onRetry: () => ref.invalidate(categoriesProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
