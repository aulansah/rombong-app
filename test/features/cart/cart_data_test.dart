import 'package:ecommerce_app/features/cart/data/models/cart_models.dart';
import 'package:ecommerce_app/features/cart/domain/entities/cart.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CartModel parses the backend cart', () {
    final cart = CartModel.fromJson({
      'id': 'cart1',
      'items': [
        {
          'id': 'i1',
          'product_id': 'p1',
          'product_name': 'Kopi Arabika',
          'product_slug': 'kopi-arabika',
          'unit_price': 85000,
          'quantity': 2,
          'subtotal': 170000,
          'available': true,
        },
        {
          // product deleted by an admin
          'id': 'i2',
          'product_id': 'p2',
          'product_name': '',
          'product_slug': '',
          'unit_price': 0,
          'quantity': 1,
          'subtotal': 0,
          'available': false,
        },
      ],
      'total_items': 3,
      'total_amount': 170000,
    });

    expect(cart.items, hasLength(2));
    expect(cart.totalItems, 3);
    expect(cart.totalAmount, 170000);
    expect(cart.items.last.productName, 'Produk tidak tersedia');
    expect(cart.hasUnavailableItems, isTrue);
  });

  test('an empty cart from the backend has items: []', () {
    final cart = CartModel.fromJson({'id': 'cart1', 'items': [], 'total_items': 0, 'total_amount': 0});
    expect(cart.isEmpty, isTrue);
  });

  test('withQuantity / without edit one line and keep totals consistent', () {
    const cart = Cart(id: 'c', items: [
      CartItem(id: 'a', productId: 'pa', productName: 'A', productSlug: 'a', unitPrice: 1000, quantity: 1, available: true),
      CartItem(id: 'b', productId: 'pb', productName: 'B', productSlug: 'b', unitPrice: 500, quantity: 2, available: true),
    ]);

    expect(cart.withQuantity('a', 3).totalAmount, 4000);
    expect(cart.without('b').totalItems, 1);
    expect(cart.totalAmount, 2000, reason: 'original unchanged');
  });
}
