import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haul/models/product.dart';
import 'package:haul/screens/buyer/product_details_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandProductsScreen extends StatefulWidget {
  final String brandName;

  const BrandProductsScreen({Key? key, required this.brandName}) : super(key: key);

  @override
  _BrandProductsScreenState createState() => _BrandProductsScreenState();
}

class _BrandProductsScreenState extends State<BrandProductsScreen> {
  List<Product> brandProducts = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  String searchQuery = '';

  // Add these to your state variables
  String _sortBy = 'name'; // 'name', 'price_low', 'price_high', 'newest'

  @override
  void initState() {
    super.initState();
    fetchBrandProducts();
  }

  void _filterProducts(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredProducts = brandProducts;
      } else {
        filteredProducts = brandProducts
            .where((product) =>
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.category.toLowerCase().contains(query.toLowerCase()) ||
                product.subcategory.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> fetchBrandProducts() async {
    try {
      setState(() => isLoading = true);
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('brand', isEqualTo: widget.brandName)
          .where('isActive', isEqualTo: true)
          .get();

      final results = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      setState(() {
        brandProducts = results;
        filteredProducts = results; // Initialize filtered list
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching brand products: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ${widget.brandName} products'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: fetchBrandProducts,
            ),
          ),
        );
      }
    }
  }

  void _sortProducts() {
    filteredProducts.sort((a, b) {
      switch (_sortBy) {
        case 'price_low':
          return (a.salePrice ?? a.sellingPrice).compareTo(b.salePrice ?? b.sellingPrice);
        case 'price_high':
          return (b.salePrice ?? b.sellingPrice).compareTo(a.salePrice ?? a.sellingPrice);
        case 'newest':
          return b.createdAt.compareTo(a.createdAt);
        case 'name':
        default:
          return a.name.compareTo(b.name);
      }
    });
  }

  Widget _buildProductCard(Product product) {
    final imageUrl = product.images.isNotEmpty ? product.images[0] : '';
    final hasDiscount = product.salePrice != null && product.salePrice! < product.sellingPrice;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Category/Subcategory
                    Text(
                      product.subcategory.isNotEmpty ? product.subcategory : product.category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Price Row
                    Row(
                      children: [
                        if (hasDiscount) ...[
                          Text(
                            '₱${product.salePrice!.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.red[600],
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₱${product.sellingPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ] else
                          Text(
                            '₱${product.sellingPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                    
                    // Stock indicator
                    if (product.currentStock <= 5 && product.currentStock > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Only ${product.currentStock} left',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Arrow indicator
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Sort by: ', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
                _sortProducts();
              });
            },
            items: [
              DropdownMenuItem(value: 'name', child: Text('Name')),
              DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
              DropdownMenuItem(value: 'newest', child: Text('Newest First')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...'),
          ],
        ),
      );
    }

    if (brandProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No products available for ${widget.brandName}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: fetchBrandProducts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchBrandProducts,
      child: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Search ${widget.brandName} products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Sort options
          _buildSortOptions(),
          
          // Products list
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.brandName,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          // Add product count in subtitle
          bottom: brandProducts.isNotEmpty ? PreferredSize(
            preferredSize: const Size.fromHeight(30),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${brandProducts.length} product${brandProducts.length != 1 ? 's' : ''} found',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ) : null,
        ),
        body: _buildBody(),
      );
    }

}
