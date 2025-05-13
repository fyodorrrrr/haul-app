class PaymentMethod {
  final String type; // e.g., 'Credit Card', 'Cash on Delivery'
  final Map<String, dynamic>? details;

  PaymentMethod({
    required this.type,
    this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'details': details,
    };
  }
}