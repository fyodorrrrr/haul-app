import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String type;
  final String? cardLastFour;
  final String? cardType;
  final String? cardholderName;
  final String? expiryMonth;
  final String? expiryYear;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    this.cardLastFour,
    this.cardType,
    this.cardholderName,
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
  });

  // ✅ Add toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'cardLastFour': cardLastFour,
      'cardType': cardType,
      'cardholderName': cardholderName,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'isDefault': isDefault,
    };
  }

  // ✅ Add fromMap method
  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      cardLastFour: map['cardLastFour'],
      cardType: map['cardType'],
      cardholderName: map['cardholderName'],
      expiryMonth: map['expiryMonth'],
      expiryYear: map['expiryYear'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  // ✅ Keep existing fromJson for compatibility
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod.fromMap(json);
  }

  // ✅ Keep existing toJson for compatibility
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // ✅ Add copyWith method
  PaymentMethod copyWith({
    String? id,
    String? type,
    String? cardLastFour,
    String? cardType,
    String? cardholderName,
    String? expiryMonth,
    String? expiryYear,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      cardLastFour: cardLastFour ?? this.cardLastFour,
      cardType: cardType ?? this.cardType,
      cardholderName: cardholderName ?? this.cardholderName,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'PaymentMethod(id: $id, type: $type, cardLastFour: $cardLastFour, cardType: $cardType, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PaymentMethod &&
        other.id == id &&
        other.type == type &&
        other.cardLastFour == cardLastFour &&
        other.cardType == cardType &&
        other.cardholderName == cardholderName &&
        other.expiryMonth == expiryMonth &&
        other.expiryYear == expiryYear &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        cardLastFour.hashCode ^
        cardType.hashCode ^
        cardholderName.hashCode ^
        expiryMonth.hashCode ^
        expiryYear.hashCode ^
        isDefault.hashCode;
  }
}