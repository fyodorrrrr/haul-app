import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import 'product_form_screen.dart';
import '../../utils/safe_state.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({Key? key}) : super(key: key);

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  bool _isLoading = true;
  String _filterStatus = 'all'; // 'all', 'active', 'inactive'
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    if (!mounted) return;
    safeSetState(() => _isLoading = true);
    
    try {
      await Provider.of<ProductProvider>(context, listen: false).loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    } finally {
      if (mounted) safeSetState(() => _isLoading = false);
    }
  }
  
  List<Product> _getFilteredProducts(List<Product> allProducts) {
    return allProducts.where((product) {
      // Apply status filter
      if (_filterStatus == 'active' && !product.isActive) return false;
      if (_filterStatus == 'inactive' && product.isActive) return false;
      
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return product.name.toLowerCase().contains(query) || 
               product.description.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }
  
  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final success = await Provider.of<ProductProvider>(
          context, 
          listen: false
        ).deleteProduct(product.id);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product deleted successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting product: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Products',
          style: GoogleFonts.poppins(),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormScreen()),
              );
              _loadProducts(); // Refresh after returning
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    safeSetState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Inactive', 'inactive'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Product list
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (provider.products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first product',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProductFormScreen(),
                              ),
                            ).then((_) => _loadProducts());
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                final filteredProducts = _getFilteredProducts(provider.products);
                
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'No products match your filters',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductFormScreen()),
          ).then((_) => _loadProducts());
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          safeSetState(() {
            _filterStatus = value;
          });
        }
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductFormScreen(product: product),
            ),
          ).then((_) => _loadProducts());
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.isActive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: product.isActive ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.inventory_2_outlined,
                        '${product.stock} in stock',
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.visibility_outlined,
                        '${product.viewCount} views',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductFormScreen(product: product),
                            ),
                          ).then((_) => _loadProducts());
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(product),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}