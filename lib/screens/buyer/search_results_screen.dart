import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';
import 'product_details_screen.dart';
import '../../widgets/product_card.dart';
import '../../utils/currency_formatter.dart';

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
      
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();
          
      print('📦 SearchResults fetched: ${result.docs.length} products');
      
      final List<Product> allProducts = result.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              
              // FIXED: Handle Timestamp conversion here
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
              }
              if (data['updatedAt'] is Timestamp) {
                data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate();
              }
              
              return Product.fromMap(data);
            } catch (e) {
              print('❌ Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<Product>()
          .toList();
          
      final List<Product> filteredProducts = allProducts
          .where((product) {
            final name = product.name.toLowerCase();
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
                  // FIXED: Products grid with more conservative aspect ratio
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12), // FIXED: Reduced padding
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8, // FIXED: Increased to 0.8 for more height
                        mainAxisSpacing: 12, // FIXED: Reduced spacing
                        crossAxisSpacing: 12, // FIXED: Reduced spacing
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

  // FIXED: Completely overflow-proof product card
  Widget _buildProductCard(Product product) {
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image section - keep same
            SizedBox(
              height: 110,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 110, // FIXED: Reduced height
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported, 
                              size: 24,
                              color: Colors.grey[400],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported, 
                          size: 24,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
              ),
            ),
            
            // FIXED: Use Expanded instead of SizedBox for flexible height
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name - flexible
                    Expanded(
                      flex: 2,
                      child: Text(
                        product.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Price section - fixed height
                    SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          if (product.salePrice != null) ...[
                            // Original price with strikethrough
                            Text(
                              product.displaySellingPrice, // Using the new getter
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 2),
                            // Sale price
                            Expanded(
                              child: Text(
                                product.displaySalePrice, // Using the new getter
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.red,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else ...[
                            // Regular price
                            Expanded(
                              child: Text(
                                product.displayPrice, // Using the new getter
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Stock indicator - fixed height
                    SizedBox(
                      height: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Category (truncated)
                          Expanded(
                            child: Text(
                              product.category.length > 6 
                                ? '${product.category.substring(0, 6)}...' // FIXED: Even shorter truncation
                                : product.category,
                              style: GoogleFonts.poppins(
                                fontSize: 7,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.clip,
                            ),
                          ),
                          // Stock indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0), // FIXED: Minimal padding
                            decoration: BoxDecoration(
                              color: _getStockColor(product).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              _getStockText(product),
                              style: GoogleFonts.poppins(
                                fontSize: 6, // FIXED: Reduced from 7 to 6
                                fontWeight: FontWeight.w500,
                                color: _getStockColor(product),
                              ),
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

  // Helper methods for stock status
  Color _getStockColor(Product product) {
    if (product.currentStock <= 0) return Colors.red;
    if (product.isLowStock) return Colors.orange;
    return Colors.green;
  }

  String _getStockText(Product product) {
    if (product.currentStock <= 0) return 'Out';
    if (product.isLowStock) return 'Low';
    return 'Stock';
  }
}
