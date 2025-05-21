import 'package:flutter/material.dart';
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
  void handleSearchChanged(String query){
    print("user is searching for: $query");
  }
  

  @override
  void initState() {
    super.initState();
    // Fetch user profile when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().fetchUserProfile();
    });
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
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: title,
        showSearchBar: showSearch,
        searchController: searchController,
        onSearchChanged: handleSearchChanged,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
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
