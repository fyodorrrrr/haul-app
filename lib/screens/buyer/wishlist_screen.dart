import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/providers/wishlist_providers.dart';
import '/providers/cart_providers.dart'; // Import CartProvider
import '/providers/user_profile_provider.dart'; // Import UserProfileProvider
import '/models/wishlist_model.dart';
import '/models/cart_model.dart';
import '/models/product.dart';
import '/screens/buyer/product_details_screen.dart'; // Make sure this path is correct!
import '/widgets/not_logged_in.dart'; // Import NotLoggedInScreen

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        // Show NotLoggedInScreen if user is not logged in
        if (!userProfileProvider.isProfileLoaded) {
          return const NotLoggedInScreen(
            message: 'Please log in to view your wishlist',
            icon: Icons.favorite_border,
          );
        }

        // Show wishlist content if user is logged in
        return Consumer<WishlistProvider>(
          builder: (context, wishlistProvider, child) {
            final cartProvider = Provider.of<CartProvider>(context); // Access CartProvider

            if (wishlistProvider.wishlist.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your wishlist is empty',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                    child: Text(
                      'Your Wishlist',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Stats bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(wishlistProvider.wishlist.length.toString(), 'Items'),
                        _buildDivider(),
                        _buildStat('2', 'On sale'),
                        _buildDivider(),
                        _buildStat('3', 'Recently added'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sorting options
                  Row(
                    children: [
                      Text(
                        'Sort by:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Recently Added',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Wishlist Items
                  Expanded(
                    child: ListView.builder(
                      itemCount: wishlistProvider.wishlist.length,
                      itemBuilder: (context, index) {
                        final wishlistItem = wishlistProvider.wishlist[index];
                        return _buildWishlistItem(context, wishlistItem, wishlistProvider, cartProvider);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildWishlistItem(
    BuildContext context,
    WishlistModel wishlistItem,
    WishlistProvider wishlistProvider,
    CartProvider cartProvider,
  ) {
    final isInCart = cartProvider.isInCart(wishlistItem.productId);

    return GestureDetector(
      onTap: () {
        // Navigate to product details screen
        _navigateToProductDetails(context, wishlistItem.productId);
      },
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image (now tappable as part of the whole container)
            Container(
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                image: wishlistItem.productImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(wishlistItem.productImage),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: wishlistItem.productImage.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade500,
                        size: 24,
                      ),
                    )
                  : null,
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      wishlistItem.productName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price with improved responsive behavior for high values
                        Expanded(  // Use Expanded instead of Flexible for better space distribution
                          child: Text(
                            '\$${wishlistItem.productPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: wishlistItem.productPrice >= 10000 ? 14 : 16,  // Reduce font size for very large numbers
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Cart action button with shorter text
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isInCart ? Colors.red.shade700 : Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (isInCart) {
                                // Remove from cart if already in cart
                                cartProvider.removeFromCart(wishlistItem.productId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${wishlistItem.productName} removed from cart',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                // Add to cart if not in cart
                                cartProvider.addToCart(
                                  CartModel(
                                    productId: wishlistItem.productId,
                                    userId: wishlistItem.userId,
                                    sellerId: '', // You may need to add seller ID if required
                                    productName: wishlistItem.productName,
                                    imageURL: wishlistItem.productImage,
                                    productPrice: wishlistItem.productPrice,
                                    addedAt: DateTime.now(),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${wishlistItem.productName} added to cart!',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              isInCart ? 'Remove' : 'Add to Cart',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Remove from wishlist button
            Container(
              width: 40,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 12.0, right: 12.0),
              child: IconButton(
                onPressed: () {
                  wishlistProvider.removeFromWishlist(
                    wishlistItem.productId, 
                    wishlistItem.userId,
                  );
                },
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this new method to your class to handle navigation
  void _navigateToProductDetails(BuildContext context, String productId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
      
      // Fetch product details from Firestore
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (productDoc.exists) {
        final productData = productDoc.data()!;
        productData['id'] = productId; // Make sure ID is included
        
        // Create a Product object
        final product = Product.fromMap(productData);
        
        // Navigate to product detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      } else {
        // Show error if product not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product not available',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if error occurs
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load product details',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      print('Error loading product details: $e');
    }
  }
}