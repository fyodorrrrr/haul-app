import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '/providers/wishlist_providers.dart';
import '/providers/cart_providers.dart';
import '/providers/user_profile_provider.dart';
import '/models/wishlist_model.dart';
import '/models/cart_model.dart';
import '/models/product.dart';
import '/screens/buyer/product_details_screen.dart';
import '/widgets/not_logged_in.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  String _sortBy = 'recent';
  bool _isSelectionMode = false;
  Set<String> _selectedItems = {};

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        if (!userProfileProvider.isProfileLoaded) {
          return const NotLoggedInScreen(
            message: 'Please log in to view your wishlist',
            icon: Icons.favorite_border,
          );
        }

        return Consumer<WishlistProvider>(
          builder: (context, wishlistProvider, child) {
            final cartProvider = Provider.of<CartProvider>(context);
            final filteredItems = _getFilteredAndSortedItems(wishlistProvider);

            return Scaffold(
              appBar: _buildAppBar(wishlistProvider, cartProvider),
              body: _buildBody(filteredItems, wishlistProvider, cartProvider),
            );
          },
        );
      },
    );
  }

  // ✅ Enhanced app bar with search and selection
  PreferredSizeWidget _buildAppBar(WishlistProvider wishlistProvider, CartProvider cartProvider) {
    return AppBar(
      title: _isSelectionMode 
          ? Text('${_selectedItems.length} selected')
          : Text('Your Wishlist'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined),
            onPressed: () => _moveSelectedToCart(wishlistProvider, cartProvider),
            tooltip: 'Move to Cart',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () => _removeSelectedItems(wishlistProvider),
            tooltip: 'Remove Selected',
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: _exitSelectionMode,
            tooltip: 'Cancel',
          ),
        ],
      ],
    );
  }

  // ✅ Enhanced body with stats and filters
  Widget _buildBody(List<WishlistModel> items, WishlistProvider provider, CartProvider cartProvider) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your wishlist...', style: GoogleFonts.poppins()),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _refreshWishlist(provider),
      child: Column(
        children: [
          _buildStatsAndFilters(provider),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildEnhancedWishlistItem(item, provider, cartProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Enhanced stats section with overflow fixes
  Widget _buildStatsAndFilters(WishlistProvider provider) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // ✅ Stats cards with responsive layout
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '${provider.totalItems}',
                      'Total Items',
                      Icons.favorite,
                      Colors.red,
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Colors.grey.shade300,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      '${provider.recentlyAddedCount}',
                      'Recent',
                      Icons.schedule,
                      Colors.orange,
                    ),
                  ),
                  Container(
                    width: 1,
                    color: Colors.grey.shade300,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      '\$${provider.totalWishlistValue.toStringAsFixed(0)}',
                      'Total Value',
                      Icons.monetization_on,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // ✅ Sort dropdown with responsive design
          Row(
            children: [
              Icon(Icons.sort, size: 18, color: Colors.grey.shade600),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      onChanged: (value) => setState(() => _sortBy = value!),
                      isExpanded: true,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'recent',
                          child: Text('Recently Added'),
                        ),
                        DropdownMenuItem(
                          value: 'price_low',
                          child: Text('Price: Low to High'),
                        ),
                        DropdownMenuItem(
                          value: 'price_high',
                          child: Text('Price: High to Low'),
                        ),
                        DropdownMenuItem(
                          value: 'name',
                          child: Text('Name A-Z'),
                        ),
                        DropdownMenuItem(
                          value: 'brand',
                          child: Text('Brand'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Enhanced wishlist item with fixed overflow issues
  Widget _buildEnhancedWishlistItem(
    WishlistModel item, 
    WishlistProvider wishlistProvider, 
    CartProvider cartProvider
  ) {
    final isSelected = _selectedItems.contains(item.productId);
    final isInCart = cartProvider.isInCart(item.productId);
    final hasDiscount = item.hasDiscount;

    return GestureDetector(
      onTap: () => _isSelectionMode 
          ? _toggleSelection(item.productId)
          : _navigateToProductDetails(context, item.productId),
      onLongPress: () => _enterSelectionMode(item.productId),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: isSelected 
              ? Border.all(color: Colors.blue, width: 2)
              : null,
        ),
        child: Column(
          children: [
            // ✅ Fixed main content with proper constraints
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ Product image with fixed dimensions
                  _buildProductImage(item, hasDiscount, isSelected),
                  
                  // ✅ Product details with flexible layout
                  Expanded(
                    child: _buildProductDetails(item, hasDiscount),
                  ),
                  
                  // ✅ Action buttons with proper sizing
                  if (!_isSelectionMode)
                    _buildActionButtons(item, wishlistProvider),
                ],
              ),
            ),
            
            // ✅ Fixed action bar
            if (!_isSelectionMode)
              _buildActionBar(item, cartProvider, wishlistProvider, isInCart),
          ],
        ),
      ),
    );
  }

  // ✅ Separate method for product image
  Widget _buildProductImage(WishlistModel item, bool hasDiscount, bool isSelected) {
    return Container(
      width: 100,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(0),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
            ),
            child: item.productImage.isNotEmpty
                ? Image.network(
                    item.productImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade100,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                  ),
          ),
          
          // ✅ Discount badge with better positioning
          if (hasDiscount)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(((item.productPrice - item.salePrice!) / item.productPrice) * 100).round()}% OFF',
                  style: GoogleFonts.poppins(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          
          // ✅ Selection indicator with better positioning
          if (_isSelectionMode)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: 1.5,
                  ),
                ),
                child: isSelected 
                    ? Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Separate method for product details with overflow fixes
  Widget _buildProductDetails(WishlistModel item, bool hasDiscount) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ Product name with overflow handling
          Flexible(
            child: Text(
              item.productName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // ✅ Brand with conditional display
          if (item.brand?.isNotEmpty == true) ...[
            SizedBox(height: 4),
            Text(
              item.brand!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          SizedBox(height: 8),
          
          // ✅ Price section with responsive layout
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price row
              if (hasDiscount) ...[
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '\$${item.salePrice!.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '\$${item.productPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  '\$${item.productPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
              
              SizedBox(height: 4),
              
              // ✅ Time added with overflow handling
              Text(
                'Added ${_formatTimeAgo(item.addedAt)}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ Separate method for action buttons with fixed width
  Widget _buildActionButtons(WishlistModel item, WishlistProvider wishlistProvider) {
    return Container(
      width: 44,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: () => _removeFromWishlist(item, wishlistProvider),
              icon: Icon(Icons.close, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                padding: EdgeInsets.zero,
                minimumSize: Size(36, 36),
                maximumSize: Size(36, 36),
              ),
            ),
          ),
          
          SizedBox(height: 8),
          
          Container(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: () => _shareProduct(item),
              icon: Icon(Icons.share, size: 16),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue,
                padding: EdgeInsets.zero,
                minimumSize: Size(36, 36),
                maximumSize: Size(36, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Separate method for action bar with responsive design
  Widget _buildActionBar(
    WishlistModel item, 
    CartProvider cartProvider, 
    WishlistProvider wishlistProvider,
    bool isInCart
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // ✅ Flexible cart button
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: () => isInCart 
                    ? _removeFromCart(item, cartProvider)
                    : _addToCart(item, cartProvider, wishlistProvider),
                icon: Icon(
                  isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                  size: 14,
                ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isInCart ? 'Remove' : 'Add to Cart',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInCart ? Colors.red : Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // ✅ View button with fixed width
          SizedBox(
            width: 60,
            height: 36,
            child: OutlinedButton(
              onPressed: () => _navigateToProductDetails(context, item.productId),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'View',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Enhanced stat card with responsive design
  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          
          SizedBox(height: 6),
          
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
          ),
          
          SizedBox(height: 2),
          
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 24),
          Text(
            'Your wishlist is empty',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start adding items you love!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to explore screen
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/main', 
                (route) => false,
                arguments: {'initialIndex': 1}, // Explore tab
              );
            },
            icon: Icon(Icons.explore),
            label: Text('Browse Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  List<WishlistModel> _getFilteredAndSortedItems(WishlistProvider provider) {
    List<WishlistModel> items = provider.wishlist;

    // Apply sorting
    items = provider.getSortedItems(_sortBy);
    
    return items;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  // Action methods
  Future<void> _addToCart(WishlistModel item, CartProvider cartProvider, WishlistProvider wishlistProvider) async {
    try {
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
      
      await cartProvider.addToCart(cartItem);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.productName} added to cart!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/main', 
                (route) => false,
                arguments: {'initialIndex': 2}, // Cart tab
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeFromCart(WishlistModel item, CartProvider cartProvider) async {
    try {
      await cartProvider.removeFromCart(item.productId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.productName} removed from cart'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove from cart'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Keep your existing _navigateToProductDetails method unchanged
  void _navigateToProductDetails(BuildContext context, String productId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
      
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      
      Navigator.pop(context);
      
      if (productDoc.exists) {
        final productData = productDoc.data()!;
        productData['id'] = productId;
        
        final product = Product.fromMap(productData);
        
        final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
        final userId = userProfileProvider.userProfile?.uid;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              product: product,
              userId: userId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load product details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Additional helper methods
  void _enterSelectionMode(String productId) {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.add(productId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  void _toggleSelection(String productId) {
    setState(() {
      if (_selectedItems.contains(productId)) {
        _selectedItems.remove(productId);
      } else {
        _selectedItems.add(productId);
      }
      
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _refreshWishlist(WishlistProvider provider) async {
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final userId = userProfileProvider.userProfile?.uid;
    
    if (userId != null) {
      await provider.fetchWishlist(userId);
      await provider.syncWithProductUpdates();
    }
  }

  Widget? _buildFloatingActionButton(WishlistProvider provider) {
    return null;
  }

  // Additional methods for enhanced functionality
  Future<void> _removeFromWishlist(WishlistModel item, WishlistProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove from Wishlist'),
        content: Text('Remove "${item.productName}" from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.removeFromWishlist(item.productId, item.userId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.productName} removed from wishlist'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () => provider.addToWishlist(item),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from wishlist'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareProduct(WishlistModel item) {
    Share.share(
      'Check out this ${item.productName} for ${item.displayPrice}! Found it on Haul app.',
      subject: 'Great find on Haul App!',
    );
  }

  void _shareWishlist(WishlistProvider provider) {
    final itemCount = provider.wishlist.length;
    final totalValue = provider.totalWishlistValue;
    
    Share.share(
      'Check out my wishlist on Haul! I have $itemCount items worth \$${totalValue.toStringAsFixed(2)}. Join me in discovering amazing thrift finds!',
      subject: 'My Haul Wishlist',
    );
  }

  Future<void> _moveSelectedToCart(WishlistProvider wishlistProvider, CartProvider cartProvider) async {
    // Implementation for moving selected items to cart
  }

  Future<void> _removeSelectedItems(WishlistProvider provider) async {
    // Implementation for removing selected items
  }
}