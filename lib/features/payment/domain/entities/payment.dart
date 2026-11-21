import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending,
  success,
  failed,
  expired,
  unknown;

  static PaymentStatus fromApi(String? value) => switch (value) {
        'PENDING' => pending,
        'SUCCESS' => success,
        'FAILED' => failed,
        'EXPIRED' => expired,
        _ => unknown,
      };

  /// FAILED and EXPIRED payments are final: paying again needs a new
  /// payment, and therefore a new Idempotency-Key.
  bool get isFinalFailure => this == failed || this == expired;
}

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.orderId,
    required this.reference,
    required this.amount,
    required this.status,
    required this.expiresAt,
    this.paidAt,
    this.provider = providerSimulated,
    this.redirectUrl,
  });

  static const providerSimulated = 'simulated';

  final String id;
  final String orderId;
  final String reference;
  final int amount;
  final PaymentStatus status;
  final DateTime expiresAt;
  final DateTime? paidAt;

  /// "simulated" or "midtrans".
  final String provider;

  /// Payment page of the gateway (Midtrans Snap). Null for simulated payments.
  final String? redirectUrl;

  /// True when the buyer pays on the gateway's page and the result arrives
  /// through the backend webhook, so the app only checks the status.
  bool get usesGateway => provider != providerSimulated && redirectUrl != null;

  bool isExpiredAt(DateTime now) => status == PaymentStatus.pending && !now.isBefore(expiresAt);

  @override
  List<Object?> get props => [id, orderId, reference, amount, status, expiresAt, paidAt, provider, redirectUrl];
}
