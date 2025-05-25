import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/brand_logo_widget.dart';
import '../../services/brand_logo_service.dart';
import 'brand_screen.dart';

class BrandsShowcaseScreen extends StatefulWidget {
  @override
  _BrandsShowcaseScreenState createState() => _BrandsShowcaseScreenState();
}

class _BrandsShowcaseScreenState extends State<BrandsShowcaseScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Brands',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Category filter
          _buildCategoryFilter(),
          
          // Brand grid
          Expanded(
            child: _buildBrandGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      {'key': 'all', 'label': 'All Brands'},
      {'key': 'luxury', 'label': 'Luxury'},
      {'key': 'streetwear', 'label': 'Streetwear'},
      {'key': 'sports', 'label': 'Sports'},
      {'key': 'vintage', 'label': 'Vintage'},
    ];

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['key'];
          
          return Container(
            margin: EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                category['label']!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category['key']!;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.black,
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandGrid() {
    List<String> brands;
    
    if (_selectedCategory == 'all') {
      brands = BrandLogoService.getAllBrands();
    } else {
      brands = BrandLogoService.getBrandsByCategory(_selectedCategory);
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: brands.length,
      itemBuilder: (context, index) {
        final brand = brands[index];
        return BrandLogoWidget(
          brandName: brand,
          size: 80,
          showText: true,
          circular: true,
          showBorder: true,
          backgroundColor: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BrandProductsScreen(brandName: brand),
              ),
            );
          },
        );
      },
    );
  }
}