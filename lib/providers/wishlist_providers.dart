import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/wishlist_model.dart';
import '/utils/snackbar_helper.dart';

class WishlistProvider with ChangeNotifier {
  List<WishlistModel> _wishlist = [];

  List<WishlistModel> get wishlist => _wishlist;

  // Fetch wishlist from Firestore
  Future<void> fetchWishlist(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .get();

      _wishlist = snapshot.docs
          .map((doc) => WishlistModel.fromMap(doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      print("Error fetching wishlist: $e");
    }
  }

  // Add a product to wishlist
  Future<void> addToWishlist(WishlistModel wishlistItem) async {
    try {
      await FirebaseFirestore.instance
          .collection('wishlists')
          .add(wishlistItem.toMap());
      _wishlist.add(wishlistItem);
      notifyListeners();
    } catch (e) {
      print("Error adding to wishlist: $e");
    }
  }

  // Remove a product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('productId', isEqualTo: productId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      _wishlist.removeWhere((item) => item.productId == productId);
      notifyListeners();
    } catch (e) {
      print("Error removing from wishlist: $e");
    }
  }

  // Check if a product is in the wishlist
  bool isInWishlist(String productId) {
    return _wishlist.any((item) => item.productId == productId);
  }

  // Handle wishlist logic
  Future<void> handleWishlist({
    required BuildContext context,
    required String productId,
    required String userId,
    required WishlistModel wishlistItem,
    required bool isInWishlist,
  }) async {
    try {
      if (isInWishlist) {
        await removeFromWishlist(productId);
        SnackBarHelper.showSnackBar(
          context,
          'Removed from wishlist',
        );
      } else {
        await addToWishlist(wishlistItem);
        SnackBarHelper.showSnackBar(
          context,
          'Added to wishlist',
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

  // Clear the wishlist
  void clearWishlist() {
    _wishlist = [];
    notifyListeners();
  }
}


