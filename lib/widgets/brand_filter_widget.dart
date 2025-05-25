import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/brand_logo_service.dart';
import 'brand_logo_widget.dart';

class BrandFilterWidget extends StatefulWidget {
  final List<String> selectedBrands;
  final Function(List<String>) onBrandsChanged;

  const BrandFilterWidget({
    Key? key,
    required this.selectedBrands,
    required this.onBrandsChanged,
  }) : super(key: key);

  @override
  State<BrandFilterWidget> createState() => _BrandFilterWidgetState();
}

class _BrandFilterWidgetState extends State<BrandFilterWidget> {
  String _selectedCategory = 'all';
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brands',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        
        // Category tabs
        _buildCategoryTabs(),
        SizedBox(height: 16),
        
        // Brand grid
        _buildBrandGrid(),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'key': 'all', 'label': 'All'},
      {'key': 'sports', 'label': 'Sports'},
      {'key': 'luxury', 'label': 'Luxury'},
      {'key': 'streetwear', 'label': 'Street'},
      {'key': 'classic', 'label': 'Classic'},
      {'key': 'vintage', 'label': 'Vintage'},
      {'key': 'other', 'label': 'Other'},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['key'];
          
          return Container(
            margin: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category['key']!;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandGrid() {
    List<String> brands;
    
    if (_selectedCategory == 'all') {
      brands = BrandLogoService.getAllKnownBrands();
      brands.add('Other Brands'); // Add other brands option
    } else if (_selectedCategory == 'other') {
      brands = ['Other Brands'];
    } else {
      brands = BrandLogoService.getBrandsByCategory(_selectedCategory);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: brands.map((brand) {
        final isSelected = widget.selectedBrands.contains(brand);
        final isOtherBrand = brand == 'Other Brands';
        
        return FilterChip(
          avatar: isOtherBrand 
              ? Icon(Icons.more_horiz, size: 16)
              : BrandLogoWidget(
                  brandName: brand,
                  size: 20,
                  circular: true,
                ),
          label: Text(
            brand,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            List<String> newSelection = List.from(widget.selectedBrands);
            
            if (selected) {
              newSelection.add(brand);
            } else {
              newSelection.remove(brand);
            }
            
            widget.onBrandsChanged(newSelection);
          },
        );
      }).toList(),
    );
  }
}