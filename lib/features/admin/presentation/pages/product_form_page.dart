import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../catalog/presentation/controllers/catalog_queries.dart';
import '../../../catalog/presentation/widgets/catalog_widgets.dart';
import '../../admin_providers.dart';
import '../../domain/entities/product_draft.dart';

/// Create (`productId == null`) or edit a product.
class ProductFormPage extends ConsumerWidget {
  const ProductFormPage({super.key, this.productId});
  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = productId == null ? 'Produk baru' : 'Ubah produk';
    if (productId == null) return _Form(title: title);

    final provider = productDetailProvider(productId!);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) => _Form(title: title, product: value),
      AsyncError(:final error) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: StateView.error(error, onRetry: () => ref.invalidate(provider)),
        ),
      _ => Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator())),
    };
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.title, this.product});
  final String title;
  final Product? product;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _description = TextEditingController(text: widget.product?.description);
  late final _price = TextEditingController(text: widget.product == null ? '' : '${widget.product!.price}');
  late final _stock = TextEditingController(text: widget.product == null ? '0' : '${widget.product!.stock}');
  late String? _categoryId = widget.product?.categoryId;
  bool _saving = false;
  Failure? _error;

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await ref.read(adminActionsProvider).saveProduct(
          ProductDraft(
            name: _name.text,
            description: _description.text,
            price: int.tryParse(_price.text) ?? 0,
            stock: int.tryParse(_stock.text) ?? -1,
            categoryId: _categoryId ?? '',
          ),
          id: widget.product?.id,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = failure;
    });
    if (failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk disimpan')));
      context.pop();
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const <Category>[];
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.space16),
          children: [
            if (_error != null) ...[ErrorBanner.fromError(_error!), const SizedBox(height: AppSizes.space16)],
            AppTextField(label: 'Nama', controller: _name, icon: Icons.inventory_2_outlined, validator: _required),
            const SizedBox(height: AppSizes.space16),
            AppTextField(label: 'Deskripsi', controller: _description, icon: Icons.notes),
            const SizedBox(height: AppSizes.space16),
            Row(
              children: [
                Expanded(
                  child: _NumberField(label: 'Harga (Rp)', controller: _price, formatters: digits, validator: _required),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(
                  child: _NumberField(label: 'Stok', controller: _stock, formatters: digits, validator: _required),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),
            Text('Kategori', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: categories.any((c) => c.id == _categoryId) ? _categoryId : null,
              items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => v == null ? 'Pilih kategori' : null,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined, size: 20)),
            ),
            const SizedBox(height: AppSizes.space24),
            PrimaryButton(label: 'Simpan', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.controller, required this.formatters, this.validator});
  final String label;
  final TextEditingController controller;
  final List<TextInputFormatter> formatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: formatters,
          validator: validator,
          style: AppTextStyles.body,
        ),
      ],
    );
  }
}
