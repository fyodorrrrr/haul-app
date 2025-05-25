import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/product.dart';
import '../screens/buyer/search_screen.dart'; // ✅ Add this import

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearchBar;
  final TextEditingController? searchController; // ✅ Make optional
  final Function(String)? onSearchChanged; // ✅ Make optional
  final List<Product>? searchSuggestions;
  final VoidCallback? onSearchSubmitted;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showSearchBar = true,
    this.searchController, // ✅ Make optional
    this.onSearchChanged, // ✅ Make optional
    this.searchSuggestions,
    this.onSearchSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: showSearchBar
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'assets/haul_logo_.png',
                  height: 64,
                  width: 64,
                ),
                SizedBox(width: 8),
                
                // ✅ Replace TextField with GestureDetector
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // ✅ Navigate to SearchScreen when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 16),
                          Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Search for thrift items...',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
      leading: title == 'Explore'
          ? IconButton(
              icon: Icon(Icons.filter_list, color: Colors.black),
              onPressed: () {
                // ✅ Navigate to SearchScreen with filters open
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(),
                  ),
                ).then((_) {
                  // Could open filters bottom sheet automatically
                });
              },
            )
          : null,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.black),
          onPressed: () {
            // Add notification functionality
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
