import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearchBar;

  const CustomAppBar({
    Key? key,
    this.title = 'HAUL',
    this.showSearchBar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            if (showSearchBar)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: height * 0.01),
                child: Container(
                  height: height * 0.05,
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
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for products',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: fontSize,
                              color: Colors.black54,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: height * 0.012),
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

  @override
  Size get preferredSize => const Size.fromHeight(140.0);
}
