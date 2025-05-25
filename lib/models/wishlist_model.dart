class WishlistModel {
  final String? id; // Add ID field for Firestore document reference
  final String productId;
  final String userId;
  final String productName;
  final String productImage;
  final double productPrice;
  final DateTime addedAt;
  final String? sellerId; // Add seller information
  final String? sellerName;
  final String? brand; // Add product details
  final String? condition;
  final String? size;
  final bool? isOnSale; // Add sale tracking
  final double? salePrice;
  final int? originalStock; // Track stock when added

  WishlistModel({
    this.id,
    required this.productId,
    required this.userId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.addedAt,
    this.sellerId,
    this.sellerName,
    this.brand,
    this.condition,
    this.size,
    this.isOnSale,
    this.salePrice,
    this.originalStock,
  });

  // Enhanced toMap method
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'addedAt': addedAt.toIso8601String(),
      'sellerId': sellerId,
      'sellerName': sellerName,
      'brand': brand,
      'condition': condition,
      'size': size,
      'isOnSale': isOnSale,
      'salePrice': salePrice,
      'originalStock': originalStock,
    };
  }

  // Enhanced fromMap method
  factory WishlistModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return WishlistModel(
      id: documentId ?? map['id'],
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      productName: map['productName'] ?? 'Unknown Product',
      productImage: map['productImage'] ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      addedAt: map['addedAt'] != null 
          ? DateTime.parse(map['addedAt']) 
          : DateTime.now(),
      sellerId: map['sellerId'],
      sellerName: map['sellerName'],
      brand: map['brand'],
      condition: map['condition'],
      size: map['size'],
      isOnSale: map['isOnSale'],
      salePrice: map['salePrice']?.toDouble(),
      originalStock: map['originalStock']?.toInt(),
    );
  }

  // Enhanced helper methods
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(addedAt);
    return difference.inDays < 7; // Changed to 7 days for more recent items
  }

  bool get hasDiscount => salePrice != null && salePrice! < productPrice;

  double get effectivePrice => salePrice ?? productPrice;

  String get displayPrice {
    if (hasDiscount) {
      return '\$${salePrice!.toStringAsFixed(2)} (was \$${productPrice.toStringAsFixed(2)})';
    }
    return '\$${productPrice.toStringAsFixed(2)}';
  }

  // Copy method for updates
  WishlistModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? productName,
    String? productImage,
    double? productPrice,
    DateTime? addedAt,
    String? sellerId,
    String? sellerName,
    String? brand,
    String? condition,
    String? size,
    bool? isOnSale,
    double? salePrice,
    int? originalStock,
  }) {
    return WishlistModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      addedAt: addedAt ?? this.addedAt,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      brand: brand ?? this.brand,
      condition: condition ?? this.condition,
      size: size ?? this.size,
      isOnSale: isOnSale ?? this.isOnSale,
      salePrice: salePrice ?? this.salePrice,
      originalStock: originalStock ?? this.originalStock,
    );
  }
}