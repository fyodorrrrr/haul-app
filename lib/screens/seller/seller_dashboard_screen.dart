import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/seller_registration_provider.dart';
import 'order_listing_screen.dart' show SellerOrdersScreen;
import 'product_listing_screen.dart';
import 'product_form_screen.dart';
import 'seller_profile_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({Key? key}) : super(key: key);

  @override
  _SellerDashboardScreenState createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool _isLoading = true;
  String _businessName = 'Your Shop';
  String? _profileImageUrl;
  Map<String, dynamic> _sellerData = {};
  Map<String, dynamic> _salesMetrics = {
    'totalSales': 0.0,
    'ordersCount': 0,
    'activeListings': 0,
    'viewCount': 0,
  };

  final List<String> _requiredProfileFields = [
    'businessName',
    'address',
    'phone',
    'description',
    'businessHours',
    'profileImageUrl',
  ];

  @override
  void initState() {
    super.initState();
    
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
      }
    });
    
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

      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();

      if (!sellerDoc.exists) throw Exception('Seller profile not found');

      final sellerData = sellerDoc.data()!;
      _sellerData = sellerData;
      
      if (!mounted) return;
      setState(() {
        _businessName = sellerData['businessName'] ?? 'Your Shop';
        _profileImageUrl = sellerData['profileImageUrl'];
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

  double _getProfileCompleteness(Map<String, dynamic> data) {
    int filled = 0;
    for (final field in _requiredProfileFields) {
      if (data[field] != null && data[field].toString().trim().isNotEmpty) {
        if (field == 'businessHours') {
          if (data['businessHours'] is Map && (data['businessHours'] as Map).isNotEmpty) filled++;
        } else {
          filled++;
        }
      }
    }
    return filled / _requiredProfileFields.length;
  }

  List<String> _getMissingFields(Map<String, dynamic> data) {
    List<String> missing = [];
    for (final field in _requiredProfileFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty || (field == 'businessHours' && (data['businessHours'] == null || (data['businessHours'] is Map && (data['businessHours'] as Map).isEmpty)))) {
        missing.add(field);
      }
    }
    return missing;
  }

  bool _isValidPhone(String? phone) {
    if (phone == null) return false;
    final reg = RegExp(r'^(\+?\d{7,15})');
    return reg.hasMatch(phone);
  }

  bool _isValidEmail(String? email) {
    if (email == null) return false;
    final reg = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}');
    return reg.hasMatch(email);
  }

  bool _isValidWebsite(String? url) {
    if (url == null) return false;
    final reg = RegExp(r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]{2,}(\/\S*)?');
    return reg.hasMatch(url);
  }

  @override
  Widget build(BuildContext context) {
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
                    
                    _buildProfileSection(),
                    
                    SizedBox(height: 24),
                    
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
                    
                    _buildSectionHeader('Quick Actions'),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          context, 
                          Icons.add_box_outlined, 
                          'Add Product', 
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductFormScreen()),
                            );
                          }
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
                    
                    _buildSectionHeader('Recent Orders'),
                    SizedBox(height: 8),
                    _buildEmptyState(
                      'No orders yet',
                      'Your recent orders will appear here'
                    ),
                    
                    SizedBox(height: 32),
                    
                    _buildSectionHeader('Products'),
                    SizedBox(height: 8),
                    _buildRecentProducts(),
                  ],
                ),
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductFormScreen()),
          );
        },
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
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductListingScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SellerOrdersScreen()),
            );
          }
        },
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

  Widget _buildRecentProducts() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        final products = provider.products;
        
        if (products.isEmpty) {
          return _buildEmptyState(
            'No products yet',
            'Add your first product to start selling'
          );
        }
        
        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: products.length > 3 ? 3 : products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product);
              },
            ),
            if (products.length > 3)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductListingScreen()),
                  );
                },
                child: Text('View all ${products.length} products'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: product.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  product.images.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: Icon(Icons.inventory_2_outlined, color: Colors.grey),
              ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '\$${product.price.toStringAsFixed(2)} • ${product.stock} in stock',
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: product.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            product.isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              color: product.isActive ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductFormScreen(product: product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection() {
    final verificationStatus = _sellerData['verificationStatus'] ?? 'pending';
    Color statusColor;
    IconData statusIcon;
    
    switch (verificationStatus.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.verified;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
    }

    final completeness = _getProfileCompleteness(_sellerData);
    final missingFields = _getMissingFields(_sellerData);
    final showOnboarding = completeness < 1.0;
    final phoneValid = _isValidPhone(_sellerData['phone']);
    final emailValid = _isValidEmail(FirebaseAuth.instance.currentUser?.email);
    final websiteValid = _sellerData['website'] == null || _sellerData['website'].toString().isEmpty || _isValidWebsite(_sellerData['website']);

    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showOnboarding) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete your profile to unlock all features.',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.orange[900], fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: completeness,
                      minHeight: 7,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(completeness == 1.0 ? Colors.green : Colors.orange),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('${(completeness * 100).round()}%', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              if (missingFields.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Missing: ' + missingFields.map((f) {
                    switch (f) {
                      case 'businessName': return 'Business Name';
                      case 'address': return 'Address';
                      case 'phone': return 'Phone';
                      case 'description': return 'Description';
                      case 'businessHours': return 'Business Hours';
                      case 'profileImageUrl': return 'Profile Image';
                      default: return f;
                    }
                  }).join(', '),
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange[900]),
                ),
              ],
              SizedBox(height: 12),
            ],
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage('assets/default_profile.png') as ImageProvider,
                      backgroundColor: Colors.grey.shade200,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          statusIcon,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _businessName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 13, color: emailValid ? Colors.grey[600] : Colors.red),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              FirebaseAuth.instance.currentUser?.email ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: emailValid ? Colors.grey[600] : Colors.red,
                                fontWeight: emailValid ? FontWeight.normal : FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!emailValid)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.error_outline, color: Colors.red, size: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 13, color: phoneValid ? Colors.grey[700] : Colors.red),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _sellerData['phone'] ?? 'No phone',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: phoneValid ? Colors.grey[700] : Colors.red,
                                fontWeight: phoneValid ? FontWeight.normal : FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!phoneValid)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.error_outline, color: Colors.red, size: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.language_outlined, size: 13, color: websiteValid ? Colors.grey[700] : Colors.red),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _sellerData['website'] ?? 'No website',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: websiteValid ? Colors.grey[700] : Colors.red,
                                fontWeight: websiteValid ? FontWeight.normal : FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!websiteValid)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.error_outline, color: Colors.red, size: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _sellerData['address'] ?? 'No address provided',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerProfileScreen(initialData: _sellerData),
                      ),
                    ).then((_) => _loadDashboardData());
                  },
                ),
              ],
            ),
            if (_sellerData['description'] != null && _sellerData['description'].toString().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _sellerData['description'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}