import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .where('productId', isEqualTo: productId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _cart.removeWhere((item) => item.productId == productId);
      notifyListeners();
    } catch (e) {
      print("Error removing from cart: $e");
    }
  }

  // Clear the cart
  void clearCart() {
    _cart = [];
    notifyListeners();
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
        await addToCart(cartItem);
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
}