enum PaymentProvider { stripe, payfast, mock }

enum PaymentStatus { pending, paid, succeeded, failed, refunded }

class PaymentModel {
  final String id;
  final String appointmentId;
  final double amount;
  final String currency;
  final PaymentProvider provider;
  final PaymentStatus status;
  final String? providerTxnId;
  final String? clientSecret;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.appointmentId,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    this.providerTxnId,
    this.clientSecret,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      appointmentId: json['appointmentId'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'PKR',
      provider: PaymentProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => PaymentProvider.mock,
      ),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      providerTxnId: json['providerTxnId'],
      clientSecret: json['clientSecret'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'appointmentId': appointmentId,
        'amount': amount,
        'currency': currency,
        'provider': provider.name,
        'status': status.name,
        'providerTxnId': providerTxnId,
        'clientSecret': clientSecret,
        'createdAt': createdAt.toIso8601String(),
      };
}
