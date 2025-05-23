import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import 'product_details_screen.dart';

class SellerPublicProfileScreen extends StatefulWidget {
  final String sellerId;
  
  const SellerPublicProfileScreen({
    Key? key, 
    required this.sellerId,
  }) : super(key: key);

  @override
  _SellerPublicProfileScreenState createState() => _SellerPublicProfileScreenState();
}

class _SellerPublicProfileScreenState extends State<SellerPublicProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _sellerData = {};
  List<Product> _products = [];
  late TabController _tabController;
  String _sortBy = 'newest';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSellerData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to launch URLs
  Future<void> _launchUrl(String urlString, String urlType) async {
    Uri? uri;
    
    switch (urlType) {
      case 'phone':
        uri = Uri.parse('tel:$urlString');
        break;
      case 'email':
        uri = Uri.parse('mailto:$urlString');
        break;
      case 'web':
        uri = Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');
        break;
      case 'map':
        // Using Google Maps base URL with the address as query parameter
        uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(urlString)}');
        break;
      default:
        return;
    }
    
    try {
      if (!await launchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $urlType')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching $urlType: $e')),
        );
      }
    }
  }

  Future<void> _loadSellerData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load seller profile
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(widget.sellerId)
          .get();
          
      if (!sellerDoc.exists) {
        throw Exception('Seller not found');
      }
      
      _sellerData = sellerDoc.data()!;
      
      // Load seller's products
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: widget.sellerId)
          .where('isActive', isEqualTo: true) // Only show active products
          .get();
          
      // Fixed Product.fromMap() call
      _products = productsSnapshot.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Add document ID to data
              return Product.fromMap(data);
            } catch (e) {
              print('Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<Product>()
          .toList();
          
      // Sort products by default
      _sortProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _sortProducts() {
    switch (_sortBy) {
      case 'newest':
        _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        _products.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_high':
        // Fixed: Changed from 'price' to 'sellingPrice'
        _products.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      case 'price_low':
        // Fixed: Changed from 'price' to 'sellingPrice'
        _products.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _sellerData['businessName'] ?? 'Seller Profile',
                      style: GoogleFonts.poppins(),
                    ),
                    background: _sellerData['bannerImageUrl'] != null
                      ? Image.network(
                          _sellerData['bannerImageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                            child: Center(
                              child: Icon(Icons.store, color: Colors.white, size: 64),
                            ),
                          ),
                        )
                      : Container(
                          color: Theme.of(context).primaryColor.withOpacity(0.7),
                          child: Center(
                            child: Icon(Icons.store, color: Colors.white, size: 64),
                          ),
                        ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSellerInfoSection(),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(text: 'Products'),
                        Tab(text: 'About'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildAboutTab(),
              ],
            ),
          ),
    );
  }

  Widget _buildSellerInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: _sellerData['profileImageUrl'] != null
              ? NetworkImage(_sellerData['profileImageUrl'])
              : null,
            child: _sellerData['profileImageUrl'] == null
              ? Icon(Icons.store, size: 40)
              : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sellerData['businessName'] ?? 'Seller',
                  style: GoogleFonts.poppins(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _sellerData['address'] ?? 'No address provided',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatItem('${_products.length}', 'Products'),
                    SizedBox(width: 16),
                    _buildStatItem(_sellerData['joinedYear'] ?? 'N/A', 'Member Since'),
                    SizedBox(width: 16),
                    if (_sellerData['averageRating'] != null)
                      _buildRatingItem(_sellerData['averageRating']),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _buildRatingItem(dynamic rating) {
    double ratingValue = 0.0;
    if (rating is int) {
      ratingValue = rating.toDouble();
    } else if (rating is double) {
      ratingValue = rating;
    } else if (rating is String) {
      ratingValue = double.tryParse(rating) ?? 0.0;
    }
    
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: 20),
        SizedBox(width: 4),
        Text(
          ratingValue.toStringAsFixed(1),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No products available',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'This seller hasn\'t listed any products yet',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        _buildSortingBar(),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortingBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          SizedBox(width: 8),
          DropdownButton<String>(
            value: _sortBy,
            underline: Container(),
            items: [
              DropdownMenuItem(value: 'newest', child: Text('Newest')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
              DropdownMenuItem(value: 'price_high', child: Text('Price high to low')),
              DropdownMenuItem(value: 'price_low', child: Text('Price low to high')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _sortBy = value;
                  _sortProducts();
                });
              }
            },
          ),
          Spacer(),
          Text('${_products.length} items', style: GoogleFonts.poppins(fontSize: 14)),
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
              userId: userId, // Pass userId to ProductDetailsScreen
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
              child: Container(
                width: double.infinity,
                child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first, // Use first image from array
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[500]),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey[500]),
                    ),
              ),
            ),
            // Product info
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: 4),
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
                        SizedBox(width: 8),
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
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _buildAboutTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Description
        if (_sellerData['description'] != null && _sellerData['description'].toString().isNotEmpty) ...[
          Text(
            'About the Shop',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _sellerData['description'] ?? '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
        ],
        
        // Business Hours
        if (_sellerData['businessHours'] != null && _sellerData['businessHours'] is Map) ...[
          Text(
            'Business Hours',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildBusinessHours(_sellerData['businessHours']),
          SizedBox(height: 24),
        ],
        
        // Store Policies
        if (_sellerData['storePolicies'] != null && _sellerData['storePolicies'] is Map) ...[
          Text(
            'Store Policies',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _buildStorePolicies(_sellerData['storePolicies']),
          SizedBox(height: 24),
        ],
        
        // Contact Information
        Text(
          'Contact Information',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        _buildContactInfo(),
      ],
    );
  }
  
  Widget _buildBusinessHours(Map<String, dynamic> hours) {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    
    return Column(
      children: days.map((day) {
        final schedule = hours[day] ?? 'Closed';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  day.substring(0, 1).toUpperCase() + day.substring(1),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  schedule,
                  style: GoogleFonts.poppins(
                    color: schedule.toLowerCase() == 'closed' ? Colors.red : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildStorePolicies(Map<String, dynamic> policies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Return Policy
        if (policies['returnPolicy'] != null && policies['returnPolicy'].toString().isNotEmpty) ...[
          Text(
            'Return Policy',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            policies['returnPolicy'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
        ],
        
        // Shipping Policy
        if (policies['shippingPolicy'] != null && policies['shippingPolicy'].toString().isNotEmpty) ...[
          Text(
            'Shipping Policy',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            policies['shippingPolicy'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
        ],
        
        // Terms & Conditions
        if (policies['termsAndConditions'] != null && policies['termsAndConditions'].toString().isNotEmpty) ...[
          Text(
            'Terms & Conditions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            policies['termsAndConditions'],
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildContactInfo() {
    return Column(
      children: [
        // Phone
        if (_sellerData['phone'] != null && _sellerData['phone'].toString().isNotEmpty)
          ListTile(
            leading: Icon(Icons.phone, color: Theme.of(context).primaryColor),
            title: Text(
              _sellerData['phone'],
              style: GoogleFonts.poppins(),
            ),
            dense: true,
            onTap: () => _launchUrl(_sellerData['phone'], 'phone'),
          ),
          
        // Email
        if (_sellerData['email'] != null && _sellerData['email'].toString().isNotEmpty)
          ListTile(
            leading: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
            title: Text(
              _sellerData['email'],
              style: GoogleFonts.poppins(),
            ),
            dense: true,
            onTap: () => _launchUrl(_sellerData['email'], 'email'),
          ),
          
        // Website
        if (_sellerData['website'] != null && _sellerData['website'].toString().isNotEmpty)
          ListTile(
            leading: Icon(Icons.language, color: Theme.of(context).primaryColor),
            title: Text(
              _sellerData['website'],
              style: GoogleFonts.poppins(),
            ),
            dense: true,
            onTap: () => _launchUrl(_sellerData['website'], 'web'),
          ),
          
        // Address
        if (_sellerData['address'] != null && _sellerData['address'].toString().isNotEmpty)
          ListTile(
            leading: Icon(Icons.location_on_outlined, color: Theme.of(context).primaryColor),
            title: Text(
              _sellerData['address'],
              style: GoogleFonts.poppins(),
            ),
            dense: true,
            onTap: () => _launchUrl(_sellerData['address'], 'map'),
          ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  
  _SliverAppBarDelegate(this._tabBar);
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  
  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
