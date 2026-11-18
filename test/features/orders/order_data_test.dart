import 'package:ecommerce_app/core/utils/date_format.dart';
import 'package:ecommerce_app/features/orders/data/models/order_models.dart';
import 'package:ecommerce_app/features/orders/domain/entities/order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OrderModel parses the backend order, including a deleted product', () {
    final order = OrderModel.fromJson({
      'id': 'o1',
      'user_id': 'u1',
      'order_number': 'ORD-20261118-ABC123',
      'status': 'PENDING',
      'total_amount': 200000,
      'items': [
        {'id': 'i1', 'product_id': 'p1', 'product_name': 'Kopi', 'unit_price': 85000, 'quantity': 2, 'subtotal': 170000},
        {'id': 'i2', 'product_id': null, 'product_name': 'Teh (dihapus)', 'unit_price': 30000, 'quantity': 1, 'subtotal': 30000},
      ],
      'created_at': '2026-11-18T03:27:00Z',
      'updated_at': '2026-11-18T03:27:00Z',
    });

    expect(order.status, OrderStatus.pending);
    expect(order.status.canCancel, isTrue);
    expect(order.totalItems, 3);
    expect(order.items.last.productId, isNull);
    expect(order.createdAt, DateTime.utc(2026, 11, 18, 3, 27));
  });

  test('unknown statuses do not crash the app', () {
    expect(OrderStatus.fromApi('REFUNDED'), OrderStatus.unknown);
    expect(OrderStatus.fromApi(null), OrderStatus.unknown);
    expect(OrderStatus.fromApi('PAID').canCancel, isFalse);
  });

  test('formatDateTime', () {
    final local = DateTime(2026, 11, 8, 9, 5);
    expect(formatDateTime(local), '8 Nov 2026, 09:05');
  });
}
