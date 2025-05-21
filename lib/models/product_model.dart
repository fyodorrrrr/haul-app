import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final List<String> images;
  
  // Change from single category to categories list
  final String category;  // Keep for backward compatibility
  final List<String> categories; // Add this field for multiple categories
  
  final String size;
  final String condition;
  final String brand;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int viewCount;
  final int orderCount;

  // Add imageUrl getter for backward compatibility
  String get imageUrl => images.isNotEmpty ? images.first : '';

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
    
    // Add support for categories list
    this.category = '',
    List<String>? categories,
    
    this.size = '',
    this.condition = '',
    this.brand = '',
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.viewCount = 0,
    this.orderCount = 0,
  }) : this.categories = categories ?? [category].where((c) => c.isNotEmpty).toList();


  factory Product.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>? ?? {};
  return Product.fromMap(doc.id, data);
}


  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'images': images,
      
      // Include both fields for backward compatibility
      'category': category,
      'categories': categories,
      
      'size': size,
      'condition': condition,
      'brand': brand,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'viewCount': viewCount,
      'orderCount': orderCount,
    };
  }

  // Update the fromMap method in your Product model to handle legacy data
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      sellerId: map['sellerId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock']?.toInt() ?? 0,
      
      // Handle potential legacy data structures
      images: map['images'] != null 
        ? List<String>.from(map['images']) 
        : map['imageUrl'] != null 
          ? [map['imageUrl']] 
          : [],
          
      // Handle categories field that might be missing
      categories: map['categories'] != null 
        ? List<String>.from(map['categories']) 
        : map['category'] != null && map['category'].toString().isNotEmpty
          ? [map['category']]
          : [],
          
      // Handle other new fields with default values
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: map['viewCount']?.toInt() ?? 0,
      orderCount: map['orderCount']?.toInt() ?? 0,
      
      // Add default values for new fields
      condition: map['condition'] ?? '',
      size: map['size'] ?? '',
      brand: map['brand'] ?? '',
    );
  }
}
