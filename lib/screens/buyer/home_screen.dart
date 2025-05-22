import 'package:flutter/material.dart';
import 'package:haul/screens/buyer/product_details_screen.dart';
import 'package:haul/screens/buyer/search_results_screen.dart';
import '/widgets/custom_appbar.dart';
import '/widgets/custom_bottomnav.dart';
import 'explore_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'main_home_screen.dart'; // Import the new main home screen
import 'package:provider/provider.dart'; // Import provider for UserProfileProvider
import '/providers/user_profile_provider.dart';
import '/widgets/not_logged_in.dart';
import 'seller_public_profile_screen.dart'; // Import SellerPublicProfileScreen
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import '/models/product_model.dart'; // Import Product model
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firebase Firestore

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
  List<Product> _searchSuggestions = []; // Add a local variable for search suggestions

  void handleSearchChanged(String query) {
    if (query.length >= 2) { // Reduced from 3 to 2 characters for earlier suggestions
      // Convert query to lowercase for case-insensitive search
      String lowercaseQuery = query.toLowerCase();
      
      // First try to get products by name
      FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true) // Only get active products
          .limit(20) // Get more products to filter locally
          .get()
          .then((result) {
            setState(() {
              // Filter results client-side to find products with matching name anywhere
              _searchSuggestions = result.docs
                  .map((doc) => Product.fromMap(doc.id, doc.data()))
                  .where((product) => 
                      product.name.toLowerCase().contains(lowercaseQuery) ||
                      (product.brand != null && 
                       product.brand.toLowerCase().contains(lowercaseQuery)) ||
                      (product.category != null && 
                       product.category.toLowerCase().contains(lowercaseQuery))
                  )
                  .take(5) // Limit to 5 suggestions
                  .toList();
            });
          })
          .catchError((error) {
            print('Error searching products: $error');
          });
    } else if (query.isEmpty) {
      // Clear suggestions when search is empty
      setState(() {
        _searchSuggestions = [];
      });
    }
  }

  void handleSearchAdvanced(String query) {
    if (query.length >= 2) {
      String lowercaseQuery = query.toLowerCase();
      print('🔍 Searching for: "$lowercaseQuery"');
      
      // Get products where name contains query
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
            
            // Debug: Print ALL products to see what we're working with
            for (int i = 0; i < result.docs.length; i++) {
              final doc = result.docs[i];
              final data = doc.data();
              print('📋 Product ${i + 1}: "${data['name']}" | Active: ${data['isActive']} | Brand: "${data['brand']}" | Category: "${data['category']}"');
            }
            
            try {
              final List<Product> allProducts = result.docs
                  .map((doc) {
                    try {
                      final product = Product.fromMap(doc.id, doc.data());
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
                    final name = (product.name ?? '').toLowerCase();
                    final brand = (product.brand ?? '').toLowerCase();
                    final category = (product.category ?? '').toLowerCase();
                    final description = (product.description ?? '').toLowerCase();
                    
                    print('🔍 Checking product: "$name" against query: "$lowercaseQuery"');
                    print('   - Name contains: ${name.contains(lowercaseQuery)}');
                    print('   - Brand contains: ${brand.contains(lowercaseQuery)}');
                    print('   - Category contains: ${category.contains(lowercaseQuery)}');
                    print('   - Description contains: ${description.contains(lowercaseQuery)}');
                    
                    bool matches = name.contains(lowercaseQuery) || 
                                  brand.contains(lowercaseQuery) || 
                                  category.contains(lowercaseQuery) ||
                                  description.contains(lowercaseQuery);
                    
                    if (matches) {
                      print('✅ Match found: ${product.name}');
                    } else {
                      print('❌ No match for: ${product.name}');
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
    // Fetch user profile when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().fetchUserProfile();
    });
  }

  @override
  void dispose() {
    searchController.dispose(); // Don't forget to dispose controllers
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Define screens array
    final List<Widget> screens = [
      MainHomeScreen(userData: widget.userData), // Home (index 0)
      const ExploreScreen(),                    // Explore (index 1)
      const WishlistScreen(),                   // Wishlist (index 2)
      const CartScreen(),                       // Cart (index 3)
      Consumer<UserProfileProvider>(
        builder: (context, provider, child) {
          return provider.userProfile != null
              ? ProfileScreen(userProfile: provider.userProfile!)
              : NotLoggedInScreen(message: 'Please log in to continue', icon: Icons.lock_outline);
        },
      ),  // Profile (index 4)
    ];
    
    // Get titles for app bar based on selected tab
    final List<String> titles = ['Home', 'Explore', 'Wishlist', 'Cart', 'Profile'];
    final String title = titles[_selectedIndex];
    
    // Show search only on Home and Explore tabs
    final bool showSearch = _selectedIndex == 0 || _selectedIndex == 1;
    
    return Scaffold(
      // Only show AppBar for Home and Explore tabs (index 0 and 1)
      appBar: showSearch 
          ? CustomAppBar(
              title: title, // Use dynamic title based on current tab
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
          : null, // No AppBar for Wishlist, Cart, and Profile tabs
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Your existing SafeArea and IndexedStack
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
          ),
          
          // Search suggestions dropdown - only show when search is active AND on searchable tabs
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
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: product.imageUrl.isNotEmpty 
                              ? DecorationImage(
                                  image: NetworkImage(product.imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          ),
                          child: product.imageUrl.isEmpty 
                            ? Icon(Icons.image_not_supported, color: Colors.grey)
                            : null,
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
                        subtitle: Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          // Navigate to product details
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

  // In your product card widget, add a tap handler for the seller name
  Widget _buildSellerInfo(Product product) {
    return GestureDetector(
      onTap: () {
        // Add null check to prevent error
        if (product.sellerId != null && product.sellerId.isNotEmpty) {
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
            // Use a property that does exist, or a placeholder
            product.sellerBusinessName ?? 'Seller', 
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
