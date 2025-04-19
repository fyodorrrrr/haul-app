import 'package:flutter/material.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_bottomnav.dart';
import 'explore_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'main_home_screen.dart'; // Import the new main home screen


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
      ProfileScreen(userData: widget.userData), // Profile (index 4)
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
}
