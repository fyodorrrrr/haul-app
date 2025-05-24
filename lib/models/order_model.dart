import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String buyerId;
  final List<String> sellerIds;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? shippingAddress;
  final String? paymentMethod;
  final String? trackingNumber;
  
  // ADD THESE NEW OPTIONAL FIELDS:
  final String? orderNumber;    // For display purposes
  final String? sellerName;     // For easier display
  
  OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerIds,
    required this.items,
    required this.total,
    required this.status,
    required this.createdAt,
    this.shippingAddress,
    this.paymentMethod,
    this.trackingNumber,
    this.orderNumber,           // ADD THIS
    this.sellerName,           // ADD THIS
  });
  
  // UPDATE your fromMap method:
  factory OrderModel.fromMap(String id, Map<String, dynamic> data) {
    // Extract items
    List<OrderItem> orderItems = [];
    if (data['items'] != null) {
      orderItems = (data['items'] as List).map((item) => OrderItem.fromMap(item)).toList();
    }
    
    // Extract seller IDs
    List<String> sellers = [];
    if (data['sellerIds'] != null) {
      sellers = List<String>.from(data['sellerIds']);
    }
    
    // Convert timestamp to DateTime
    DateTime orderDate = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        orderDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        orderDate = DateTime.parse(data['createdAt']);
      }
    }
    
    return OrderModel(
      id: id,
      buyerId: data['buyerId'] ?? '',
      sellerIds: sellers,
      items: orderItems,
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: orderDate,
      shippingAddress: data['shippingAddress'],
      paymentMethod: data['paymentMethod'],
      trackingNumber: data['trackingNumber'],
      orderNumber: data['orderNumber'] ?? 'ORD-${id.substring(0, 8)}', // ADD THIS
      sellerName: data['sellerName'] ?? 'Unknown Seller',              // ADD THIS
    );
  }
  
  // UPDATE your toMap method:
  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerIds': sellerIds,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': createdAt,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'trackingNumber': trackingNumber,
      'orderNumber': orderNumber,     // ADD THIS
      'sellerName': sellerName,       // ADD THIS
    };
  }
  
  // ADD THESE HELPER METHODS:
  String get displayOrderNumber => orderNumber ?? 'ORD-${id.substring(0, 8)}';
  String get displaySellerName => sellerName ?? (sellerIds.isNotEmpty ? 'Seller ${sellerIds.first.substring(0, 8)}' : 'Unknown Seller');
  double get effectivePrice => total; // For compatibility with the package tracking screen
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String sellerId;
  final String? imageURL;
  final String? size;
  final String? color;
  
  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.sellerId,
    this.imageURL,
    this.size,
    this.color,
  });
  
  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      name: data['name'] ?? 'Unknown Product',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0).toDouble(),
      sellerId: data['sellerId'] ?? '',
      imageURL: data['imageURL'],
      size: data['size'],
      color: data['color'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'sellerId': sellerId,
      'imageURL': imageURL,
      'size': size,
      'color': color,
    };
  }
  
  double get subtotal => price * quantity;
}