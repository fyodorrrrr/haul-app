import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/product_model.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(showSearchBar ? 122.0 : 56.0);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isSearchFocused = false;
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false, // Remove default back button
      centerTitle: true, // Center the title/logo
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add your logo here
          Image.asset(
            'assets/haul_logo_.png', // Replace with your logo path
            height: 64, // Adjust height as needed
            width: 64,  // Adjust width as needed
          ),
        ],
      ),
      // Add leading and trailing widgets if needed
      leading: widget.title == 'Explore' 
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
      ],
      bottom: widget.showSearchBar
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _isSearchFocused
                          ? [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.fromSwatch().copyWith(
                          secondary: Theme.of(context).primaryColor,
                        ),
                      ),
                      child: TextField(
                        controller: widget.searchController,
                        focusNode: _searchFocus,
                        onChanged: widget.onSearchChanged,
                        onSubmitted: (value) {
                          if (widget.onSearchSubmitted != null) {
                            widget.onSearchSubmitted!();
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
                          suffixIcon: widget.searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    widget.searchController.clear();
                                    widget.onSearchChanged('');
                                    setState(() {});
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
                ],
              ),
            )
          : null,
    );
  }
}
