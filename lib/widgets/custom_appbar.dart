import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haul/screens/buyer/search_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearchBar;
  final TextEditingController searchController;
  final Function(String) onSearchChanged;

  const CustomAppBar({
    super.key,
    this.title = 'HAUL',
    required this.showSearchBar,
    required this.searchController,
    required this.onSearchChanged,

  });

  @override
  _customAppBarState createState() => _customAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(120);
}

  class _customAppBarState extends State<CustomAppBar>{
  @override
  Widget build(BuildContext context) {
    final searchController = widget.searchController;
    List searchResults = [];

    void searchProducts (String query) async {
      if (query.isEmpty) {
        return;
      }
      QuerySnapshot result = await FirebaseFirestore.instance
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .get();

        List<DocumentSnapshot> documents = result.docs;

        setState(() {
          searchResults = documents;
        });
    }


    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isSmallScreen = width < 360;
    final iconSize = isSmallScreen ? 20.0 : width * 0.06;
    final fontSize = isSmallScreen ? 12.0 : width * 0.04;
    final horizontalPadding = width * 0.04;
    final toolbarHeight = kToolbarHeight;

    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row
            SizedBox(
              height: toolbarHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Settings Icon
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: IconButton(
                      icon: Icon(Icons.settings, size: iconSize, color: Colors.black),
                      onPressed: () {},
                    ),
                  ),

                  // Center Logo
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/haul_logo_.png',
                        height: height * 0.04,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Notifications Icon
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: IconButton(
                      icon: Icon(Icons.notifications_outlined, size: iconSize, color: Colors.black),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            if (widget.showSearchBar)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: height * 0.01),
                child: Container(
                  height: height * 0.06,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Icon(Icons.search, color: Colors.grey, size: iconSize),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        //Editing search bar
                        child: TextField(
                          
                          controller: searchController,
                          onChanged: (value){
                            searchProducts(value);
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => search_product(
                                    showSearchBar: true,
                                    searchController: TextEditingController(text: value),
                                    onSearchChanged: (value){},
                                    query: value,
                                  )
                                )
                              );
                            }
                            searchController.clear();
                          },


                          decoration: InputDecoration(
                            hintText: 'Search for products',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: fontSize,
                              color: Colors.black54,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: height * 0.01),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                        child: Center(
                          child: Icon(Icons.menu, color: Colors.white, size: iconSize),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
