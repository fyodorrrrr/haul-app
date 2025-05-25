import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/screens/buyer/product_details_screen.dart';
import 'package:haul/screens/buyer/search_results_screen.dart';
import '/widgets/custom_appbar.dart';
import '/widgets/custom_bottomnav.dart';
import 'explore_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'main_home_screen.dart';
import 'package:provider/provider.dart';
import '/providers/user_profile_provider.dart';
import '/widgets/not_logged_in.dart';
import 'seller_public_profile_screen.dart';
import '../../models/product.dart'; // Make sure this points to your enhanced Product model
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/brand_logo_widget.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const HomeScreen({
    Key? key, 
    required this.userData,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  List<Product> _searchSuggestions = [];

  void handleSearchChanged(String query) {
    if (query.length >= 2) {
      String lowercaseQuery = query.toLowerCase();
      
      FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get()
          .then((result) {
            setState(() {
              _searchSuggestions = result.docs
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
                  .where((product) => 
                      product.name.toLowerCase().contains(lowercaseQuery) ||
                      product.brand.toLowerCase().contains(lowercaseQuery) ||
                      product.category.toLowerCase().contains(lowercaseQuery)
                  )
                  .take(5)
                  .toList();
            });
          })
          .catchError((error) {
            print('Error searching products: $error');
          });
    } else if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
      });
    }
  }

  void handleSearchAdvanced(String query) {
    if (query.length >= 2) {
      String lowercaseQuery = query.toLowerCase();
      print('🔍 Searching for: "$lowercaseQuery"');
      
      FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get()
          .then((result) {
            print('📦 Total products fetched: ${result.docs.length}');
            
            if (result.docs.isEmpty) {
              print('❌ No products in database at all!');
              setState(() {
                _searchSuggestions = [];
              });
              return;
            }
            
            try {
              final List<Product> allProducts = result.docs
                  .map((doc) {
                    try {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id; // Add document ID to data
                      final product = Product.fromMap(data);
                      print('✅ Parsed product: "${product.name}" | Brand: "${product.brand}" | Category: "${product.category}"');
                      return product;
                    } catch (e) {
                      print('❌ Error parsing product ${doc.id}: $e');
                      return null;
                    }
                  })
                  .where((product) => product != null)
                  .cast<Product>()
                  .toList();
                  
              print('✅ Successfully parsed ${allProducts.length} products');
              
              final List<Product> filteredProducts = allProducts
                  .where((product) {
                    final name = product.name.toLowerCase();
                    final brand = product.brand.toLowerCase();
                    final category = product.category.toLowerCase();
                    final description = product.description.toLowerCase();
                    
                    bool matches = name.contains(lowercaseQuery) || 
                                  brand.contains(lowercaseQuery) || 
                                  category.contains(lowercaseQuery) ||
                                  description.contains(lowercaseQuery);
                    
                    if (matches) {
                      print('✅ Match found: ${product.name}');
                    }
                    
                    return matches;
                  })
                  .take(5)
                  .toList();
                  
              print('🎯 Final filtered results: ${filteredProducts.length}');
              
              setState(() {
                _searchSuggestions = filteredProducts;
              });
              
            } catch (e) {
              print('❌ Error processing search results: $e');
              setState(() {
                _searchSuggestions = [];
              });
            }
          })
          .catchError((error) {
            print('❌ Firestore error: $error');
            setState(() {
              _searchSuggestions = [];
            });
          });
    } else {
      setState(() {
        _searchSuggestions = [];
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().fetchUserProfile();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MainHomeScreen(userData: widget.userData),
      const ExploreScreen(),
      const WishlistScreen(),
      const CartScreen(),
      Consumer<UserProfileProvider>(
        builder: (context, provider, child) {
          return provider.userProfile != null
              ? ProfileScreen(userProfile: provider.userProfile!)
              : NotLoggedInScreen(message: 'Please log in to continue', icon: Icons.lock_outline);
        },
      ),
    ];
    
    final List<String> titles = ['Home', 'Explore', 'Wishlist', 'Cart', 'Profile'];
    final String title = titles[_selectedIndex];
    final bool showSearch = _selectedIndex == 0; // Only show search on Home (index 0)
    
    return Scaffold(
      appBar: _selectedIndex == 1 // If it's Explore screen (index 1)
          ? null // No AppBar for Explore
          : showSearch 
              ? CustomAppBar(
                  title: title,
                  searchController: searchController,
                  onSearchChanged: handleSearchAdvanced,
                  showSearchBar: true,
                  searchSuggestions: _searchSuggestions,
                  onSearchSubmitted: () {
                    if (searchController.text.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SearchResultsScreen(query: searchController.text),
                        ),
                      );
                    }
                  },
                )
              : CustomAppBar(
                  title: title,
                  searchController: searchController,
                  onSearchChanged: handleSearchAdvanced,
                  showSearchBar: false, // No search bar for other screens
                  searchSuggestions: [],
                ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
          
          // Fixed search suggestions dropdown
          if (showSearch && searchController.text.length >= 2 && _searchSuggestions.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4.0,
                color: Colors.transparent,
                child: Container(
                  color: Colors.white,
                  constraints: BoxConstraints(
                    maxHeight: 300,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchSuggestions.length,
                    itemBuilder: (context, index) {
                      final product = _searchSuggestions[index];
                      return ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Brand logo
                            BrandLogoWidget(
                              brandName: product.brand,
                              size: 24,
                              circular: true,
                            ),
                            SizedBox(width: 8),
                            // Product image
                            Container(
                              width: 50,
                              height: 50,
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
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.image_not_supported, color: Colors.grey);
                                      },
                                    ),
                                  )
                                : Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ],
                        ),
                        title: Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              product.brand,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' • ₱${product.sellingPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  // Updated seller info widget to use correct field names
  Widget _buildSellerInfo(Product product) {
    return GestureDetector(
      onTap: () {
        if (product.sellerId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerPublicProfileScreen(sellerId: product.sellerId),
            ),
          );
        }
      },
      child: Row(
        children: [
          Text(
            'by ',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            product.brand, // Use brand as seller name, or you can add a sellerName field to Product model
            style: GoogleFonts.poppins(
              fontSize: 12, 
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
