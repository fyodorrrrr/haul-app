import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/wishlist_providers.dart';
import '/providers/cart_providers.dart'; // Import CartProvider
import '/providers/user_profile_provider.dart'; // Import UserProfileProvider
import '/models/wishlist_model.dart';
import '/models/cart_model.dart';
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
            final productCount = wishlistProvider.wishlist.length;
            final recentlyAddedProducts = wishlistProvider.wishlist.where((item) => item.isRecent).toList();

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
                        _buildStat(productCount.toString(), 'Items'),
                        _buildDivider(),
                        _buildStat(recentlyAddedProducts.length.toString(), 'Recently added'),
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
    CartProvider cartProvider, // Pass CartProvider
  ) {
    final isInCart = cartProvider.isInCart(wishlistItem.productId); // Check if item is in cart

    return Container(
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
          // Product Image
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
                  : null, // Fallback if no image is provided
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${wishlistItem.productPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 5),
                        decoration: BoxDecoration(
                          color: isInCart ? Colors.grey : Colors.black, // Change color if in cart
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                            onTap: isInCart
                              ? null // Disable button if already in cart
                              : () {
                                  // Add to Cart Logic
                                  cartProvider.addToCart(
                                    CartModel(
                                      productId: wishlistItem.productId,
                                      userId: wishlistItem.userId,
                                      productName: wishlistItem.productName,
                                      imageURL: wishlistItem.productImage,
                                      productPrice: wishlistItem.productPrice,
                                      addedAt: DateTime.now(),
                                    ),
                                  );

                                  // Show confirmation message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${wishlistItem.productName} added to cart!',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                            child: Text(
                              isInCart ? 'Added' : 'Add to Cart', // Dynamic button text
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                            ),
                          ),
                        ),
                          )
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Remove button
          Container(
            width: 40,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 12.0, right: 12.0),
            child: IconButton(
              onPressed: () {
                // Remove item from wishlist
                wishlistProvider.removeFromWishlist(wishlistItem.productId,
                 wishlistItem.userId,);
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
    );
  }
}