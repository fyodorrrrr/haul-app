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
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      sku: map['sku']?.toString() ?? 'SKU-${DateTime.now().millisecondsSinceEpoch}',
      barcode: map['barcode']?.toString(),
      category: map['category']?.toString() ?? '',
      subcategory: map['subcategory']?.toString() ?? map['category']?.toString() ?? '',
      brand: map['brand']?.toString() ?? '',
      
      // Handle both old and new image fields
      images: _toStringList(map['images'] ?? (map['imageUrl'] != null ? [map['imageUrl']] : [])),
      
      // FIXED: Add missing required parameters with defaults
      variants: _toVariantsList(map['variants'] ?? []),
      
      // Handle both old and new stock fields
      currentStock: _toInt(map['currentStock'] ?? map['stock'] ?? 0),
      minimumStock: _toInt(map['minimumStock'] ?? 5),
      maximumStock: _toInt(map['maximumStock'] ?? 1000),
      reorderPoint: _toInt(map['reorderPoint'] ?? 10),
      reorderQuantity: _toInt(map['reorderQuantity'] ?? 50),
      location: map['location']?.toString() ?? 'Main Warehouse',
      reservedStock: _toInt(map['reservedStock'] ?? 0),
      
      // Handle both old and new price fields
      costPrice: _toDouble(map['costPrice'] ?? (map['sellingPrice'] ?? map['price'] ?? 0.0) * 0.7),
      sellingPrice: _toDouble(map['sellingPrice'] ?? map['price'] ?? 0.0),
      salePrice: map['salePrice'] != null ? _toDouble(map['salePrice']) : null,
      taxRate: _toDouble(map['taxRate'] ?? 0.0),
      bulkPricing: _toBulkPricingList(map['bulkPricing'] ?? []),
      
      // Product details
      weight: _toDouble(map['weight'] ?? 0.0),
      dimensions: _toDimensions(map['dimensions']), // FIXED: Add dimensions parameter
      status: _toProductStatus(map['status']), // FIXED: Add status parameter
      isActive: map['isActive'] == true,
      expiryDate: _toOptionalDateTime(map['expiryDate']),
      
      // Analytics
      totalSold: _toInt(map['totalSold'] ?? 0),
      viewCount: _toInt(map['viewCount'] ?? 0),
      turnoverRate: _toDouble(map['turnoverRate'] ?? 0.0),
      
      // Dates
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      
      sellerId: map['sellerId']?.toString() ?? '',
      condition: map['condition']?.toString() ?? 'new',
    );
  }

  // FIXED: Add missing helper methods
  static List<ProductVariant> _toVariantsList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((v) {
        if (v is Map<String, dynamic>) {
          return ProductVariant.fromMap(v);
        }
        return ProductVariant(
          id: '',
          name: '',
          value: '',
          stock: 0,
        );
      }).toList();
    }
    return [];
  }

  static ProductDimensions _toDimensions(dynamic value) {
    if (value == null) return ProductDimensions();
    if (value is Map<String, dynamic>) {
      return ProductDimensions.fromMap(value);
    }
    return ProductDimensions(); // Return default dimensions
  }

  static ProductStatus _toProductStatus(dynamic value) {
    if (value == null) return ProductStatus.active;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'active':
          return ProductStatus.active;
        case 'inactive':
          return ProductStatus.inactive;
        case 'discontinued':
          return ProductStatus.discontinued;
        case 'outofstock':
          return ProductStatus.outOfStock;
        case 'lowstock':
          return ProductStatus.lowStock;
        default:
          return ProductStatus.active;
      }
    }
    return ProductStatus.active;
  }

  static List<BulkPricing> _toBulkPricingList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((b) {
        if (b is Map<String, dynamic>) {
          return BulkPricing.fromMap(b);
        }
        return BulkPricing(
          minQuantity: 1,
          price: 0.0,
          discountPercentage: 0.0,
        );
      }).toList();
    }
    return [];
  }

  static DateTime? _toOptionalDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Existing helper methods (keep these)
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) return [value];
    return [];
  }

  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
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
