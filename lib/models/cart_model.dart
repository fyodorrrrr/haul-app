import 'package:cloud_firestore/cloud_firestore.dart';

class CartModel {
  final String? id;
  final String? productId;
  final String? productName;
  final String? sellerId;
  final String? sellerName;
  final String? brand;
  final String? category;
  final String? imageURL; // ✅ Match your property name
  final String? size;
  final String? condition;
  final double? productPrice; // ✅ Match your property name
  final int quantity; // ✅ Add quantity property
  final String? userId;
  final DateTime? addedAt;

  CartModel({
    this.id,
    this.productId,
    this.productName,
    this.sellerId,
    this.sellerName,
    this.brand,
    this.category,
    this.imageURL,
    this.size,
    this.condition,
    this.productPrice,
    this.quantity = 1,
    this.userId,
    this.addedAt,
  });

  // ✅ Add fromMap method (factory constructor)
  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      sellerId: map['sellerId'],
      sellerName: map['sellerName'],
      brand: map['brand'],
      category: map['category'],
      imageURL: map['imageURL'],
      size: map['size'],
      condition: map['condition'],
      productPrice: (map['productPrice'] as num?)?.toDouble(),
      quantity: map['quantity'] ?? 1,
      userId: map['userId'],
      addedAt: map['addedAt'] != null
          ? (map['addedAt'] is Timestamp
              ? (map['addedAt'] as Timestamp).toDate()
              : DateTime.parse(map['addedAt']))
          : null,
    );
  }

  // ✅ Add toMap method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'brand': brand,
      'category': category,
      'imageURL': imageURL,
      'size': size,
      'condition': condition,
      'productPrice': productPrice,
      'quantity': quantity,
      'userId': userId,
      'addedAt': addedAt,
    };
  }

  // ✅ Keep existing fromJson method for compatibility
  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel.fromMap(json);
  }

  // ✅ Keep existing toJson method for compatibility
  Map<String, dynamic> toJson() {
    return toMap();
  }

  // ✅ Add copyWith method for updating items
  CartModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? sellerId,
    String? sellerName,
    String? brand,
    String? category,
    String? imageURL,
    String? size,
    String? condition,
    double? productPrice,
    int? quantity,
    String? userId,
    DateTime? addedAt,
  }) {
    return CartModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      imageURL: imageURL ?? this.imageURL,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      userId: userId ?? this.userId,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
