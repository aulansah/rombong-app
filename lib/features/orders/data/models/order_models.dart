import '../../domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.status,
    required super.totalAmount,
    required super.items,
    required super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        orderNumber: json['order_number'] as String,
        status: OrderStatus.fromApi(json['status'] as String?),
        totalAmount: (json['total_amount'] as num).toInt(),
        items: ((json['items'] as List<dynamic>?) ?? const [])
            .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    required super.unitPrice,
    required super.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'] as String,
        productId: json['product_id'] as String?,
        productName: json['product_name'] as String,
        unitPrice: (json['unit_price'] as num).toInt(),
        quantity: (json['quantity'] as num).toInt(),
      );
}
