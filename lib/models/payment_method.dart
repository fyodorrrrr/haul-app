class PaymentMethod {
  final String type;
  final String name;
  final Map<String, dynamic>? details;

  PaymentMethod({
    required this.type,
    required this.name,
    this.details,
  });

  // ✅ Safe factory constructor
  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      type: map['type']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      details: map['details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'name': name,
      'details': details,
    };
  }
}