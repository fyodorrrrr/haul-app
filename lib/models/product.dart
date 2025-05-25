import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/currency_formatter.dart';

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
  final int reservedStock;
  
  // Pricing (in Philippine Peso)
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
    this.condition = 'new',
  });

  // Calculate available stock
  int get availableStock => currentStock - reservedStock;
  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  double get profitMargin => ((sellingPrice - costPrice) / costPrice) * 100;
  double get effectivePrice => salePrice ?? sellingPrice;

  // FIXED: Currency formatting getters using the utility
  String get formattedCostPrice => CurrencyFormatter.format(costPrice);
  String get formattedSellingPrice => CurrencyFormatter.format(sellingPrice);
  String get formattedSalePrice => salePrice != null ? CurrencyFormatter.format(salePrice!) : '';
  String get formattedEffectivePrice => CurrencyFormatter.format(effectivePrice);
  
  // For display in cards (no decimals)
  String get displayPrice => CurrencyFormatter.formatWhole(effectivePrice);
  String get displaySellingPrice => CurrencyFormatter.formatWhole(sellingPrice);
  String get displaySalePrice => salePrice != null ? CurrencyFormatter.formatWhole(salePrice!) : '';

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
      
      images: _toStringList(map['images'] ?? (map['imageUrl'] != null ? [map['imageUrl']] : [])),
      variants: _toVariantsList(map['variants'] ?? []),
      
      currentStock: _toInt(map['currentStock'] ?? map['stock'] ?? 0),
      minimumStock: _toInt(map['minimumStock'] ?? 5),
      maximumStock: _toInt(map['maximumStock'] ?? 1000),
      reorderPoint: _toInt(map['reorderPoint'] ?? 10),
      reorderQuantity: _toInt(map['reorderQuantity'] ?? 50),
      location: map['location']?.toString() ?? 'Main Warehouse',
      reservedStock: _toInt(map['reservedStock'] ?? 0),
      
      costPrice: _toDouble(map['costPrice'] ?? (map['sellingPrice'] ?? map['price'] ?? 0.0) * 0.7),
      sellingPrice: _toDouble(map['sellingPrice'] ?? map['price'] ?? 0.0),
      salePrice: map['salePrice'] != null ? _toDouble(map['salePrice']) : null,
      taxRate: _toDouble(map['taxRate'] ?? 0.0),
      bulkPricing: _toBulkPricingList(map['bulkPricing'] ?? []),
      
      weight: _toDouble(map['weight'] ?? 0.0),
      dimensions: _toDimensions(map['dimensions']),
      status: _toProductStatus(map['status']),
      isActive: map['isActive'] == true,
      expiryDate: _toOptionalDateTime(map['expiryDate']),
      
      totalSold: _toInt(map['totalSold'] ?? 0),
      viewCount: _toInt(map['viewCount'] ?? 0),
      turnoverRate: _toDouble(map['turnoverRate'] ?? 0.0),
      
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
      
      sellerId: map['sellerId']?.toString() ?? '',
      condition: map['condition']?.toString() ?? 'new',
    );
  }

  // ✅ Add the missing fromFirestore method
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    data['id'] = doc.id; // Add document ID to data
    
    // Handle Timestamp conversion
    if (data['createdAt'] is Timestamp) {
      data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
    }
    if (data['updatedAt'] is Timestamp) {
      data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
    }
    
    // Handle other potential Timestamp fields
    data.forEach((key, value) {
      if (value is Timestamp) {
        data[key] = value.toDate();
      }
    });
    
    return Product.fromMap(data);
  }

  // Helper methods (keep all existing helper methods)
  static List<ProductVariant> _toVariantsList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((v) {
        if (v is Map<String, dynamic>) {
          return ProductVariant.fromMap(v);
        }
        return ProductVariant(id: '', name: '', value: '', stock: 0);
      }).toList();
    }
    return [];
  }

  static ProductDimensions _toDimensions(dynamic value) {
    if (value == null) return ProductDimensions();
    if (value is Map<String, dynamic>) {
      return ProductDimensions.fromMap(value);
    }
    return ProductDimensions();
  }

  static ProductStatus _toProductStatus(dynamic value) {
    if (value == null) return ProductStatus.active;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'active': return ProductStatus.active;
        case 'inactive': return ProductStatus.inactive;
        case 'discontinued': return ProductStatus.discontinued;
        case 'outofstock': return ProductStatus.outOfStock;
        case 'lowstock': return ProductStatus.lowStock;
        default: return ProductStatus.active;
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
        return BulkPricing(minQuantity: 1, price: 0.0, discountPercentage: 0.0);
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
      'condition': condition,
    };
  }
}

// Supporting models
enum ProductStatus { active, inactive, discontinued, outOfStock, lowStock }

class ProductVariant {
  final String id;
  final String name;
  final String value;
  final double? priceAdjustment; // In Philippine Peso
  final int stock;

  ProductVariant({
    required this.id,
    required this.name,
    required this.value,
    this.priceAdjustment,
    required this.stock,
  });

  // FIXED: Currency formatting for variant price adjustment
  String get formattedPriceAdjustment => 
    priceAdjustment != null ? '₱${priceAdjustment!.toStringAsFixed(2)}' : '';

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
  final double price; // In Philippine Peso
  final double discountPercentage;

  BulkPricing({
    required this.minQuantity,
    required this.price,
    required this.discountPercentage,
  });

  // FIXED: Currency formatting for bulk pricing
  String get formattedPrice => '₱${price.toStringAsFixed(2)}';

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
