import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haul/models/cart_model.dart';
import 'package:haul/models/shipping_address.dart';
import 'package:haul/models/payment_method.dart';

class Order {
  final String? id;
  final String userId;
  final List<CartModel> items;
  final ShippingAddress shippingAddress;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;
  final String status;
  final DateTime createdAt;

  Order({
    this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    this.status = 'pending',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'paymentMethod': paymentMethod.toMap(),
      'subtotal': subtotal,
      'shipping': shipping,
      'tax': tax,
      'total': total,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => CartModel.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      shippingAddress: ShippingAddress.fromMap(map['shippingAddress'] as Map<String, dynamic>),
      paymentMethod: PaymentMethod.fromMap(map['paymentMethod'] as Map<String, dynamic>),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      shipping: (map['shipping'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt']))
          : DateTime.now(),
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order.fromMap(json);
  }

  Map<String, dynamic> toJson() {
    return toMap();
  }

  Order copyWith({
    String? id,
    String? userId,
    List<CartModel>? items,
    ShippingAddress? shippingAddress,
    PaymentMethod? paymentMethod,
    double? subtotal,
    double? shipping,
    double? tax,
    double? total,
    String? status,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      shipping: shipping ?? this.shipping,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}