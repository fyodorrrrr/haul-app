import 'package:cloud_firestore/cloud_firestore.dart';

// Update your existing lib/models/product.dart
class Product {
  final String id;
  final String name;
  final String description;
  final String sku;
  final String? barcode;
  final String category;
  final String subcategory;
  final String brand;
  final List<String> images;
  final List<ProductVariant> variants;
  
  // Stock Management
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final int reorderPoint;
  final int reorderQuantity;
  final String location;
  final int reservedStock; // For pending orders
  
  // Pricing
  final double costPrice;
  final double sellingPrice;
  final double? salePrice;
  final double taxRate;
  final List<BulkPricing> bulkPricing;
  
  // Product Details
  final double weight;
  final ProductDimensions dimensions;
  final ProductStatus status;
  final bool isActive;
  final DateTime? expiryDate;
  
  // Analytics
  final int totalSold;
  final int viewCount;
  final double turnoverRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sellerId;
  final String condition;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.sku,
    this.barcode,
    required this.category,
    required this.subcategory,
    required this.brand,
    required this.images,
    required this.variants,
    required this.currentStock,
    this.minimumStock = 5,
    this.maximumStock = 1000,
    this.reorderPoint = 10,
    this.reorderQuantity = 50,
    this.location = 'Main Warehouse',
    this.reservedStock = 0,
    required this.costPrice,
    required this.sellingPrice,
    this.salePrice,
    this.taxRate = 0.0,
    this.bulkPricing = const [],
    this.weight = 0.0,
    required this.dimensions,
    this.status = ProductStatus.active,
    this.isActive = true,
    this.expiryDate,
    this.totalSold = 0,
    this.viewCount = 0,
    this.turnoverRate = 0.0,
    required this.createdAt,
    required this.updatedAt,
    required this.sellerId,
    this.condition = 'new', // Default condition
  });

  // Calculate available stock (current - reserved)
  int get availableStock => currentStock - reservedStock;
  
  // Check if product is low on stock
  bool get isLowStock => currentStock <= minimumStock;
  
  // Check if product is out of stock
  bool get isOutOfStock => currentStock <= 0;
  
  // Calculate profit margin
  double get profitMargin => ((sellingPrice - costPrice) / costPrice) * 100;
  
  // Get effective selling price (sale price if available, otherwise regular price)
  double get effectivePrice => salePrice ?? sellingPrice;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      sku: map['sku'] ?? '',
      barcode: map['barcode'],
      category: map['category'] ?? '',
      subcategory: map['subcategory'] ?? '',
      brand: map['brand'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      variants: (map['variants'] as List?)?.map((v) => ProductVariant.fromMap(v)).toList() ?? [],
      currentStock: map['currentStock'] ?? 0,
      minimumStock: map['minimumStock'] ?? 5,
      maximumStock: map['maximumStock'] ?? 1000,
      reorderPoint: map['reorderPoint'] ?? 10,
      reorderQuantity: map['reorderQuantity'] ?? 50,
      location: map['location'] ?? 'Main Warehouse',
      reservedStock: map['reservedStock'] ?? 0,
      costPrice: (map['costPrice'] ?? 0.0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0.0).toDouble(),
      salePrice: map['salePrice']?.toDouble(),
      taxRate: (map['taxRate'] ?? 0.0).toDouble(),
      bulkPricing: (map['bulkPricing'] as List?)?.map((b) => BulkPricing.fromMap(b)).toList() ?? [],
      weight: (map['weight'] ?? 0.0).toDouble(),
      dimensions: ProductDimensions.fromMap(map['dimensions'] ?? {}),
      status: ProductStatus.values.firstWhere((s) => s.name == map['status'], orElse: () => ProductStatus.active),
      isActive: map['isActive'] ?? true,
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      totalSold: map['totalSold'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      turnoverRate: (map['turnoverRate'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      sellerId: map['sellerId'] ?? '',
      condition: map['condition'] ?? 'new', // Default to 'new' if not provided
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'barcode': barcode,
      'category': category,
      'subcategory': subcategory,
      'brand': brand,
      'images': images,
      'variants': variants.map((v) => v.toMap()).toList(),
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'reorderPoint': reorderPoint,
      'reorderQuantity': reorderQuantity,
      'location': location,
      'reservedStock': reservedStock,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'salePrice': salePrice,
      'taxRate': taxRate,
      'bulkPricing': bulkPricing.map((b) => b.toMap()).toList(),
      'weight': weight,
      'dimensions': dimensions.toMap(),
      'status': status.name,
      'isActive': isActive,
      'expiryDate': expiryDate?.toIso8601String(),
      'totalSold': totalSold,
      'viewCount': viewCount,
      'turnoverRate': turnoverRate,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sellerId': sellerId,
      'condition': condition, // Include condition in the map
    };
  }
}

// Supporting models
enum ProductStatus { active, inactive, discontinued, outOfStock, lowStock }

class ProductVariant {
  final String id;
  final String name;
  final String value;
  final double? priceAdjustment;
  final int stock;

  ProductVariant({
    required this.id,
    required this.name,
    required this.value,
    this.priceAdjustment,
    required this.stock,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      value: map['value'] ?? '',
      priceAdjustment: map['priceAdjustment']?.toDouble(),
      stock: map['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'priceAdjustment': priceAdjustment,
      'stock': stock,
    };
  }
}

class BulkPricing {
  final int minQuantity;
  final double price;
  final double discountPercentage;

  BulkPricing({
    required this.minQuantity,
    required this.price,
    required this.discountPercentage,
  });

  factory BulkPricing.fromMap(Map<String, dynamic> map) {
    return BulkPricing(
      minQuantity: map['minQuantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      discountPercentage: (map['discountPercentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minQuantity': minQuantity,
      'price': price,
      'discountPercentage': discountPercentage,
    };
  }
}

class ProductDimensions {
  final double length;
  final double width;
  final double height;
  final String unit;

  ProductDimensions({
    this.length = 0.0,
    this.width = 0.0,
    this.height = 0.0,
    this.unit = 'cm',
  });

  factory ProductDimensions.fromMap(Map<String, dynamic> map) {
    return ProductDimensions(
      length: (map['length'] ?? 0.0).toDouble(),
      width: (map['width'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'cm',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'length': length,
      'width': width,
      'height': height,
      'unit': unit,
    };
  }
}
