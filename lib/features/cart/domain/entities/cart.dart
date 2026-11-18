import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.unitPrice,
    required this.quantity,
    required this.available,
  });

  final String id;
  final String productId;
  final String productName;
  final String productSlug;

  /// Current product price. The cart stores no price; the order snapshots it
  /// at checkout.
  final int unitPrice;
  final int quantity;

  /// False when the product was removed or has less stock than [quantity].
  final bool available;

  int get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        productId: productId,
        productName: productName,
        productSlug: productSlug,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        available: available,
      );

  @override
  List<Object?> get props => [id, productId, productName, productSlug, unitPrice, quantity, available];
}

class Cart extends Equatable {
  const Cart({required this.id, required this.items});

  static const empty = Cart(id: '', items: []);

  final String id;
  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);
  int get totalAmount => items.fold(0, (sum, i) => sum + i.subtotal);

  /// Checkout would be rejected by the backend while this is true.
  bool get hasUnavailableItems => items.any((i) => !i.available);

  /// Local edits used for optimistic updates. The server response replaces
  /// the result once it arrives.
  Cart withQuantity(String itemId, int quantity) =>
      Cart(id: id, items: [for (final i in items) i.id == itemId ? i.copyWith(quantity: quantity) : i]);

  Cart without(String itemId) => Cart(id: id, items: items.where((i) => i.id != itemId).toList());

  @override
  List<Object?> get props => [id, items];
}
