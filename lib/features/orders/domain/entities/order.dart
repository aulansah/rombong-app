import 'package:equatable/equatable.dart';

/// Order lifecycle, as defined by the backend.
enum OrderStatus {
  pending,
  paid,
  processing,
  shipped,
  completed,
  cancelled,

  /// A status this app version does not know yet. The app keeps working
  /// instead of crashing when the backend adds a new one.
  unknown;

  static OrderStatus fromApi(String? value) => switch (value) {
        'PENDING' => pending,
        'PAID' => paid,
        'PROCESSING' => processing,
        'SHIPPED' => shipped,
        'COMPLETED' => completed,
        'CANCELLED' => cancelled,
        _ => unknown,
      };

  /// Only PENDING orders can be cancelled by the customer (backend rule).
  bool get canCancel => this == pending;

  /// Only PENDING orders can be paid.
  bool get canPay => this == pending;

  /// Value sent to the backend.
  String get apiValue => name.toUpperCase();

  /// Next fulfilment step an admin can apply (PATCH /orders/:id/status).
  /// PAID → PROCESSING → SHIPPED → COMPLETED.
  OrderStatus? get nextForAdmin => switch (this) {
        paid => processing,
        processing => shipped,
        shipped => completed,
        _ => null,
      };
}

class OrderItem extends Equatable {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String id;

  /// Null when the product was deleted after the order; the name and price
  /// below are snapshots taken at checkout and stay valid.
  final String? productId;
  final String productName;
  final int unitPrice;
  final int quantity;

  int get subtotal => unitPrice * quantity;

  @override
  List<Object?> get props => [id, productId, productName, unitPrice, quantity];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;

  /// Total computed by the backend at checkout. Not recomputed here: later
  /// price changes must not change an existing order.
  final int totalAmount;
  final List<OrderItem> items;
  final DateTime createdAt;

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  @override
  List<Object?> get props => [id, orderNumber, status, totalAmount, items, createdAt];
}
