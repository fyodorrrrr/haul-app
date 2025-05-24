import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/product.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearchBar;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final List<Product>? searchSuggestions;
  final VoidCallback? onSearchSubmitted;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showSearchBar = true,
    required this.searchController,
    required this.onSearchChanged,
    this.searchSuggestions,
    this.onSearchSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false, // Remove default back button
      centerTitle: true, // Center the title/logo
      title: showSearchBar
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add your logo here
                Image.asset(
                  'assets/haul_logo_.png', // Replace with your logo path
                  height: 64, // Adjust height as needed
                  width: 64,  // Adjust width as needed
                ),
                SizedBox(width: 8),
                Expanded(
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
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.fromSwatch().copyWith(
                          secondary: Theme.of(context).primaryColor,
                        ),
                      ),
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onSubmitted: (value) {
                          if (onSearchSubmitted != null) {
                            onSearchSubmitted!();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search for thrift items...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    searchController.clear();
                                    onSearchChanged('');
                                    // setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                        ),
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
      // Add leading and trailing widgets if needed
      leading: title == 'Explore'
          ? IconButton(
              icon: Icon(Icons.filter_list, color: Colors.black),
              onPressed: () {
                // Add filter functionality
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
        // IconButton(
        //   icon: Icon(Icons.clear_all),
        //   onPressed: () {
        //     setState(() {
        //       _selectedCategory = 'All';
        //       _selectedCondition = 'All';
        //       _priceRange = RangeValues(0, 200);
        //       _sortBy = 'newest';
        //     });
        //     _loadFeaturedProducts();
        //   },
        // ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
