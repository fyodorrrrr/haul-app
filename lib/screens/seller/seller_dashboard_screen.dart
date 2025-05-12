import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/seller_registration_provider.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({Key? key}) : super(key: key);

  @override
  _SellerDashboardScreenState createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool _isLoading = true;
  String _businessName = "";
  Map<String, dynamic> _salesMetrics = {
    'totalSales': 0.0,
    'ordersCount': 0,
    'activeListings': 0,
    'viewCount': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get seller information
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();

      if (!sellerDoc.exists) throw Exception('Seller profile not found');

      // Get basic seller info
      final sellerData = sellerDoc.data()!;
      
      if (!mounted) return;
      setState(() {
        _businessName = sellerData['businessName'] ?? 'Your Shop';
        _salesMetrics = {
          'totalSales': sellerData['totalSales'] ?? 0.0,
          'ordersCount': sellerData['ordersCount'] ?? 0,
          'activeListings': sellerData['activeListings'] ?? 0,
          'viewCount': sellerData['viewCount'] ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_businessName),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadDashboardData,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Here\'s your store performance',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Metrics Cards
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard(
                          'Total Sales', 
                          '\$${_salesMetrics['totalSales'].toStringAsFixed(2)}',
                          Icons.attach_money,
                          Colors.green
                        ),
                        _buildMetricCard(
                          'Orders', 
                          _salesMetrics['ordersCount'].toString(),
                          Icons.shopping_bag_outlined,
                          Colors.blue
                        ),
                        _buildMetricCard(
                          'Active Listings', 
                          _salesMetrics['activeListings'].toString(),
                          Icons.inventory_2_outlined,
                          Colors.orange
                        ),
                        _buildMetricCard(
                          'Total Views', 
                          _salesMetrics['viewCount'].toString(),
                          Icons.visibility_outlined,
                          Colors.purple
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Quick Actions
                    _buildSectionHeader('Quick Actions'),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          context, 
                          Icons.add_box_outlined, 
                          'Add Product', 
                          () {}
                        ),
                        _buildActionButton(
                          context, 
                          Icons.shopping_bag_outlined, 
                          'Orders', 
                          () {}
                        ),
                        _buildActionButton(
                          context, 
                          Icons.inventory_2_outlined, 
                          'Inventory', 
                          () {}
                        ),
                        _buildActionButton(
                          context, 
                          Icons.analytics_outlined, 
                          'Analytics', 
                          () {}
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Recent Orders
                    _buildSectionHeader('Recent Orders'),
                    SizedBox(height: 8),
                    _buildEmptyState(
                      'No orders yet',
                      'Your recent orders will appear here'
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Recent Products
                    _buildSectionHeader('Products'),
                    SizedBox(height: 8),
                    _buildEmptyState(
                      'No products yet',
                      'Add your first product to start selling'
                    ),
                  ],
                ),
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: Icon(Icons.add),
        label: Text('Add Product'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: (index) {},
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text('See All'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, 
    IconData icon, 
    String label, 
    VoidCallback onTap
  ) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 26,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}