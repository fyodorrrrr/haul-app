import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/screens/seller/seller_profile_navigation_screen.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/seller_registration_provider.dart';
import '../../providers/analytics_provider.dart';
import 'order_listing_screen.dart' show SellerOrdersScreen;
import 'product_listing_screen.dart';
import 'product_form_screen.dart';
import 'seller_profile_screen.dart';
import 'analytics_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
    'totalSalesWeek': 0.0,
  };

  List<Map<String, dynamic>> _recentOrders = [];
  bool _ordersLoading = true;
  String? _ordersError;

  final List<String> _requiredProfileFields = [
    'businessName',
    'address',
    'phone',
    'description',
    'businessHours',
    'profileImageUrl',
  ];

  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupOrdersListener();
    
    // Load analytics with delay to ensure provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
        print('Loading analytics from dashboard...');
        analyticsProvider.fetchAnalytics().then((_) {
          print('Analytics loading completed');
        }).catchError((error) {
          print('Analytics loading failed: $error');
        });
      }
    });
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }

  void _setupOrdersListener() {
    setState(() {
      _ordersLoading = true;
      _ordersError = null;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final ordersStream = FirebaseFirestore.instance
          .collection('orders')
          .where('sellerIds', arrayContains: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots();
      
      _ordersSubscription = ordersStream.listen(
        (snapshot) {
          if (mounted) {
            final orders = snapshot.docs.map((doc) {
              final data = doc.data();
              data['documentId'] = doc.id;
              return data;
            }).toList();
            
            setState(() {
              _recentOrders = orders;
              _ordersLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _ordersError = error.toString();
              _ordersLoading = false;
            });
          }
        }
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _ordersError = e.toString();
          _ordersLoading = false;
        });
      }
    }
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
          'totalSalesWeek': sellerData['totalSalesWeek'] ?? 0.0,
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
                          '₱${_salesMetrics['totalSales'].toStringAsFixed(2)}', // Fixed: Changed from '$' to '₱'
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
                    
                    SizedBox(height: 24),
                    Consumer<AnalyticsProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) {
                          return Center(child: CircularProgressIndicator());
                        }
                        return Column(
                          children: [
                            _buildAnalyticsSummary(),
                            if (provider.error != null)
                              TextButton(
                                onPressed: () {
                                  Provider.of<AnalyticsProvider>(context, listen: false).fetchAnalytics();
                                },
                                child: Text('Retry loading analytics'),
                              ),
                          ],
                        );
                      },
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
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => SellerOrdersScreen()),
                            );
                          }
                        ),
                        _buildActionButton(
                          context, 
                          Icons.inventory_2_outlined, 
                          'Inventory', 
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductListingScreen()), // Fixed: Changed from InventoryDashboardScreen to ProductListingScreen
                            );
                          }
                        ),
                        _buildActionButton(
                          context, 
                          Icons.analytics_outlined, 
                          'Analytics', 
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AnalyticsScreen()),
                            );
                          }
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 32),
                    
                    _buildSectionHeader('Recent Orders'),
                    SizedBox(height: 8),
                    _buildRecentOrdersSection(),
                    
                    SizedBox(height: 32),
                    
                    _buildSectionHeader('Products'),
                    SizedBox(height: 8),
                    _buildRecentProducts(),
                  ],
                ),
              ),
            ),
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
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SellerProfileNavigationScreen()),
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
    VoidCallback? onSeeAll;
    if (title == 'Recent Orders') {
      onSeeAll = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SellerOrdersScreen()),
        );
      };    } else if (title == 'Products') {
      onSeeAll = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductListingScreen()),
        );
      };
    } else {
      onSeeAll = null;
    }
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
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
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
    );  }

  Widget _buildRecentProducts() {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final products = provider.products;
        
        if (products.isEmpty) {
          return _buildEmptyProductsState();
        }
        
        return _buildProductsGrid(products);
      },
    );
  }

  Widget _buildEmptyProductsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: Colors.blue[600],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No Products Yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start building your inventory by adding your first product',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    return Column(
      children: [
        SizedBox(
          height: 200, // Increased from 180 to 200 to accommodate content
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: products.length > 6 ? 6 : products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                width: 140,
                margin: EdgeInsets.only(right: 12),
                child: _buildSimpleProductCard(product),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
        child: Container(
          width: 140,
          height: 190, // Increased from 170 to 190 to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with status badge
              Container(
                height: 80, // Reduced from 85 to 80 to save space
                width: double.infinity,
                margin: EdgeInsets.all(6), // Reduced from 8 to 6
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: product.images.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product.images.first, // Fixed: Changed from imageUrl to images.first
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                              ),
                            )
                          : _buildImagePlaceholder(),
                    ),
                    
                    // Status badge
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
                        decoration: BoxDecoration(
                          color: product.isActive ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(6), // Reduced radius
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          product.isActive ? 'LIVE' : 'OFF',
                          style: GoogleFonts.poppins(
                            fontSize: 7, // Reduced from 8 to 7
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Product details section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(6, 0, 6, 6), // Reduced all padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Product name
                      Container(
                        height: 28, // Reduced from 32 to 28
                        child: Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 10, // Reduced from 11 to 10
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            height: 1.1, // Reduced line height
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Bottom section with price and details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Price - Fixed: Changed from product.price to product.sellingPrice
                          Text(
                            '₱${product.sellingPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12, // Reduced from 13 to 12
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          
                          SizedBox(height: 2),
                          
                          // Stock and category row - Fixed: Changed from product.stock to product.currentStock
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Reduced padding
                                  decoration: BoxDecoration(
                                    color: _getStockColor(product.currentStock).withOpacity(0.1), // Fixed: Changed from stock to currentStock
                                    borderRadius: BorderRadius.circular(4), // Reduced radius
                                  ),
                                  child: Text(
                                    '${product.currentStock}', // Fixed: Changed from stock to currentStock
                                    style: GoogleFonts.poppins(
                                      fontSize: 7, // Reduced from 8 to 7
                                      fontWeight: FontWeight.w600,
                                      color: _getStockColor(product.currentStock), // Fixed: Changed from stock to currentStock
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 3, vertical: 1), // Reduced padding
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3), // Reduced radius
                                ),
                                child: Text(
                                  product.category.length > 4 
                                      ? product.category.substring(0, 4).toUpperCase()
                                      : product.category.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 6, // Reduced from 7 to 6
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 2),
                          
                          // Action row with views and edit icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.visibility_outlined,
                                    size: 10, // Reduced from 12 to 10
                                    color: Colors.grey[500],
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '${product.viewCount}', // Fixed: viewCount is non-nullable in enhanced model
                                    style: GoogleFonts.poppins(
                                      fontSize: 8, // Reduced from 9 to 8
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Icon(
                                Icons.edit_outlined,
                                size: 12, // Reduced from 14 to 12
                                color: Colors.blue[600],
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: Colors.grey[500],
        size: 20,
      ),
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
                  product.images.first, // Fixed: Changed from imageUrl to images.first
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
          '₱${product.sellingPrice.toStringAsFixed(2)} • ${product.currentStock} in stock', // Fixed: Changed from price and stock to sellingPrice and currentStock
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
                          : const AssetImage('assets/haul_logo.png') as ImageProvider,
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

  Widget _buildRecentOrdersSection() {
    if (_ordersLoading) {
      return Container(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_ordersError != null) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 32),
              SizedBox(height: 8),
              Text(
                'Failed to load orders',
                style: GoogleFonts.poppins(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_recentOrders.isEmpty) {
      return Container(
        // Remove fixed height to let content determine height
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min to avoid expanding unnecessarily
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, color: Colors.grey[600], size: 32),
              SizedBox(height: 8),
              Text(
                'No recent orders',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Orders will appear here once customers start buying',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Limit to 2 lines
                overflow: TextOverflow.ellipsis, // Add ellipsis if text overflows
              ),
            ],
          ),
        ),
      );
    }

    // Horizontal scrollable order cards with different layout
    return Container(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentOrders.length,
        itemBuilder: (context, index) {
          final order = _recentOrders[index];
          final createdAt = order['createdAt'] is Timestamp
              ? (order['createdAt'] as Timestamp).toDate()
              : null;
          final orderItems = order['items'] is List ? List<Map<String, dynamic>>.from(order['items']) : [];
          String? imageUrl;
          if (orderItems.isNotEmpty && orderItems[0]['imageURL'] != null) {
            imageUrl = orderItems[0]['imageURL'];
          }
          
          // Get status color
          Color statusColor = Colors.orange;
          String status = order['status'] ?? 'pending';
          switch (status.toLowerCase()) {
            case 'delivered':
              statusColor = Colors.green;
              break;
            case 'processing':
              statusColor = Colors.blue;
              break;
            case 'cancelled':
              statusColor = Colors.red;
              break;
            default:
              statusColor = Colors.orange;
          }

          return Container(
            width: 200,
            margin: EdgeInsets.only(right: 12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${order['orderNumber'] ?? order['orderId'] ?? ''}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (createdAt != null)
                                Text(
                                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${order['total']?.toStringAsFixed(2) ?? '0.00'}', // Fixed: Changed from '$' to '₱'
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${orderItems.length} item${orderItems.length != 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Overview',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Week',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '₱${_salesMetrics['totalSalesWeek'] ?? 0}', // Fixed: Changed from '$' to '₱'
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 150,
                  height: 50,
                  child: Consumer<AnalyticsProvider>(
                    builder: (context, provider, _) {
                      // Add error handling for debugging
                      print('Analytics provider state: isLoading=${provider.isLoading}, hasError=${provider.error != null}');
                      
                      if (provider.isLoading) {
                        return Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      
                      if (provider.error != null) {
                        print('Error in provider: ${provider.error}');
                        return Center(child: Text('Error', style: TextStyle(color: Colors.red)));
                      }
                      
                      final analytics = provider.analytics;
                      print('SalesData points: ${analytics.salesByDate.length}');
                      
                      // Prepare chart data with defensive programming
                      List<SalesData> chartData = [];
                      
                      // Only try to map data if we have some
                      if (analytics.salesByDate.isNotEmpty) {
                        try {
                          chartData = analytics.salesByDate.map((dataPoint) {
                            // Convert the date string to a numeric index for the chart
                            // This is crude but will work for visualization
                            final dateIndex = analytics.salesByDate.indexOf(dataPoint).toDouble();
                            return SalesData(dateIndex, dataPoint.sales);
                          }).toList();
                        } catch (e) {
                          print('Chart data conversion error: $e');
                          chartData = [SalesData(0, 0), SalesData(1, 0)]; 
                        }
                      } else {
                        // Fallback data 
                        chartData = [SalesData(0, 0), SalesData(1, 0)];
                      }
                      
                      return SfCartesianChart(
                        plotAreaBorderWidth: 0,
                        primaryXAxis: NumericAxis(isVisible: false),
                        primaryYAxis: NumericAxis(isVisible: false),
                        series: <CartesianSeries<SalesData, double>>[
                          SplineAreaSeries<SalesData, double>(
                            dataSource: chartData,
                            xValueMapper: (SalesData data, _) => data.day,
                            yValueMapper: (SalesData data, _) => data.sales,
                            color: Colors.blue.withOpacity(0.2),
                            borderColor: Colors.blue,
                            borderWidth: 2,
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fixed: Changed parameter from 'int stock' to 'int currentStock'
  Color _getStockColor(int currentStock) {
    if (currentStock <= 0) return Colors.red;
    if (currentStock <= 5) return Colors.orange;
    return Colors.green;
  }
}

class SalesData {
  final double day;
  final double sales;
  
  SalesData(this.day, this.sales);
}