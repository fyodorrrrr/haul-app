import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:haul/widgets/product_card.dart';
import '../../models/product_model.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<Product> _featuredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 200);
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();

      setState(() {
        _featuredProducts = result.docs
            .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  void _sortProducts() {
    // Add sorting logic here
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
            child: Text(
              'Explore Collections',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Categories
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryItem(context, 'All', Icons.apps),
                _buildCategoryItem(context, 'Vintage', Icons.history),
                _buildCategoryItem(context, 'Designer', Icons.diamond),
                _buildCategoryItem(context, 'Casual', Icons.checkroom),
                _buildCategoryItem(context, 'Formal', Icons.business_center),
                _buildCategoryItem(context, 'Shoes', Icons.directions_walk),
                _buildCategoryItem(context, 'Bags', Icons.shopping_bag),
                _buildCategoryItem(context, 'Jewelry', Icons.star),
              ],
            ),
          ),
          
          // Price Range
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Text(
                  'Price Range: ',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 200,
                    divisions: 20,
                    labels: RangeLabels(
                      '\$${_priceRange.start.round()}',
                      '\$${_priceRange.end.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Featured Items Text and Sort Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Items',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              DropdownButton<String>(
                value: _sortBy,
                items: [
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                  DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                  DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  _sortProducts();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Product Grid
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadFeaturedProducts,
                    child: _featuredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                SizedBox(height: 16),
                                Text(
                                  'No items found',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Try adjusting your filters',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _featuredProducts.length,
                            itemBuilder: (context, index) {
                              return ProductCard(product: _featuredProducts[index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryItem(BuildContext context, String title, IconData icon) {
    final isSelected = _selectedCategory == title;
    
    return GestureDetector(
      onTap: () => _filterByCategory(title),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    // Add filtering logic here
  }
}