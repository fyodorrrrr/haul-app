import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/cart_model.dart';
import '/utils/snackbar_helper.dart';

class CartProvider with ChangeNotifier {
  List<CartModel> _cart = [];

  List<CartModel> get cart => _cart;

  // Fetch cart from Firestore
  Future<void> fetchCart(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .where('userId', isEqualTo: userId)
          .get();

      _cart = snapshot.docs
          .map((doc) => CartModel.fromMap(doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      print("Error fetching cart: $e");
    }
  }

  // Add a product to cart
  Future<void> addToCart(CartModel cartItem) async {
    try {
      await FirebaseFirestore.instance
          .collection('carts')
          .add(cartItem.toMap());
      _cart.add(cartItem);
      notifyListeners();
    } catch (e) {
      print("Error adding to cart: $e");
    }
  }

  // Remove an item from the cart
  Future<void> removeFromCart(String productId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .where('productId', isEqualTo: productId)
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _cart.removeWhere((item) => item.productId == productId && item.userId == user.uid);
      notifyListeners();
    } catch (e) {
      print("Error removing from cart: $e");
    }
  }

  // Clear the cart (local only)
  void clearCart() {
    _cart = [];
    notifyListeners();
  }
  
  // Clear the cart from Firebase after checkout
  Future<void> clearCartFromFirebase(String userId) async {
    try {
      // Get all cart items for this user
      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        // Create a batch write to delete all items efficiently
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        // Execute the batch delete
        await batch.commit();
        
        // Clear local cart as well
        _cart = [];
        notifyListeners();
        print('Cart cleared from Firebase successfully');
      }
    } catch (e) {
      print('Error clearing cart from Firebase: $e');
      throw e; // Re-throw to allow handling by the caller
    }
  }

  // Check if a product is in the cart
  bool isInCart(String productId) {
    return _cart.any((item) => item.productId == productId);
  }

  // Handle add to cart logic
  Future<void> handleAddToCart({
    required BuildContext context,
    required String productId,
    required String userId,
    required CartModel cartItem,
  }) async {
    try {
      if (isInCart(productId)) {
        await removeFromCart(productId);
        SnackBarHelper.showSnackBar(
          context,
          'Removed from cart',
          isError: true,
        );
      } else {
        await addToCart(
          CartModel(
            productId: cartItem.productId,
            userId: cartItem.userId,
            sellerId: cartItem.sellerId, // Add the seller ID here
            productName: cartItem.productName,
            imageURL: cartItem.imageURL,
            productPrice: cartItem.productPrice,
            addedAt: DateTime.now(),
          ),
        );
        SnackBarHelper.showSnackBar(
          context,
          'Added to cart',
          isSuccess: true,
        );
      }
    } catch (e) {
      SnackBarHelper.showSnackBar(
        context,
        'An error occurred. Please try again.',
        isError: true,
      );
    }
  }

  // Add this method to update cart items with missing seller IDs
  Future<void> updateCartItemsWithSellerId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get all cart items for this user
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('carts')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      bool updatesNeeded = false;

      // For each cart item without a seller ID, fetch the product and update
      for (var doc in cartSnapshot.docs) {
        final data = doc.data();
        if (data['sellerId'] == null || data['sellerId'] == '') {
          // Fetch product info to get seller ID
          final productId = data['productId'];
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();
              
          if (productDoc.exists) {
            final sellerId = productDoc.data()?['sellerId'];
            if (sellerId != null && sellerId != '') {
              // Update with seller ID
              batch.update(doc.reference, {'sellerId': sellerId});
              updatesNeeded = true;
            }
          }
        }
      }
      
      if (updatesNeeded) {
        await batch.commit();
        // Refresh cart
        await fetchCart(user.uid);
      }
    } catch (e) {
      print('Error updating cart with seller IDs: $e');
    }
  }
}