class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String condition;
  final String size;
  final String imageUrl; // Optional if you plan to store the image URL in Firebase
  final String brand;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.size,
    required this.imageUrl,
    required this.brand,
  });

  // Factory constructor to create a Product from a Map (Firebase data)
  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      condition: data['condition'] ?? '',
      size: data['size'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      brand: data['brand'] ?? '',
    );
  }

  // Method to convert Product to Map (for saving to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'size': size,
      'imageUrl': imageUrl,
      'brand': brand,
    };
  }
}
