import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/cart_model.dart';
import '/utils/snackbar_helper.dart';

class CartProvider with ChangeNotifier {
  List<CartModel> _cart = [];

  List<CartModel> get cart => _cart;
  List<CartModel> get items => _cart; // For compatibility

  // ✅ Add calculated properties
  double get subtotal {
    return _cart.fold(0.0, (sum, item) {
      final price = item.productPrice ?? 0.0;
      final quantity = item.quantity;
      return sum + (price * quantity);
    });
  }

  double get shippingFee {
    return _cart.isNotEmpty ? 5.99 : 0.0;
  }

  double get tax {
    return subtotal * 0.1; // 10% tax
  }

  double get total {
    return subtotal + shippingFee + tax;
  }

  int get itemCount {
    return _cart.fold(0, (sum, item) => sum + item.quantity);
  }

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

  // ✅ Add the missing removeFromCartById method
  Future<void> removeFromCartById(String cartItemId) async {
    try {
      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(cartItemId)
          .delete();

      // Remove from local cart
      _cart.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
      
      print('✅ Item removed from cart successfully');
    } catch (e) {
      print('❌ Error removing item from cart: $e');
      throw e;
    }
  }

  // ✅ Add updateQuantity method if it's also missing
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        // Remove item if quantity is 0 or less
        await removeFromCartById(cartItemId);
        return;
      }

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(cartItemId)
          .update({'quantity': newQuantity});

      // Update locally
      final index = _cart.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        _cart[index] = _cart[index].copyWith(quantity: newQuantity);
        notifyListeners();
      }
      
      print('✅ Quantity updated successfully');
    } catch (e) {
      print('❌ Error updating quantity: $e');
      throw e;
    }
  }

  // ✅ Enhanced validateCartForCheckout method in CartProvider:

  bool validateCartForCheckout() {
    List<String> issues = [];
    
    for (var item in _cart) {
      final productName = item.productName ?? 'Unknown Product';
      
      // Check for missing or empty seller ID
      if (item.sellerId == null || item.sellerId!.trim().isEmpty) {
        issues.add('Missing seller ID for $productName');
        continue;
      }
      
      // Check for missing product ID
      if (item.productId == null || item.productId!.trim().isEmpty) {
        issues.add('Missing product ID for $productName');
        continue;
      }
      
      // Check for zero or negative price
      if (item.productPrice == null || item.productPrice! <= 0) {
        issues.add('Invalid price for $productName');
        continue;
      }
      
      // Check for zero quantity
      if (item.quantity <= 0) {
        issues.add('Invalid quantity for $productName');
        continue;
      }
    }
    
    if (issues.isNotEmpty) {
      print('❌ Cart validation failed:');
      for (String issue in issues) {
        print('  - $issue');
      }
      return false;
    }
    
    print('✅ Cart validation passed for ${_cart.length} items');
    return true;
  }

  // ✅ Add method to get validation issues for UI display
  List<String> getCartValidationIssues() {
    List<String> issues = [];
    
    for (var item in _cart) {
      final productName = item.productName ?? 'Unknown Product';
      
      if (item.sellerId == null || item.sellerId!.trim().isEmpty) {
        issues.add('$productName is missing seller information');
      }
      
      if (item.productId == null || item.productId!.trim().isEmpty) {
        issues.add('$productName is missing product information');
      }
      
      if (item.productPrice == null || item.productPrice! <= 0) {
        issues.add('$productName has an invalid price');
      }
      
      if (item.quantity <= 0) {
        issues.add('$productName has an invalid quantity');
      }
    }
    
    return issues;
  }

  // ✅ Add this method to CartProvider to update cart items with seller IDs:

  /// Update all cart items to include seller information
  Future<void> updateCartItemsWithSellerInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get all cart items for the user
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('carts')
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      bool updatesNeeded = false;

      for (var cartDoc in cartSnapshot.docs) {
        final cartData = cartDoc.data();
        final productId = cartData['productId'];
        
        // Check if seller info is missing
        if (cartData['sellerId'] == null || 
            cartData['sellerId'] == '' ||
            cartData['sellerName'] == null ||
            cartData['sellerName'] == '') {
          
          // Fetch product details to get seller info
          try {
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(productId)
                .get();
                
            if (productDoc.exists) {
              final productData = productDoc.data()!;
              final sellerId = productData['sellerId'];
              final sellerName = productData['sellerName'] ?? 'Unknown Seller';
              
              if (sellerId != null && sellerId.toString().trim().isNotEmpty) {
                // Update cart item with seller info
                batch.update(cartDoc.reference, {
                  'sellerId': sellerId,
                  'sellerName': sellerName,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                updatesNeeded = true;
                
                print('✅ Updated cart item ${cartData['productName']} with seller: $sellerName');
              } else {
                print('⚠️ Product ${cartData['productName']} has no valid seller ID');
              }
            }
          } catch (e) {
            print('❌ Error fetching product $productId: $e');
          }
        }
      }
      
      if (updatesNeeded) {
        await batch.commit();
        // Refresh cart after updates
        await fetchCart(user.uid);
        print('✅ Cart items updated with seller information');
      } else {
        print('ℹ️ All cart items already have seller information');
      }
      
    } catch (e) {
      print('❌ Error updating cart with seller info: $e');
      throw e;
    }
  }
}