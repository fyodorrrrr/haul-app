import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../screens/buyer/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String? userId; // Add optional userId parameter
  
  const ProductCard({
    Key? key,
    required this.product,
    this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current user ID if not provided
    final currentUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              product: product,
              userId: currentUserId, // Pass userId to ProductDetailsScreen
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image - Fixed to use images array
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[100], // Add background color for better loading state
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first, // Fixed: Changed from imageUrl to images.first
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported, 
                                  size: 40, 
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported, 
                              size: 40, 
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            
            // Product Info - Fixed with proper constraints
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name - Fixed overflow
                    Flexible(
                      child: Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Brand if available - Fixed overflow
                    if (product.brand.isNotEmpty) 
                      Flexible(
                        child: Text(
                          product.brand,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // Enhanced Price Display - Fixed: Changed from 'price' to 'sellingPrice'
                    Row(
                      children: [
                        if (product.salePrice != null) ...[
                          // Show original price with strikethrough
                          Text(
                            '₱${product.sellingPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Show sale price
                          Text(
                            '₱${product.salePrice!.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ] else ...[
                          // Show regular selling price
                          Text(
                            '₱${product.sellingPrice.toStringAsFixed(2)}', // Fixed: Changed from 'price' to 'sellingPrice'
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Enhanced Stock and Category Display - Fixed: Changed from 'stock' to 'currentStock'
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Category instead of condition (more relevant for thrift shopping)
                          Flexible(
                            child: Text(
                              product.category,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Enhanced stock status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getStockColor(product).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getStockColor(product),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _getStockText(product),
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: _getStockColor(product),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get stock status color
  Color _getStockColor(Product product) {
    if (product.currentStock <= 0) return Colors.red; // Fixed: Changed from 'stock' to 'currentStock'
    if (product.isLowStock) return Colors.orange; // Use the enhanced model's isLowStock property
    return Colors.green;
  }

  // Helper method to get stock status text
  String _getStockText(Product product) {
    if (product.currentStock <= 0) return 'Out'; // Fixed: Changed from 'stock' to 'currentStock'
    if (product.isLowStock) return 'Low'; // Use the enhanced model's isLowStock property
    return 'Stock';
  }
}