import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';
import 'product_details_screen.dart';
import '../../widgets/product_card.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  
  const SearchResultsScreen({
    Key? key,
    required this.query,
  }) : super(key: key);
  
  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Product> _searchResults = [];
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _performSearch();
  }
  
  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      String lowercaseQuery = widget.query.trim().toLowerCase();
      print('🔍 SearchResultsScreen searching for: "$lowercaseQuery"');
      
      // Use the SAME logic as your working home screen search
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get(); // Remove the problematic .where() clauses that require indexes
          
      print('📦 SearchResults fetched: ${result.docs.length} products');
      
      // Fixed Product.fromMap() call - Use client-side filtering (same as home screen)
      final List<Product> allProducts = result.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Add document ID to data
              return Product.fromMap(data); // Fixed: Use single parameter
            } catch (e) {
              print('❌ Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<Product>()
          .toList();
          
      // Apply the same filtering logic as your working search
      final List<Product> filteredProducts = allProducts
          .where((product) {
            final name = product.name.toLowerCase(); // Removed null check since enhanced model has non-nullable fields
            final brand = product.brand.toLowerCase();
            final category = product.category.toLowerCase();
            final description = product.description.toLowerCase();
            
            return name.contains(lowercaseQuery) || 
                   brand.contains(lowercaseQuery) || 
                   category.contains(lowercaseQuery) ||
                   description.contains(lowercaseQuery);
          })
          .toList();
          
      print('🎯 SearchResults filtered: ${filteredProducts.length} matches');
          
      setState(() {
        _searchResults = filteredProducts;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ SearchResults error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Results for "${widget.query}"',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading results',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _performSearch,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : _searchResults.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Results count header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Text(
                      '${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''} found',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  // Products grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_searchResults[index]);
                      },
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Get current user ID for product details screen
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(
              product: product,
              userId: userId,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image - Fixed to use images array
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first, // Use first image from array
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported, 
                            size: 50, 
                            color: Colors.grey[500]
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported, 
                        size: 50, 
                        color: Colors.grey[500]
                      ),
                    ),
              ),
            ),
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show effective price (sale price if available, otherwise selling price)
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
                              const SizedBox(width: 8),
                              // Show sale price
                              Text(
                                '₱${product.salePrice!.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ] else ...[
                              // Show regular selling price
                              Text(
                                '₱${product.sellingPrice.toStringAsFixed(2)}', // Fixed: Changed from 'price' to 'sellingPrice'
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        // Stock indicator
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStockColor(product).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStockText(product),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getStockColor(product),
                            ),
                          ),
                        ),
                      ],
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

  // Helper methods for stock status
  Color _getStockColor(Product product) {
    if (product.currentStock <= 0) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  String _getStockText(Product product) {
    if (product.currentStock <= 0) return 'Out of Stock';
    if (product.isLowStock) return 'Low Stock';
    return 'In Stock';
  }
}
