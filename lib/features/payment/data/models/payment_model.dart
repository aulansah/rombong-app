import '../../domain/entities/payment.dart';

class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.orderId,
    required super.reference,
    required super.amount,
    required super.status,
    required super.expiresAt,
    super.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        orderId: json['order_id'] as String,
        reference: json['reference'] as String,
        amount: (json['amount'] as num).toInt(),
        status: PaymentStatus.fromApi(json['status'] as String?),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        paidAt: json['paid_at'] == null ? null : DateTime.parse(json['paid_at'] as String),
      );
}
