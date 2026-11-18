import '../../domain/entities/cart.dart';

/// JSON of GET /cart:
/// { id, items: [{ id, product_id, product_name, product_slug, unit_price,
///   quantity, subtotal, available }], total_items, total_amount }
///
/// Totals are recomputed by [Cart] from the items, so they always match what
/// is on screen, including during an optimistic update.
class CartModel extends Cart {
  const CartModel({required super.id, required super.items});

  factory CartModel.fromJson(Map<String, dynamic> json) => CartModel(
        id: json['id'] as String,
        items: ((json['items'] as List<dynamic>?) ?? const [])
            .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.productSlug,
    required super.unitPrice,
    required super.quantity,
    required super.available,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        // A product deleted by an admin comes back with an empty name.
        productName: (json['product_name'] as String?)?.isNotEmpty == true
            ? json['product_name'] as String
            : 'Produk tidak tersedia',
        productSlug: json['product_slug'] as String? ?? '',
        unitPrice: (json['unit_price'] as num).toInt(),
        quantity: (json['quantity'] as num).toInt(),
        available: json['available'] as bool? ?? false,
      );
}
