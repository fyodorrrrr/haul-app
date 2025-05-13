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
}