import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/wishlist_model.dart';
import '../../providers/wishlist_providers.dart';
import '../../utils/snackbar_helper.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';


class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Remove late initialization
  CardSwiperController? controller;
  // Add a key to force widget recreation when filters change
  Key _cardSwiperKey = UniqueKey();
  List<Product> _featuredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  RangeValues _priceRange = const RangeValues(0, 200);
  String _sortBy = 'newest';
  String _selectedBrand = 'All';
  bool _showFilterPanel = false;
  String? userId;

  // Add this variable to store wishlist product IDs
  Set<String> _wishlistProductIds = {};

  @override
  void initState() {
    super.initState();
    // Initialize controller
    controller = CardSwiperController();
    _loadFeaturedProducts();
    _fetchUserId();
    // Add this line to fetch wishlist on init
    _loadWishlistItems();
  }

  @override
  void dispose() {
    // Safe disposal with null check
    controller?.dispose();
    super.dispose();
  }

  // 2. Add a method to load wishlist items
  Future<void> _loadWishlistItems() async {
    if (userId == null) return;

    try {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      await wishlistProvider.fetchWishlist(userId!);

      setState(() {
        _wishlistProductIds = wishlistProvider.wishlist
            .map((item) => item.productId)
            .toSet();
      });

      print('Loaded ${_wishlistProductIds.length} wishlist items');
    } catch (e) {
      print('Error loading wishlist: $e');
    }
  }

  void _fetchUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      // Load wishlist after getting userId
      _loadWishlistItems();
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();

      List<Product> products = result.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return Product.fromMap(data);
            } catch (e) {
              print('Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<Product>()
          .toList();
      
      // Filter out products already in wishlist
      products = products.where((product) => 
          !_wishlistProductIds.contains(product.id)).toList();

      setState(() {
        _featuredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  // Keep your existing filtering and sorting functions

  @override
  Widget build(BuildContext context) {
    // Get active filters count
    int activeFilters = 0;
    if (_selectedCategory != 'All') activeFilters++;
    if (_selectedBrand != 'All') activeFilters++;
    if (_priceRange.start != 0 || _priceRange.end != 200) activeFilters++;
    
    // Listen for wishlist changes
    if (userId != null) {
      final wishlistProvider = Provider.of<WishlistProvider>(context);
      _updateWishlistIds(wishlistProvider);
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Ukay Section',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
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
      body: Stack(
        children: [
          // Top Categories Horizontal List
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              color: Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
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
          ),
          
          // Filter Indicator Bar
          if (activeFilters > 0)
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$activeFilters filters applied',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'All';
                          _selectedBrand = 'All';
                          _priceRange = RangeValues(0, 200);
                          _sortBy = 'newest';
                        });
                        _loadFeaturedProducts();
                      },
                      child: Text('Clear All', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(50, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Card Swiper Section
          Positioned(
            top: activeFilters > 0 ? 170 : 120,
            left: 0,
            right: 0,
            bottom: 100,
            child: _isLoading 
              ? Center(child: CircularProgressIndicator())
              : Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _featuredProducts.isEmpty
                  ? _buildEmptyState()
                  : CardSwiper(
                      key: _cardSwiperKey,
                      controller: controller,
                      cards: _featuredProducts
                          .map((product) => _buildProductCard(context, product, 0))
                          .toList(),
                      onSwipe: (index, direction) => _handleSwipe(index, direction),
                      padding: EdgeInsets.all(24),
                    ),
              ),
          ),
          
          // Bottom Action Buttons
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  heroTag: 'dislike',
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close, color: Colors.red, size: 32),
                  onPressed: () {
                    if (!_isLoading && _featuredProducts.isNotEmpty && controller != null) {
                      try {
                        controller!.swipeLeft();
                      } catch (e) {
                        print('Error swiping left: $e');
                      }
                    }
                  },
                ),
                SizedBox(width: 24),
                FloatingActionButton(
                  heroTag: 'like',
                  backgroundColor: Colors.white,
                  child: Icon(Icons.favorite, color: Colors.green, size: 32),
                  onPressed: () {
                    if (!_isLoading && _featuredProducts.isNotEmpty) {
                      try {
                        controller!.swipeRight();
                      } catch (e) {
                        print('Error swiping right: $e');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          
          // Filter Panel
          if (_showFilterPanel)
            _buildFilterPanel(),
          
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // Handle card swipe actions
  bool _handleSwipe(int index, CardSwiperDirection direction) {
    final product = _featuredProducts[index];
    
    if (direction == CardSwiperDirection.right) {
      // Add to wishlist on right swipe
      _addToWishlist(product);
      return true;
    } else if (direction == CardSwiperDirection.left) {
      // Just skip on left swipe
      return true;
    }
    
    return false;
  }

  // Add product to wishlist
  void _addToWishlist(Product product) async {
    if (userId == null) {
      SnackBarHelper.showSnackBar(
        context,
        'Please log in to add items to your wishlist.',
        isError: true,
      );
      return;
    }

    try {
      final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
      final isInWishlist = wishlistProvider.isInWishlist(product.id);
      
      if (!isInWishlist) {
        await wishlistProvider.addToWishlist(
          WishlistModel(
            productId: product.id,
            userId: userId!,
            productName: product.name,
            productImage: product.images.isNotEmpty ? product.images.first : '',
            productPrice: product.effectivePrice,
            addedAt: DateTime.now(),
          ),
        );
        
        // Add the product ID to our local set too
        setState(() {
          _wishlistProductIds.add(product.id);
        });
        
        SnackBarHelper.showSnackBar(
          context,
          'Added to wishlist',
          isSuccess: true,
        );
      }
    } catch (e) {
      SnackBarHelper.showSnackBar(
        context,
        'An error occurred. Please try again.',
        isError: true,
      );
    }
  }

  // Product card for swiping
  Widget _buildProductCard(BuildContext context, Product product, double percentThresholdX) {
    // Create swipe indicators
    final isLiking = percentThresholdX >= 0;
    final isDisliking = percentThresholdX < 0;
    final swipeProgress = percentThresholdX.abs();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Product Image
          Positioned.fill(
            child: product.images.isNotEmpty
              ? Image.network(
                  product.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey[500]),
                  ),
                )
              : Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey[500]),
                ),
          ),
          
          // Product Details Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          product.category,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        '\$${product.effectivePrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Like Overlay
          if (swipeProgress > 0)
            Positioned(
              top: 24,
              right: isLiking ? 24 : null,
              left: isDisliking ? 24 : null,
              child: Transform.rotate(
                angle: isLiking ? -0.2 : 0.2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isLiking ? Colors.green : Colors.red,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isLiking ? 'LIKE' : 'NOPE',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isLiking ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Empty state when no products match filters
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 72,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
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
                _selectedBrand = 'All';
                _priceRange = RangeValues(0, 200);
              });
              _loadFeaturedProducts();
            },
            icon: Icon(Icons.refresh),
            label: Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Filter panel UI
  Widget _buildFilterPanel() {
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Material(
        elevation: 8,
        child: Column(
          children: [
            // Fixed header
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
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
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => setState(() => _showFilterPanel = false),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brand',
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
                        'All', 'Nike', 'Adidas', 'Zara', 'H&M', 'Uniqlo'
                      ].map((brand) {
                        return FilterChip(
                          label: Text(brand),
                          selected: _selectedBrand == brand,
                          onSelected: (selected) {
                            setState(() {
                              _selectedBrand = brand;
                            });
                          },
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                    
                    SizedBox(height: 24),
                    
                    Text(
                      'Price Range',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('\$${_priceRange.start.round()}'),
                        Text('\$${_priceRange.end.round()}'),
                      ],
                    ),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 200,
                      divisions: 20,
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Colors.grey[300],
                      onChanged: (RangeValues values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                    
                    SizedBox(height: 24),
                    
                    Text(
                      'Sort By',
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
                        ChoiceChip(
                          label: Text('Newest'),
                          selected: _sortBy == 'newest',
                          onSelected: (selected) {
                            if (selected) setState(() => _sortBy = 'newest');
                          },
                        ),
                        ChoiceChip(
                          label: Text('Price: Low to High'),
                          selected: _sortBy == 'price_low',
                          onSelected: (selected) {
                            if (selected) setState(() => _sortBy = 'price_low');
                          },
                        ),
                        ChoiceChip(
                          label: Text('Price: High to Low'),
                          selected: _sortBy == 'price_high',
                          onSelected: (selected) {
                            if (selected) setState(() => _sortBy = 'price_high');
                          },
                        ),
                        ChoiceChip(
                          label: Text('Most Popular'),
                          selected: _sortBy == 'popular',
                          onSelected: (selected) {
                            if (selected) setState(() => _sortBy = 'popular');
                          },
                        ),
                      ],
                    ),
                    
                    // Add padding at the bottom to ensure space after scrolling
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Fixed bottom actions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showFilterPanel = false);
                        _applyFilters();
                      },
                      child: Text('Apply Filters'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'All';
                          _selectedBrand = 'All';
                          _priceRange = RangeValues(0, 200);
                          _sortBy = 'newest';
                          _showFilterPanel = false;
                        });
                        _loadFeaturedProducts();
                      },
                      child: Text('Reset Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep your existing category item widget
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

  // Apply filters and sorting to the featured products
  void _applyFilters() async {
    // First dispose the current controller safely
    controller?.dispose();
    controller = null;
    
    setState(() {
      _isLoading = true;
      // Generate new key to force CardSwiper recreation
      _cardSwiperKey = UniqueKey();
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true);

      if (_selectedCategory != 'All') {
        query = query.where('category', isEqualTo: _selectedCategory);
      }
      if (_selectedBrand != 'All') {
        query = query.where('brand', isEqualTo: _selectedBrand);
      }
      // Firestore does not support range queries on multiple fields, so we filter price after fetching
      QuerySnapshot result = await query.limit(50).get();

      List<Product> filtered = result.docs
          .map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return Product.fromMap(data);
            } catch (e) {
              print('Error parsing product ${doc.id}: $e');
              return null;
            }
          })
          .where((product) => product != null)
          .cast<Product>()
          .where((product) =>
              product.effectivePrice >= _priceRange.start &&
              product.effectivePrice <= _priceRange.end)
          .toList();

      // Sorting
      if (_sortBy == 'price_low') {
        filtered.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
      } else if (_sortBy == 'price_high') {
        filtered.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
      } else {
        // Default: newest
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // Also modify the _applyFilters method to filter out wishlist items
      filtered = filtered.where((product) => 
          !_wishlistProductIds.contains(product.id)).toList();

      setState(() {
        _featuredProducts = filtered;
        _isLoading = false;
        // Create a new controller after filters are applied
        controller = CardSwiperController();
      });
    } catch (e) {
      print('Error applying filters: $e');
      setState(() {
        _isLoading = false;
        // Create a new controller even on error
        controller = CardSwiperController();
      });
    }
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures we listen to wishlist changes
    if (userId != null) {
      final wishlistProvider = Provider.of<WishlistProvider>(context);
      _updateWishlistIds(wishlistProvider);
    }
  }
  
  // Helper method to update wishlist IDs when changed
  void _updateWishlistIds(WishlistProvider provider) {
    final newIds = provider.wishlist.map((item) => item.productId).toSet();
    
    // If wishlist has changed, update our set and refresh products
    if (!setEquals(newIds, _wishlistProductIds)) {
      setState(() {
        _wishlistProductIds = newIds;
      });
      
      // Check if we need to reload products (e.g., something was removed from wishlist)
      if (_wishlistProductIds.length < newIds.length) {
        _loadFeaturedProducts(); // Reload to show newly unwishlisted items
      }
    }
  }

  // Add this method to handle reloading products when a wishlist item is removed
  void _refreshAfterWishlistRemoval(String productId) {
    setState(() {
      _wishlistProductIds.remove(productId);
    });
    _loadFeaturedProducts();
  }
}