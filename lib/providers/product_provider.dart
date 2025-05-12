import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';

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
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      final querySnapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      
      _products = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.id, doc.data()))
          .toList();
      
      _setLoadingState(false);
    } catch (e) {
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
    required double price,
    required int stock,
    required List<File> images,
    required List<String> categories,
  }) async {
    _setLoadingState(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not authenticated");
      
      // Upload images first
      final imageUrls = await _uploadImages(images);
      
      // Create new product
      final newProduct = Product(
        id: '', // Will be set by Firestore
        sellerId: user.uid,
        name: name,
        description: description,
        price: price,
        stock: stock,
        images: imageUrls,
        categories: categories,
        brand: 'Default Brand', // Add the required brand parameter
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to Firestore
      final docRef = await _firestore.collection('products').add(newProduct.toMap());
      
      // Update the seller's metrics
      await _firestore.collection('sellers').doc(user.uid).update({
        'activeListings': FieldValue.increment(1),
      });
      
      // Add to local list
      _products.insert(0, Product.fromMap(docRef.id, newProduct.toMap()));
      
      _setLoadingState(false);
      return true;
    } catch (e) {
      _setLoadingState(false, e.toString());
      return false;
    }
  }

  // Update an existing product
  Future<bool> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required int stock,
    required List<File> newImages,
    required List<String> existingImageUrls,
    required List<String> categories,
    required bool isActive,
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
        'price': price,
        'stock': stock,
        'images': allImageUrls,
        'categories': categories,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update local list
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updated = await productRef.get();
        _products[index] = Product.fromMap(productId, updated.data()!);
      }
      
      _setLoadingState(false);
      return true;
    } catch (e) {
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
      
      return {
        'totalProducts': _products.length,
        'activeProducts': _products.where((p) => p.isActive).length,
        'totalViews': _products.fold(0, (sum, p) => sum + p.viewCount),
        'totalOrders': sellerData['ordersCount'] ?? 0,
        'totalSales': sellerData['totalSales'] ?? 0.0,
      };
    } catch (e) {
      return {
        'totalProducts': 0,
        'activeProducts': 0,
        'totalViews': 0,
        'totalOrders': 0,
        'totalSales': 0.0,
      };
    }
  }
}