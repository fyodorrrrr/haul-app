import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/inventory_provider.dart';
import '../../models/product.dart';
import 'inventory_list_screen.dart';
import 'stock_adjustment_screen.dart';
import 'stock_movements_screen.dart';
import 'product_form_screen.dart';

class InventoryDashboardScreen extends StatefulWidget {
  @override
  _InventoryDashboardScreenState createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
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
          'Inventory Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
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
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${provider.error}',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchProducts(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchProducts(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(provider),
                  SizedBox(height: 24),
                  _buildQuickActions(),
                  SizedBox(height: 24),
                  _buildLowStockAlert(provider),
                  SizedBox(height: 24),
                  _buildRecentProducts(provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCards(InventoryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Overview',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard(
              'Total Products',
              provider.totalProducts.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
            _buildStatCard(
              'Active Products',
              provider.activeProducts.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Low Stock',
              provider.lowStockCount.toString(),
              Icons.warning,
              Colors.orange,
            ),
            _buildStatCard(
              'Out of Stock',
              provider.outOfStockProducts.toString(),
              Icons.error,
              Colors.red,
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildValueCard(
                'Inventory Value',
                '₱${provider.totalInventoryValue.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildValueCard(
                'Selling Value',
                '₱${provider.totalSellingValue.toStringAsFixed(2)}',
                Icons.monetization_on,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(12), // Reduced padding
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center content
          mainAxisSize: MainAxisSize.min, // Minimize height
          children: [
            Icon(icon, color: color, size: 20), // Reduced icon size
            SizedBox(height: 6), // Reduced spacing
            Flexible( // Make text flexible
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2), // Reduced spacing
            Flexible( // Make text flexible
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11, // Reduced font size
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(14), // Slightly reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Minimize height
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18), // Slightly smaller icon
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
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
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15, // Slightly reduced font size
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View All Products',
                Icons.list,
                Colors.blue,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InventoryListScreen()),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Stock Movements',
                Icons.timeline,
                Colors.green,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StockMovementsScreen()),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Product',
                Icons.add_box,
                Colors.purple,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductFormScreen()),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Adjust Stock',
                Icons.edit,
                Colors.orange,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StockAdjustmentScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockAlert(InventoryProvider provider) {
    if (provider.lowStockProducts.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              'Low Stock Alert',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${provider.lowStockProducts.length} products are running low on stock',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange[800],
                ),
              ),
              SizedBox(height: 12),
              ...provider.lowStockProducts.take(3).map((product) => 
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.currentStock} left',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.lowStockProducts.length > 3)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryListScreen(filter: 'low_stock'),
                    ),
                  ),
                  child: Text('View all ${provider.lowStockProducts.length} products'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProducts(InventoryProvider provider) {
    final recentProducts = provider.products.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Products',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InventoryListScreen()),
              ),
              child: Text('View All'),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (recentProducts.isEmpty)
          Container(
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'No products yet',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentProducts.length,
              itemBuilder: (context, index) {
                final product = recentProducts[index];
                return Container(
                  width: 200,
                  margin: EdgeInsets.only(right: 12),
                  child: _buildProductCard(product),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        height: 110, // Fixed height to prevent overflow
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product name and stock
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13, // Slightly smaller
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStockColor(product.currentStock).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${product.currentStock}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStockColor(product.currentStock),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 6),
            
            // SKU
            Text(
              'SKU: ${product.sku}',
              style: GoogleFonts.poppins(
                fontSize: 9, // Smaller text
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 6),
            
            // Price and category
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '₱${product.sellingPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product.category,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.blue[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }
}