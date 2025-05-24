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
  // Handle items safely - works with both CartModel and OrderItem formats
  List<OrderItem> orderItems = [];
  if (data['items'] != null && data['items'] is List) {
    for (var item in data['items'] as List) {
      if (item is Map<String, dynamic>) {
        try {
          // Try to parse as OrderItem first, fallback to CartModel format
          orderItems.add(OrderItem.fromMap(item));
        } catch (e) {
          print('Error parsing order item: $e');
          // Create a basic OrderItem if parsing fails
          orderItems.add(OrderItem(
            productId: item['productId']?.toString() ?? '',
            name: item['name']?.toString() ?? item['productName']?.toString() ?? 'Unknown Product',
            quantity: (item['quantity'] is num) ? (item['quantity'] as num).toInt() : 1,
            price: (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0,
            sellerId: item['sellerId']?.toString() ?? '',
            imageURL: item['imageURL']?.toString(),
            size: item['size']?.toString(),
            color: item['color']?.toString(),
          ));
        }
      }
    }
  }
  
  // Extract seller IDs safely
  List<String> sellers = [];
  if (data['sellerIds'] != null) {
    if (data['sellerIds'] is List) {
      sellers = List<String>.from(data['sellerIds']);
    }
  } else {
    // Extract from items if not stored separately
    Set<String> uniqueSellers = {};
    for (var item in orderItems) {
      if (item.sellerId.isNotEmpty) {
        uniqueSellers.add(item.sellerId);
      }
    }
    sellers = uniqueSellers.toList();
  }
  
  // Convert timestamp to DateTime safely
  DateTime orderDate = DateTime.now();
  if (data['createdAt'] != null) {
    try {
      if (data['createdAt'] is Timestamp) {
        orderDate = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        orderDate = DateTime.parse(data['createdAt']);
      }
    } catch (e) {
      print('Error parsing createdAt: $e');
    }
  }
  
  return OrderModel(
    id: id,
    buyerId: data['userId']?.toString() ?? data['buyerId']?.toString() ?? '', // TRY BOTH FIELDS
    sellerIds: sellers,
    items: orderItems,
    total: (data['total'] is num) ? (data['total'] as num).toDouble() : 0.0,
    status: data['status']?.toString() ?? 'pending',
    createdAt: orderDate,
    shippingAddress: data['shippingAddress']?.toString(),
    paymentMethod: data['paymentMethod']?.toString(),
    trackingNumber: data['trackingNumber']?.toString(),
    orderNumber: data['orderNumber']?.toString() ?? 'ORD-${id.substring(0, 8)}',
    sellerName: data['sellerName']?.toString() ?? 'Unknown Seller',
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
    productId: data['productId']?.toString() ?? '',
    name: data['name']?.toString() ?? data['productName']?.toString() ?? 'Unknown Product',
    quantity: (data['quantity'] is num) ? (data['quantity'] as num).toInt() : 1,
    price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
    sellerId: data['sellerId']?.toString() ?? '',
    imageURL: data['imageURL']?.toString(),
    size: data['size']?.toString(),
    color: data['color']?.toString(),
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