import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/wishlist_model.dart';
import '/models/cart_model.dart';
import '/utils/snackbar_helper.dart';

class WishlistProvider with ChangeNotifier {
  List<WishlistModel> _wishlist = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<WishlistModel> get wishlist => _wishlist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // ✅ Enhanced analytics getters
  int get totalItems => _wishlist.length;
  
  int get recentlyAddedCount => _wishlist.where((item) => 
    DateTime.now().difference(item.addedAt).inDays <= 7).length;
  
  double get totalWishlistValue => _wishlist.fold(0.0, 
    (sum, item) => sum + item.effectivePrice);
  
  List<WishlistModel> get recentlyAdded => _wishlist.where((item) => 
    DateTime.now().difference(item.addedAt).inDays <= 7).toList();
  
  List<WishlistModel> get onSaleItems => _wishlist.where((item) => 
    item.hasDiscount).toList();

  Set<String> get brandNames => _wishlist
      .where((item) => item.brand?.isNotEmpty == true)
      .map((item) => item.brand!)
      .toSet();

  // ✅ Enhanced fetch with better error handling
  Future<void> fetchWishlist(String userId) async {
    try {
      _setLoading(true);
      _error = null;

      final snapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('userId', isEqualTo: userId)
          .orderBy('addedAt', descending: true)
          .get();

      _wishlist = snapshot.docs
          .map((doc) => WishlistModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
          
      notifyListeners();
      print('✅ Wishlist loaded: ${_wishlist.length} items');
    } catch (e) {
      _error = 'Failed to load wishlist: $e';
      print('❌ Error fetching wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Enhanced add with product details fetching
  Future<void> addToWishlist(WishlistModel wishlistItem) async {
    try {
      _setLoading(true);
      
      // Check if item already exists
      if (isInWishlist(wishlistItem.productId)) {
        throw Exception('Item already in wishlist');
      }
      
      // ✅ Fetch additional product details if missing
      WishlistModel enhancedItem = wishlistItem;
      if (wishlistItem.sellerId == null || wishlistItem.brand == null) {
        enhancedItem = await _enhanceWishlistItem(wishlistItem);
      }
      
      // Add to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('wishlists')
          .add(enhancedItem.toMap());
      
      // Add to local list with generated ID
      final newItem = enhancedItem.copyWith(id: docRef.id);
      _wishlist.insert(0, newItem); // Add to beginning for recent items first
      notifyListeners();
      
      print('✅ Added to wishlist: ${enhancedItem.productName}');
    } catch (e) {
      _error = e.toString();
      print('❌ Error adding to wishlist: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Enhanced remove with better feedback
  Future<void> removeFromWishlist(String productId, String userId) async {
    try {
      _setLoading(true);
      
      // Find the item in local list
      final itemIndex = _wishlist.indexWhere(
        (item) => item.productId == productId && item.userId == userId
      );
      
      if (itemIndex == -1) {
        throw Exception('Item not found in wishlist');
      }
      
      final item = _wishlist[itemIndex];
      
      // Remove from Firestore
      if (item.id != null) {
        await FirebaseFirestore.instance
            .collection('wishlists')
            .doc(item.id!)
            .delete();
      } else {
        // Fallback: query by productId and userId
        final snapshot = await FirebaseFirestore.instance
            .collection('wishlists')
            .where('productId', isEqualTo: productId)
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
      }
      
      // Remove from local list
      _wishlist.removeAt(itemIndex);
      notifyListeners();
      
      print('✅ Removed from wishlist: ${item.productName}');
    } catch (e) {
      _error = e.toString();
      print('❌ Error removing from wishlist: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Enhanced handle wishlist with better UX
  Future<void> handleWishlist({
    required BuildContext context,
    required String productId,
    required String userId,
    required WishlistModel wishlistItem,
    bool? isInWishlist,
  }) async {
    try {
      final currentlyInWishlist = isInWishlist ?? this.isInWishlist(productId);
      
      if (currentlyInWishlist) {
        await removeFromWishlist(productId, userId);
        SnackBarHelper.showSnackBar(
          context,
          'Removed from wishlist',
        );
      } else {
        await addToWishlist(wishlistItem);
        SnackBarHelper.showSnackBar(
          context,
          'Added to wishlist ❤️',
          isSuccess: true,
        );
      }
    } catch (e) {
      SnackBarHelper.showSnackBar(
        context,
        e.toString().contains('already in wishlist') 
            ? 'Item is already in your wishlist'
            : 'An error occurred. Please try again.',
        isError: true,
      );
    }
  }

  // ✅ New: Bulk operations
  Future<void> removeMultipleItems(List<String> productIds, String userId) async {
    try {
      _setLoading(true);
      
      final batch = FirebaseFirestore.instance.batch();
      final itemsToRemove = <WishlistModel>[];
      
      for (String productId in productIds) {
        final item = _wishlist.firstWhere(
          (item) => item.productId == productId && item.userId == userId,
          orElse: () => throw Exception('Item not found: $productId'),
        );
        
        if (item.id != null) {
          batch.delete(FirebaseFirestore.instance
              .collection('wishlists')
              .doc(item.id!));
        }
        
        itemsToRemove.add(item);
      }
      
      await batch.commit();
      
      // Remove from local list
      for (var item in itemsToRemove) {
        _wishlist.remove(item);
      }
      
      notifyListeners();
      print('✅ Removed ${itemsToRemove.length} items from wishlist');
    } catch (e) {
      _error = e.toString();
      print('❌ Error removing multiple items: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ New: Move to cart functionality
  Future<void> moveToCart(String productId, CartProvider, cartProvider) async {
    try {
      final item = _wishlist.firstWhere(
        (item) => item.productId == productId,
        orElse: () => throw Exception('Item not found in wishlist'),
      );
      
      // Create cart item
      final cartItem = CartModel(
        productId: item.productId,
        userId: item.userId,
        sellerId: item.sellerId ?? '',
        productName: item.productName,
        imageURL: item.productImage,
        productPrice: item.effectivePrice,
        quantity: 1,
        addedAt: DateTime.now(),
        sellerName: item.sellerName,
        brand: item.brand,
        size: item.size,
        condition: item.condition,
      );
      
      // Add to cart
      await cartProvider.addToCart(cartItem);
      
      // Remove from wishlist
      await removeFromWishlist(item.productId, item.userId);
      
      print('✅ Moved ${item.productName} from wishlist to cart');
    } catch (e) {
      _error = e.toString();
      print('❌ Error moving to cart: $e');
      rethrow;
    }
  }

  // ✅ New: Search and filter methods
  List<WishlistModel> searchItems(String query) {
    if (query.isEmpty) return _wishlist;
    
    final lowercaseQuery = query.toLowerCase();
    return _wishlist.where((item) => 
      item.productName.toLowerCase().contains(lowercaseQuery) ||
      (item.brand?.toLowerCase().contains(lowercaseQuery) ?? false) ||
      (item.sellerName?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }

  List<WishlistModel> filterByBrand(String brand) {
    return _wishlist.where((item) => 
      item.brand?.toLowerCase() == brand.toLowerCase()).toList();
  }

  List<WishlistModel> filterByPriceRange(double minPrice, double maxPrice) {
    return _wishlist.where((item) => 
      item.effectivePrice >= minPrice && item.effectivePrice <= maxPrice).toList();
  }

  List<WishlistModel> getSortedItems(String sortBy) {
    final items = List<WishlistModel>.from(_wishlist);
    
    switch (sortBy) {
      case 'recent':
        items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case 'price_low':
        items.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_high':
        items.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'name':
        items.sort((a, b) => a.productName.compareTo(b.productName));
        break;
      case 'brand':
        items.sort((a, b) => (a.brand ?? '').compareTo(b.brand ?? ''));
        break;
    }
    
    return items;
  }

  // ✅ Helper methods
  bool isInWishlist(String productId) {
    return _wishlist.any((item) => item.productId == productId);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearWishlist() {
    _wishlist = [];
    notifyListeners();
  }

  // ✅ Enhanced product details fetching
  Future<WishlistModel> _enhanceWishlistItem(WishlistModel item) async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(item.productId)
          .get();
          
      if (!productDoc.exists) {
        return item; // Return original if product not found
      }
      
      final productData = productDoc.data()!;
      
      return item.copyWith(
        sellerId: productData['sellerId'],
        sellerName: productData['sellerName'],
        brand: productData['brand'],
        condition: productData['condition'],
        size: productData['size'],
        isOnSale: productData['isOnSale'],
        salePrice: productData['salePrice']?.toDouble(),
        originalStock: productData['currentStock']?.toInt(),
      );
    } catch (e) {
      print('Warning: Could not enhance wishlist item: $e');
      return item; // Return original on error
    }
  }

  // ✅ New: Sync with current product data
  Future<void> syncWithProductUpdates() async {
    if (_wishlist.isEmpty) return;
    
    try {
      _setLoading(true);
      
      final updatedItems = <WishlistModel>[];
      final batch = FirebaseFirestore.instance.batch();
      
      for (var item in _wishlist) {
        try {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(item.productId)
              .get();
              
          if (productDoc.exists) {
            final productData = productDoc.data()!;
            final currentPrice = (productData['price'] ?? item.productPrice).toDouble();
            final salePrice = productData['salePrice']?.toDouble();
            
            // Check if price has changed
            if (currentPrice != item.productPrice || 
                salePrice != item.salePrice) {
              
              final updatedItem = item.copyWith(
                productPrice: currentPrice,
                salePrice: salePrice,
                isOnSale: productData['isOnSale'],
              );
              
              updatedItems.add(updatedItem);
              
              // Update in Firestore if we have the document ID
              if (item.id != null) {
                batch.update(
                  FirebaseFirestore.instance.collection('wishlists').doc(item.id!),
                  {
                    'productPrice': currentPrice,
                    'salePrice': salePrice,
                    'isOnSale': productData['isOnSale'],
                  },
                );
              }
            }
          }
        } catch (e) {
          print('Warning: Could not sync item ${item.productName}: $e');
        }
      }
      
      if (updatedItems.isNotEmpty) {
        await batch.commit();
        
        // Update local list
        for (var updatedItem in updatedItems) {
          final index = _wishlist.indexWhere((item) => item.id == updatedItem.id);
          if (index != -1) {
            _wishlist[index] = updatedItem;
          }
        }
        
        notifyListeners();
        print('✅ Synced ${updatedItems.length} wishlist items with current prices');
      }
    } catch (e) {
      print('❌ Error syncing wishlist: $e');
    } finally {
      _setLoading(false);
    }
  }
}


