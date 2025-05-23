import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String? _errorMessage;
  List<Product> _products = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Product> get products => _products;

  void _setLoadingState(bool isLoading, [String? error]) {
    _isLoading = isLoading;
    _errorMessage = error;
    notifyListeners();
  }

  // Load seller's products
  Future<void> loadProducts() async {
    _setLoadingState(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      print("Loading products for seller: ${user.uid}"); // Debug log
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .get();
      
      print("Found ${querySnapshot.docs.length} products"); // Debug log
      
      _products = querySnapshot.docs
          .map((doc) {
            try {
              print("Processing product: ${doc.id}"); // Debug log
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Add document ID to data
              return Product.fromMap(data);
            } catch (e) {
              print("Error processing product ${doc.id}: $e"); // Debug log
              return null;
            }
          })
          .where((product) => product != null)
          .cast<Product>()
          .toList();
      
      print("Successfully loaded ${_products.length} products"); // Debug log
      _setLoadingState(false);
    } catch (e) {
      print("Error loading products: $e"); // Debug log
      _setLoadingState(false, e.toString());
    }
  }

  // Upload product images
  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> imageUrls = [];
    
    try {
      for (var image in images) {
        final uuid = const Uuid().v4();
        final storageRef = _storage.ref().child('products/$uuid.jpg');
        
        await storageRef.putFile(image);
        final downloadUrl = await storageRef.getDownloadURL();
        
        imageUrls.add(downloadUrl);
      }
      return imageUrls;
    } catch (e) {
      throw Exception("Failed to upload images: $e");
    }
  }

  // Add a new product
  Future<bool> addProduct({
    required String name,
    required String description,
    required double costPrice,
    required double sellingPrice,
    required int stock,
    required List<File> images,
    required String category,
    required String brand,
    String? sku,
    String? subcategory,
    double? salePrice,
    int? minimumStock,
    String location = 'Main Warehouse',
  }) async {
    _setLoadingState(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      // Upload images first
      final imageUrls = await _uploadImages(images);
      
      // Generate SKU if not provided
      final productSku = sku ?? 'SKU-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create new product with enhanced model
      final newProduct = Product(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        sku: productSku,
        category: category,
        subcategory: subcategory ?? category,
        brand: brand,
        images: imageUrls,
        variants: [], // Start with empty variants
        currentStock: stock,
        minimumStock: minimumStock ?? 5,
        maximumStock: 1000,
        reorderPoint: minimumStock ?? 10,
        reorderQuantity: 50,
        location: location,
        reservedStock: 0,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
        salePrice: salePrice,
        taxRate: 0.0,
        bulkPricing: [],
        weight: 0.0,
        dimensions: ProductDimensions(),
        status: ProductStatus.active,
        isActive: true,
        totalSold: 0,
        viewCount: 0,
        turnoverRate: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sellerId: user.uid,
      );
      
      // Save to Firestore
      final docRef = await _firestore.collection('products').add(newProduct.toMap());
      
      // Update the product with the document ID
      await docRef.update({'id': docRef.id});
      
      // Update the seller's metrics
      await _firestore.collection('sellers').doc(user.uid).update({
        'activeListings': FieldValue.increment(1),
      });
      
      // Add to local list with the correct ID
      final productData = newProduct.toMap();
      productData['id'] = docRef.id;
      _products.insert(0, Product.fromMap(productData));
      
      _setLoadingState(false);
      return true;
    } catch (e) {
      print("Error adding product: $e");
      _setLoadingState(false, e.toString());
      return false;
    }
  }

  // Update an existing product
  Future<bool> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double costPrice,
    required double sellingPrice,
    required int stock,
    required List<File> newImages,
    required List<String> existingImageUrls,
    required String category,
    required String brand,
    required bool isActive,
    String? subcategory,
    double? salePrice,
    int? minimumStock,
    String? sku,
  }) async {
    _setLoadingState(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      // Upload new images if any
      List<String> allImageUrls = List.from(existingImageUrls);
      if (newImages.isNotEmpty) {
        final newImageUrls = await _uploadImages(newImages);
        allImageUrls.addAll(newImageUrls);
      }
      
      // Update product in Firestore
      final productRef = _firestore.collection('products').doc(productId);
      await productRef.update({
        'name': name,
        'description': description,
        'costPrice': costPrice,
        'sellingPrice': sellingPrice,
        'currentStock': stock, // Updated field name
        'images': allImageUrls,
        'category': category,
        'subcategory': subcategory ?? category,
        'brand': brand,
        'isActive': isActive,
        'salePrice': salePrice,
        'minimumStock': minimumStock ?? 5,
        'sku': sku,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updated = await productRef.get();
        if (updated.exists) {
          final data = updated.data()! as Map<String, dynamic>;
          data['id'] = productId;
          _products[index] = Product.fromMap(data);
        }
      }
      
      _setLoadingState(false);
      return true;
    } catch (e) {
      print("Error updating product: $e");
      _setLoadingState(false, e.toString());
      return false;
    }
  }

  // Delete a product
  Future<bool> deleteProduct(String productId) async {
    _setLoadingState(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      // Get product to check if it belongs to this seller
      final product = _products.firstWhere((p) => p.id == productId);
      if (product.sellerId != user.uid) {
        throw Exception("You don't have permission to delete this product");
      }
      
      // Delete product from Firestore
      await _firestore.collection('products').doc(productId).delete();
      
      // Update the seller's metrics
      await _firestore.collection('sellers').doc(user.uid).update({
        'activeListings': FieldValue.increment(-1),
      });
      
      // Remove from local list
      _products.removeWhere((p) => p.id == productId);
      
      _setLoadingState(false);
      return true;
    } catch (e) {
      print("Error deleting product: $e");
      _setLoadingState(false, e.toString());
      return false;
    }
  }

  // Update stock for a product
  Future<bool> updateStock(String productId, int newStock, String reason) async {
    _setLoadingState(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      // Update in Firestore
      await _firestore.collection('products').doc(productId).update({
        'currentStock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final currentProduct = _products[index];
        final updatedData = currentProduct.toMap();
        updatedData['currentStock'] = newStock;
        updatedData['updatedAt'] = DateTime.now().toIso8601String();
        _products[index] = Product.fromMap(updatedData);
      }
      
      _setLoadingState(false);
      return true;
    } catch (e) {
      print("Error updating stock: $e");
      _setLoadingState(false, e.toString());
      return false;
    }
  }

  // Get product statistics
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      final sellerDoc = await _firestore.collection('sellers').doc(user.uid).get();
      final sellerData = sellerDoc.data() ?? {};
      
      // Calculate inventory values
      final totalInventoryValue = _products.fold(0.0, (sum, p) => sum + (p.costPrice * p.currentStock));
      final totalSellingValue = _products.fold(0.0, (sum, p) => sum + (p.sellingPrice * p.currentStock));
      final lowStockCount = _products.where((p) => p.isLowStock).length;
      final outOfStockCount = _products.where((p) => p.isOutOfStock).length;
      
      return {
        'totalProducts': _products.length,
        'activeProducts': _products.where((p) => p.isActive).length,
        'lowStockProducts': lowStockCount,
        'outOfStockProducts': outOfStockCount,
        'totalViews': _products.fold(0, (sum, p) => sum + p.viewCount),
        'totalOrders': sellerData['ordersCount'] ?? 0,
        'totalSales': sellerData['totalSales'] ?? 0.0,
        'inventoryValue': totalInventoryValue,
        'sellingValue': totalSellingValue,
        'profitPotential': totalSellingValue - totalInventoryValue,
      };
    } catch (e) {
      print("Error getting statistics: $e");
      return {
        'totalProducts': 0,
        'activeProducts': 0,
        'lowStockProducts': 0,
        'outOfStockProducts': 0,
        'totalViews': 0,
        'totalOrders': 0,
        'totalSales': 0.0,
        'inventoryValue': 0.0,
        'sellingValue': 0.0,
        'profitPotential': 0.0,
      };
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    if (category.toLowerCase() == 'all') return _products;
    return _products.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
  }

  // Get low stock products
  List<Product> getLowStockProducts() {
    return _products.where((p) => p.isLowStock && p.isActive).toList();
  }

  // Search products
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) =>
      product.name.toLowerCase().contains(lowercaseQuery) ||
      product.sku.toLowerCase().contains(lowercaseQuery) ||
      product.category.toLowerCase().contains(lowercaseQuery) ||
      product.brand.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}