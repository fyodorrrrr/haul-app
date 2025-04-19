import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainHomeScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  
  const MainHomeScreen({
    Key? key,
    this.userData = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 350;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // 30% OFF Banner
            _buildPromotionBanner(context),
            
            const SizedBox(height: 24),
            
            // Brands Section
            _buildSectionHeader('Brands'),
            const SizedBox(height: 12),
            _buildBrandsRow(),
            
            const SizedBox(height: 24),
            
            // For You Section
            _buildSectionHeader('For You', showSubtitle: true),
            const SizedBox(height: 12),
            _buildForYouGrid(context),
            
            // Add space at the bottom
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPromotionBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '30% OFF',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, {bool showSubtitle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (showSubtitle)
          Text(
            'BASED ON YOUR RECENT ACTIVITIES',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );
  }
  
  Widget _buildBrandsRow() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildForYouGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
} 