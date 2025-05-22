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
  String _selectedCondition = 'All';

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
    _applySorting(_featuredProducts);
  }

  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    
    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true);
      
      // Apply category filter
      if (_selectedCategory != 'All') {
        query = query.where('category', isEqualTo: _selectedCategory.toLowerCase());
      }
      
      QuerySnapshot result = await query.limit(20).get();
      
      List<Product> products = result.docs
          .map((doc) => Product.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      
      // Apply price range filter locally
      products = products.where((product) => 
          product.price >= _priceRange.start && 
          product.price <= _priceRange.end
      ).toList();
      
      // Apply condition filter locally
      if (_selectedCondition != 'All') {
        products = products.where((product) => 
            product.condition.toLowerCase() == _selectedCondition.toLowerCase()
        ).toList();
      }
      
      // Apply sorting
      _applySorting(products);
      
      setState(() {
        _featuredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error filtering products: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applySorting(List<Product> products) {
    switch (_sortBy) {
      case 'price_low':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        // Assuming you have a createdAt field
        products.sort((a, b) => b.id.compareTo(a.id)); // Fallback to ID
        break;
      case 'popular':
        // You'd need a popularity field or view count
        break;
    }
  }

  void applySearchFilter(String searchQuery) {
    if (searchQuery.isEmpty) {
      _loadFeaturedProducts();
      return;
    }
    
    setState(() => _isLoading = true);
    
    // Filter current products by search query
    final filtered = _featuredProducts.where((product) {
      final name = product.name.toLowerCase();
      final brand = product.brand.toLowerCase();
      final category = product.category.toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
             brand.contains(searchQuery.toLowerCase()) ||
             category.contains(searchQuery.toLowerCase());
    }).toList();
    
    setState(() {
      _featuredProducts = filtered;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
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
              
              // Condition Chips
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildConditionChips(),
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
                        onChangeEnd: (RangeValues values) {
                          _applyFilters(); // Apply filters when user finishes sliding
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
        ),
        _buildFilterOverlay(),
      ],
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

  Widget _buildConditionChips() {
    final conditions = ['All', 'Like New', 'Good', 'Fair', 'Vintage'];
    
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: conditions.length,
        itemBuilder: (context, index) {
          final condition = conditions[index];
          final isSelected = _selectedCondition == condition;
          
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCondition = condition;
                });
                _applyFilters();
              },
            ),
          );
        },
      ),
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  // Show loading overlay when filters are being applied
  Widget _buildFilterOverlay() {
    return _isLoading
        ? Container(
            color: Colors.white.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Applying filters...'),
                ],
              ),
            ),
          )
        : SizedBox.shrink();
  }

  // Show how many filters are active
  Widget _buildActiveFiltersCount() {
    int activeFilters = 0;
    if (_selectedCategory != 'All') activeFilters++;
    if (_selectedCondition != 'All') activeFilters++;
    if (_priceRange.start != 0 || _priceRange.end != 200) activeFilters++;
    
    return activeFilters > 0
        ? Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$activeFilters filters active',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          )
        : SizedBox.shrink();
  }
}