import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String name;
  final List<String> images;

  Product({
    required this.name,
    required this.images,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      name: data['name'] ?? '',
      images: List<String>.from(data['images'] ?? []),
    );
  }
}
