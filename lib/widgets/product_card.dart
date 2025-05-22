import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product_model.dart';
import '../screens/buyer/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  
  const ProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
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
            // Product Image - Fixed aspect ratio
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  image: product.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.imageUrl.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.image_not_supported, 
                          size: 40, 
                          color: Colors.grey[400],
                        ),
                      )
                    : null,
              ),
            ),
            
            // Product Info - Fixed with proper constraints
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name - Fixed overflow
                    Flexible(
                      child: Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13, // Slightly smaller font
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2, // Allow 2 lines instead of 1
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
                            fontSize: 11, // Smaller font
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // Product Price - Always visible
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 15, // Slightly smaller
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Stock status or condition - Fixed with Flexible
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              product.condition,
                              style: GoogleFonts.poppins(
                                fontSize: 11, // Smaller font
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Color dot for stock status
                          Container(
                            width: 6, // Smaller dot
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: product.stock > 0 ? Colors.green : Colors.red,
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
}