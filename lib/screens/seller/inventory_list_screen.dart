// Create lib/screens/seller/inventory_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/inventory_provider.dart';
import '../../models/product.dart';
import 'product_form_screen.dart';
import 'stock_adjustment_screen.dart';

class InventoryListScreen extends StatefulWidget {
  final String? filter;

  const InventoryListScreen({Key? key, this.filter}) : super(key: key);

  @override
  _InventoryListScreenState createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _sortBy = 'name';
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory List',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductFormScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'export', child: Text('Export Data')),
              PopupMenuItem(value: 'bulk_edit', child: Text('Bulk Edit')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          List<Product> filteredProducts = _getFilteredProducts(provider);

          return Column(
            children: [
              _buildSearchAndFilters(),
              _buildSortingBar(filteredProducts.length),
              Expanded(
                child: filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : _buildProductList(filteredProducts),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductFormScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search products, SKU, category...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: 12),
          
          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Category', _selectedCategory, _getCategories()),
                SizedBox(width: 8),
                _buildFilterChip('Status', _selectedStatus, ['All', 'Active', 'Inactive', 'Low Stock', 'Out of Stock']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options) {
    return FilterChip(
      label: Text('$label: $selected'),
      selected: selected != 'All',
      onSelected: (bool value) {
        _showFilterDialog(label, options);
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  Widget _buildSortingBar(int totalCount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Text(
            '$totalCount products',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Spacer(),
          Text('Sort by: ', style: GoogleFonts.poppins(fontSize: 12)),
          DropdownButton<String>(
            value: _sortBy,
            underline: SizedBox(),
            items: [
              DropdownMenuItem(value: 'name', child: Text('Name')),
              DropdownMenuItem(value: 'stock', child: Text('Stock')),
              DropdownMenuItem(value: 'price', child: Text('Price')),
              DropdownMenuItem(value: 'updated', child: Text('Updated')),
            ],
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
          IconButton(
            icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductFormScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Product Image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: product.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.grey[500],
                              ),
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey[500],
                          ),
                  ),
                  SizedBox(width: 16),
                  
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'SKU: ${product.sku}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: product.isActive 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.isActive ? 'ACTIVE' : 'INACTIVE',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: product.isActive ? Colors.green[700] : Colors.red[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Stock and Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStockColor(product.currentStock).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.currentStock}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getStockColor(product.currentStock),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '₱${product.sellingPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      if (product.isLowStock)
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LOW STOCK',
                            style: GoogleFonts.poppins(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              SizedBox(height: 12),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StockAdjustmentScreen(product: product),
                          ),
                        );
                      },
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('Adjust Stock'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductFormScreen(product: product),
                          ),
                        );
                      },
                      icon: Icon(Icons.visibility, size: 16),
                      label: Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No products found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductFormScreen()),
              );
            },
            icon: Icon(Icons.add),
            label: Text('Add Product'),
          ),
        ],
      ),
    );
  }

  List<Product> _getFilteredProducts(InventoryProvider provider) {
    List<Product> products = provider.products;

    // Apply initial filter
    if (widget.filter == 'low_stock') {
      products = provider.lowStockProducts;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      products = provider.searchProducts(_searchQuery);
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      products = products.where((p) => p.category == _selectedCategory).toList();
    }

    // Apply status filter
    if (_selectedStatus != 'All') {
      switch (_selectedStatus) {
        case 'Active':
          products = products.where((p) => p.isActive).toList();
          break;
        case 'Inactive':
          products = products.where((p) => !p.isActive).toList();
          break;
        case 'Low Stock':
          products = products.where((p) => p.isLowStock).toList();
          break;
        case 'Out of Stock':
          products = products.where((p) => p.isOutOfStock).toList();
          break;
      }
    }

    // Apply sorting
    products.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'name':
          result = a.name.compareTo(b.name);
          break;
        case 'stock':
          result = a.currentStock.compareTo(b.currentStock);
          break;
        case 'price':
          result = a.sellingPrice.compareTo(b.sellingPrice);
          break;
        case 'updated':
          result = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return _isAscending ? result : -result;
    });

    return products;
  }

  List<String> _getCategories() {
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final categories = provider.products.map((p) => p.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  void _showFilterDialog(String filterType, List<String> options) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $filterType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => ListTile(
            title: Text(option),
            onTap: () {
              setState(() {
                if (filterType == 'Category') {
                  _selectedCategory = option;
                } else {
                  _selectedStatus = option;
                }
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportData();
        break;
      case 'bulk_edit':
        _showBulkEditDialog();
        break;
      case 'refresh':
        Provider.of<InventoryProvider>(context, listen: false).fetchProducts();
        break;
    }
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export functionality coming soon!')),
    );
  }

  void _showBulkEditDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk edit functionality coming soon!')),
    );
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }
}