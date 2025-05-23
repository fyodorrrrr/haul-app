import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
import '/models/cart_model.dart';
import '/models/wishlist_model.dart';
import '/providers/cart_providers.dart';
import '/providers/wishlist_providers.dart';
import '/utils/snackbar_helper.dart';
import 'seller_public_profile_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  final String? userId;

  const ProductDetailsScreen({
    Key? key,
    required this.product,
    this.userId,
  }) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
    _incrementProductView();
  }

  Future<void> _incrementProductView() async {
    try {
      // Update product view count
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({
        'viewCount': FieldValue.increment(1),
      });

      // Update seller total view count
      await FirebaseFirestore.instance
          .collection('sellers')
          .doc(widget.product.sellerId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error updating view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isInWishlist = wishlistProvider.isInWishlist(widget.product.id);
    final isInCart = cartProvider.isInCart(widget.product.id);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, size),
          _buildProductDetails(),
          _buildSpecifications(),
          _buildDeliveryInfo(),
          SliverToBoxAdapter(child: _buildSellerSection(context)),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(context, wishlistProvider, cartProvider, isInWishlist, isInCart),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, Size size) {
    return SliverAppBar(
      expandedHeight: size.height * 0.5,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product-${widget.product.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Updated to use images array instead of imageUrl
              Image.network(
                widget.product.images.isNotEmpty 
                    ? widget.product.images.first 
                    : '', // Use first image or empty string
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error_outline, size: 32),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildProductDetails() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Show sale price if available, otherwise regular price
                    if (widget.product.salePrice != null) ...[
                      Text(
                        '₱${widget.product.sellingPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '₱${widget.product.salePrice!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '₱${widget.product.sellingPrice.toStringAsFixed(2)}', // Updated from price to sellingPrice
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stock status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStockColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStockColor()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStockIcon(), size: 16, color: _getStockColor()),
                  const SizedBox(width: 4),
                  Text(
                    _getStockText(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStockColor(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              'Description',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product.description,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSpecifications() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildSpecificationItem(Icons.category_outlined, 'Category', widget.product.category),
            _buildSpecificationItem(Icons.inventory_outlined, 'Subcategory', widget.product.subcategory),
            _buildSpecificationItem(Icons.branding_watermark_outlined, 'Brand', widget.product.brand),
            _buildSpecificationItem(Icons.qr_code, 'SKU', widget.product.sku),
            if (widget.product.variants.isNotEmpty) ...[
              _buildSpecificationItem(Icons.tune, 'Variants', '${widget.product.variants.length} available'),
            ],
            if (widget.product.weight > 0) ...[
              _buildSpecificationItem(Icons.scale, 'Weight', '${widget.product.weight} kg'),
            ],
            if (widget.product.dimensions.length > 0 || widget.product.dimensions.width > 0 || widget.product.dimensions.height > 0) ...[
              _buildSpecificationItem(
                Icons.straighten, 
                'Dimensions', 
                '${widget.product.dimensions.length} x ${widget.product.dimensions.width} x ${widget.product.dimensions.height} ${widget.product.dimensions.unit}'
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildDeliveryInfo() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_outlined, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stored at ${widget.product.location}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Contact seller for delivery arrangements',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerSection(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('sellers')
          .doc(widget.product.sellerId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const ListTile(
              leading: CircleAvatar(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Loading seller information...'),
            ),
          );
        }

        final Map<String, dynamic> sellerData = 
            snapshot.data?.data() as Map<String, dynamic>? ?? {};
        
        final String businessName = sellerData['businessName'] ?? widget.product.brand;
        final String? profileImageUrl = sellerData['profileImageUrl'];
        final String location = sellerData['address'] ?? 'No location';
        final bool isVerified = sellerData['isVerified'] ?? false;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sold by',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (widget.product.sellerId.isNotEmpty) {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => SellerPublicProfileScreen(
                          sellerId: widget.product.sellerId
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? Icon(Icons.store, color: Colors.grey[700])
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  businessName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified)
                                Icon(Icons.verified, 
                                  size: 16, 
                                  color: Colors.blue[700]
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, 
                                size: 14, 
                                color: Colors.grey[600]
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (sellerData['averageRating'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, 
                                  size: 14, 
                                  color: Colors.amber
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${sellerData['averageRating'].toStringAsFixed(1)} • ${sellerData['totalRatings'] ?? 0} reviews',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 6
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Visit Store',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons(BuildContext context, WishlistProvider wishlistProvider, CartProvider cartProvider, bool isInWishlist, bool isInCart) {
    final theme = Theme.of(context);
    final isOutOfStock = widget.product.currentStock <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Wishlist Button
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 16),
            child: OutlinedButton(
              onPressed: () {
                if (widget.userId == null) {
                  SnackBarHelper.showSnackBar(
                    context,
                    'Please log in to add items to your wishlist.', 
                    isError: true,
                  );
                  return;
                }
                wishlistProvider.handleWishlist(
                  context: context,
                  productId: widget.product.id,
                  userId: widget.userId!,
                  wishlistItem: WishlistModel(
                    productId: widget.product.id,
                    userId: widget.userId!,
                    productName: widget.product.name,
                    productImage: widget.product.images.isNotEmpty ? widget.product.images.first : '', // Updated
                    productPrice: widget.product.effectivePrice, // Use effective price (sale or regular)
                    addedAt: DateTime.now(),
                  ),
                  isInWishlist: isInWishlist,
                );
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist ? theme.colorScheme.error : theme.disabledColor,
              ),
            ),
          ),
          // Add/Remove Cart Button
          Expanded(
            child: ElevatedButton(
              onPressed: isOutOfStock ? null : () {
                if (widget.userId == null) {
                  SnackBarHelper.showSnackBar(
                    context,
                    'Please log in to manage your cart.', 
                    isError: true,
                  );
                  return;
                }
                cartProvider.handleAddToCart(
                  context: context,
                  productId: widget.product.id,
                  userId: widget.userId!,
                  cartItem: CartModel(
                    productId: widget.product.id,
                    userId: widget.userId!,
                    sellerId: widget.product.sellerId,
                    productName: widget.product.name,
                    imageURL: widget.product.images.isNotEmpty ? widget.product.images.first : '', // Updated
                    productPrice: widget.product.effectivePrice, // Use effective price
                    addedAt: DateTime.now(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutOfStock 
                    ? Colors.grey 
                    : (isInCart 
                        ? theme.colorScheme.error 
                        : theme.colorScheme.primary),
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                isOutOfStock 
                    ? 'Out of Stock'
                    : (isInCart ? 'Remove from Cart' : 'Add to Cart'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for stock status
  Color _getStockColor() {
    if (widget.product.currentStock <= 0) return Colors.red;
    if (widget.product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  IconData _getStockIcon() {
    if (widget.product.currentStock <= 0) return Icons.error;
    if (widget.product.isLowStock) return Icons.warning;
    return Icons.check_circle;
  }

  String _getStockText() {
    if (widget.product.currentStock <= 0) return 'Out of Stock';
    if (widget.product.isLowStock) return 'Low Stock (${widget.product.currentStock} left)';
    return 'In Stock (${widget.product.currentStock} available)';
  }
}