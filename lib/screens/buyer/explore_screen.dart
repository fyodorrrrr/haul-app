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
  bool _showFilterPanel = false;

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
    // Get active filters count
    int activeFilters = 0;
    if (_selectedCategory != 'All') activeFilters++;
    if (_selectedCondition != 'All') activeFilters++;
    if (_priceRange.start != 0 || _priceRange.end != 200) activeFilters++;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: activeFilters > 0 ? 
        FloatingActionButton(
          mini: true,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text('$activeFilters', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
        ) : null,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header Section with category navigation
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Explore Collections',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _showFilterPanel ? Icons.close : Icons.filter_list,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _showFilterPanel = !_showFilterPanel;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Categories with enhanced styling
                      SizedBox(
                        height: 110,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryItem(context, 'All', Icons.apps),
                            _buildCategoryItem(context, 'Vintage', Icons.history),
                            _buildCategoryItem(context, 'Designer', Icons.diamond_outlined),
                            _buildCategoryItem(context, 'Casual', Icons.checkroom),
                            _buildCategoryItem(context, 'Formal', Icons.business_center),
                            _buildCategoryItem(context, 'Shoes', Icons.directions_walk),
                            _buildCategoryItem(context, 'Bags', Icons.shopping_bag),
                            _buildCategoryItem(context, 'Jewelry', Icons.star),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Filter summary bar (when filters are active)
              if (activeFilters > 0)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '$activeFilters filters applied',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'All';
                              _selectedCondition = 'All';
                              _priceRange = RangeValues(0, 200);
                              _sortBy = 'newest';
                              _showFilterPanel = false;
                            });
                            _loadFeaturedProducts();
                          },
                          child: Text('Clear All'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Sort options
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Items',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.black87),
                          underline: SizedBox(), // Remove underline
                          isDense: true,
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
                      ),
                    ],
                  ),
                ),
              ),
              
              // Product Grid
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: _isLoading
                  ? SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _featuredProducts.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.5, // Fixed height constraint
                          padding: EdgeInsets.only(bottom: 80), // Extra bottom padding
                          child: Center(
                            child: SingleChildScrollView( // Make scrollable if needed
                              physics: AlwaysScrollableScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // Use min size
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.search_off, size: 64, color: Colors.grey[500]),
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'No items found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your filters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategory = 'All';
                                        _selectedCondition = 'All';
                                        _priceRange = RangeValues(0, 200);
                                      });
                                      _loadFeaturedProducts();
                                    },
                                    icon: Icon(Icons.refresh),
                                    label: Text('Reset Filters'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      textStyle: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return ProductCard(product: _featuredProducts[index]);
                          },
                          childCount: _featuredProducts.length,
                        ),
                      ),
              ),
              
              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
          
          // Expandable filter panel
          if (_showFilterPanel)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 140, 16, 0),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7, // Limit height to 70% of screen
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filter Options',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () => setState(() => _showFilterPanel = false),
                            ),
                          ],
                        ),
                        Divider(),
                        
                        // Condition Section
                        Text(
                          'Condition',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'All', 'Like New', 'Good', 'Fair', 'Vintage'
                          ].map((condition) {
                            final isSelected = _selectedCondition == condition;
                            return FilterChip(
                              label: Text(condition),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCondition = condition;
                                });
                                _applyFilters();
                              },
                              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              checkmarkColor: Theme.of(context).primaryColor,
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 24),
                        
                        // Price Range Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Price Range',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 200,
                          divisions: 20,
                          activeColor: Theme.of(context).primaryColor,
                          inactiveColor: Colors.grey[300],
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
                            _applyFilters();
                          },
                        ),
                        SizedBox(height: 24),
                        
                        // Apply & Reset buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                child: Text('Reset Filters'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: Theme.of(context).primaryColor),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedCategory = 'All';
                                    _selectedCondition = 'All';
                                    _priceRange = RangeValues(0, 200);
                                    _sortBy = 'newest';
                                  });
                                  _loadFeaturedProducts();
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                child: Text('Apply Filters'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showFilterPanel = false;
                                  });
                                  _applyFilters();
                                },
                              ),
                            ),
                          ],
                        ),
                        // Add extra bottom padding
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Loading overlay
          _buildFilterOverlay(),
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
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    spreadRadius: isSelected ? 2 : 0,
                    blurRadius: isSelected ? 8 : 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black87,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
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
    _applyFilters();
  }

  // Loading overlay with animation
  Widget _buildFilterOverlay() {
    return _isLoading
        ? Container(
            color: Colors.white.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Updating results...',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : SizedBox.shrink();
  }
}