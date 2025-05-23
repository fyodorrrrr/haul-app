// Create lib/providers/inventory_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';

class InventoryProvider with ChangeNotifier {
  List<Product> _products = [];
  List<StockMovement> _stockMovements = [];
  List<Product> _lowStockProducts = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Product> get products => _products;
  List<StockMovement> get stockMovements => _stockMovements;
  List<Product> get lowStockProducts => _lowStockProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Analytics getters
  int get totalProducts => _products.length;
  int get activeProducts => _products.where((p) => p.isActive).length;
  int get outOfStockProducts => _products.where((p) => p.isOutOfStock).length;
  int get lowStockCount => _lowStockProducts.length;
  double get totalInventoryValue => _products.fold(0.0, (sum, p) => sum + (p.costPrice * p.currentStock));
  double get totalSellingValue => _products.fold(0.0, (sum, p) => sum + (p.sellingPrice * p.currentStock));

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .get();

      _products = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data()))
          .toList();

      _updateLowStockProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> adjustStock(String productId, int newStock, String reason) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final product = _products.firstWhere((p) => p.id == productId);
      final previousStock = product.currentStock;
      final quantity = newStock - previousStock;

      // Update product stock
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({
        'currentStock': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Create stock movement record
      final stockMovement = StockMovement(
        id: FirebaseFirestore.instance.collection('stock_movements').doc().id,
        productId: productId,
        productName: product.name,
        sku: product.sku,
        type: quantity > 0 ? StockMovementType.stockIn : StockMovementType.stockOut,
        quantity: quantity.abs(),
        previousStock: previousStock,
        newStock: newStock,
        reason: reason,
        location: product.location,
        sellerId: user.uid,
        createdAt: DateTime.now(),
        createdBy: user.uid,
      );

      await FirebaseFirestore.instance
          .collection('stock_movements')
          .doc(stockMovement.id)
          .set(stockMovement.toMap());

      // Update local state
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = Product.fromMap({
          ..._products[index].toMap(),
          'currentStock': newStock,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      _updateLowStockProducts();
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to adjust stock: $e');
    }
  }

  Future<void> fetchStockMovements() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('stock_movements')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      _stockMovements = querySnapshot.docs
          .map((doc) => StockMovement.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching stock movements: $e');
    }
  }

  void _updateLowStockProducts() {
    _lowStockProducts = _products.where((p) => p.isLowStock && p.isActive).toList();
  }

  Future<void> bulkUpdateStock(Map<String, int> stockUpdates, String reason) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      for (final entry in stockUpdates.entries) {
        final productId = entry.key;
        final newStock = entry.value;
        
        // Update product
        final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
        batch.update(productRef, {
          'currentStock': newStock,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Create stock movement
        final product = _products.firstWhere((p) => p.id == productId);
        final stockMovement = StockMovement(
          id: FirebaseFirestore.instance.collection('stock_movements').doc().id,
          productId: productId,
          productName: product.name,
          sku: product.sku,
          type: StockMovementType.adjustment,
          quantity: (newStock - product.currentStock).abs(),
          previousStock: product.currentStock,
          newStock: newStock,
          reason: reason,
          location: product.location,
          sellerId: user.uid,
          createdAt: DateTime.now(),
          createdBy: user.uid,
        );

        final movementRef = FirebaseFirestore.instance.collection('stock_movements').doc(stockMovement.id);
        batch.set(movementRef, stockMovement.toMap());
      }

      await batch.commit();
      await fetchProducts(); // Refresh products
    } catch (e) {
      throw Exception('Failed to bulk update stock: $e');
    }
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    return _products.where((product) =>
      product.name.toLowerCase().contains(query.toLowerCase()) ||
      product.sku.toLowerCase().contains(query.toLowerCase()) ||
      product.category.toLowerCase().contains(query.toLowerCase()) ||
      product.brand.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  List<Product> filterByCategory(String category) {
    if (category.isEmpty || category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }

  List<Product> filterByStatus(ProductStatus status) {
    return _products.where((p) => p.status == status).toList();
  }
}