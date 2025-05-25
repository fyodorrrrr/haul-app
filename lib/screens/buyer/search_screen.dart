import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/brand_filter_widget.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/brand_logo_service.dart';
import '/screens/buyer/product_details_screen.dart';
import '/providers/user_profile_provider.dart';
import '../../helpers/responsive_helper.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  
  const SearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<String> _selectedBrands = [];
  List<String> _selectedCategories = [];
  String _sortBy = 'newest';
  
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  
  @override
  void initState() {
    super.initState();
    
    // Handle initial query
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch();
    }
    
    // ✅ Auto-focus search bar when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery == null || widget.initialQuery!.isEmpty) {
        _searchFocusNode.requestFocus();
      }
      
      // ✅ Handle navigation arguments for brand filter with better null checking
      try {
        final route = ModalRoute.of(context);
        if (route?.settings.arguments != null) {
          final args = route!.settings.arguments;
          Map<String, dynamic>? argsMap;
          
          if (args is Map<String, dynamic>) {
            argsMap = args;
          } else if (args is Map) {
            argsMap = Map<String, dynamic>.from(args);
          }
          
          // ✅ Better null checking for brandFilter
          if (argsMap != null && 
              argsMap.containsKey('brandFilter') && 
              argsMap['brandFilter'] != null &&
              argsMap['brandFilter'].toString().isNotEmpty) {
            final brandFilter = argsMap['brandFilter'].toString();
            print('🔥 Setting brand filter: $brandFilter');
            
            setState(() {
              _selectedBrands = [brandFilter];
              _hasSearched = true;
            });
            _performSearch();
          }
        }
      } catch (e) {
        print('❌ Error handling navigation arguments: $e');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if ((_searchController.text.trim().isEmpty) && 
        (_selectedBrands.isEmpty) && 
        (_selectedCategories.isEmpty)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      List<Product> allProducts = await productProvider.getAllProducts();
      
      List<Product> filteredProducts = allProducts.where((product) {
        if (product == null) return false;
        
        // Text search with null checks
        bool matchesText = true;
        if (_searchController.text.trim().isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          final productName = product.name?.toLowerCase() ?? '';
          final productDescription = product.description?.toLowerCase() ?? '';
          final productBrand = product.brand?.toLowerCase() ?? '';
          final productCategory = product.category?.toLowerCase() ?? '';
          
          matchesText = productName.contains(query) ||
                       productDescription.contains(query) ||
                       productBrand.contains(query) ||
                       productCategory.contains(query);
        }

        // Brand filter
        bool matchesBrand = true;
        if (_selectedBrands.isNotEmpty && product.brand != null) {
          if (_selectedBrands.contains('Other Brands')) {
            final knownBrands = BrandLogoService.getAllKnownBrands();
            matchesBrand = !knownBrands.contains(product.brand!) ||
                         _selectedBrands.any((brand) => brand != 'Other Brands' && brand == product.brand);
          } else {
            matchesBrand = _selectedBrands.contains(product.brand!);
          }
        } else if (_selectedBrands.isNotEmpty && product.brand == null) {
          matchesBrand = false;
        }

        // Category filter
        bool matchesCategory = _selectedCategories.isEmpty || 
                            (product.category != null && _selectedCategories.contains(product.category!));

        // ✅ Remove price filter logic completely

        return matchesText && matchesBrand && matchesCategory;
      }).toList();

      _sortProducts(filteredProducts);

      setState(() {
        _searchResults = filteredProducts;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Search error: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching products: $e')),
        );
      }
    }
  }

  void _sortProducts(List<Product> products) {
    switch (_sortBy) {
      case 'price_low':
        products.sort((a, b) => (a.sellingPrice ?? 0).compareTo(b.sellingPrice ?? 0));
        break;
      case 'price_high':
        products.sort((a, b) => (b.sellingPrice ?? 0).compareTo(a.sellingPrice ?? 0));
        break;
      case 'newest':
        products.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'oldest':
        products.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
        break;
      case 'name_az':
        products.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        break;
      case 'name_za':
        products.sort((a, b) => (b.name ?? '').compareTo(a.name ?? ''));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search & Filter',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
          if (_hasActiveFilters())
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearAllFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Active filters
          if (_hasActiveFilters()) _buildActiveFilters(),
          
          // Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search products, brands, categories...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                            _hasSearched = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (value) => _performSearch(),
              onChanged: (value) => setState(() {}),
            ),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: _performSearch,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  // ✅ Remove price range from active filters:

  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    // Brand filters
    for (String brand in _selectedBrands) {
      filterChips.add(
        Container(
          margin: EdgeInsets.only(right: 8, bottom: 6),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.business, size: 14, color: Colors.blue[700]),
              SizedBox(width: 4),
              Text(
                brand,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBrands.remove(brand);
                  });
                  _performSearch();
                },
                child: Icon(Icons.close, size: 14, color: Colors.blue[700]),
              ),
            ],
          ),
        ),
      );
    }

    // Category filters
    for (String category in _selectedCategories) {
      filterChips.add(
        Container(
          margin: EdgeInsets.only(right: 8, bottom: 6),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.category, size: 14, color: Colors.green[700]),
              SizedBox(width: 4),
              Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
              SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategories.remove(category);
                  });
                  _performSearch();
                },
                child: Icon(Icons.close, size: 14, color: Colors.green[700]),
              ),
            ],
          ),
        ),
      );
    }

    if (filterChips.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active Filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: _clearAllFilters,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[600],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            children: filterChips,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return _buildSearchSuggestions();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return Column(
      children: [
        // Results header with sort
        _buildResultsHeader(),
        
        // Products grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_searchResults[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Searches',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Nike', 'Vintage', 'Denim', 'Streetwear', 'Y2K', 'Adidas', 'Supreme'
            ].map((suggestion) => ActionChip(
              label: Text(suggestion),
              onPressed: () {
                _searchController.text = suggestion;
                _performSearch();
              },
            )).toList(),
          ),
          SizedBox(height: 24),
          Text(
            'Browse by Category',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Footwear', 'Accessories'
            ].map((category) => ActionChip(
              label: Text(category),
              onPressed: () {
                setState(() {
                  _selectedCategories = [category];
                });
                _performSearch();
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearAllFilters,
            child: Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_searchResults.length} results found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          PopupMenuButton<String>(
            initialValue: _sortBy,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 16),
                SizedBox(width: 4),
                Text(
                  _getSortDisplayName(_sortBy),
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _performSearch();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'newest', child: Text('Newest First')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
              PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
              PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
              PopupMenuItem(value: 'name_az', child: Text('Name: A-Z')),
              PopupMenuItem(value: 'name_za', child: Text('Name: Z-A')),
            ],
          ),
        ],
      ),
    );
  }

  // Replace _buildProductCard method with this responsive version:
  Widget _buildProductCard(Product product) {
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final userId = userProfileProvider.userProfile != null
        ? userProfileProvider.userProfile!.uid
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(
                product: product,
                userId: userId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(ResponsiveHelper.getCardBorderRadius(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image - responsive height
            Container(
              height: ResponsiveHelper.getSearchImageHeight(context),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ResponsiveHelper.getCardBorderRadius(context)),
                ),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ResponsiveHelper.getCardBorderRadius(context)),
                ),
                child: (product.images != null && product.images!.isNotEmpty)
                    ? Image.network(
                        product.images!.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: ResponsiveHelper.getSearchImageHeight(context),
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: ResponsiveHelper.getIconSize(context),
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: ResponsiveHelper.getIconSize(context),
                          ),
                        ),
                      ),
              ),
            ),
            
            // Product details - responsive padding and text
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveHelper.getCardPadding(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name - responsive font size with overflow protection
                    Expanded(
                      flex: 2,
                      child: Text(
                        product.name ?? 'Unknown Product',
                        style: GoogleFonts.poppins(
                          fontSize: ResponsiveHelper.getBodyFontSize(context),
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    SizedBox(height: ResponsiveHelper.isSmallScreen(context) ? 4 : 6),
                    
                    // Price and brand row - fixed height to prevent overflow
                    SizedBox(
                      height: ResponsiveHelper.isSmallScreen(context) ? 32 : 36,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price
                          Text(
                            '₱${(product.sellingPrice ?? 0).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontSize: ResponsiveHelper.getPriceFontSize(context),
                              fontWeight: FontWeight.w600,
                              color: Colors.green[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: 2),
                          
                          // Brand - with overflow protection
                          Expanded(
                            child: Text(
                              product.brand ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontSize: ResponsiveHelper.getCaptionFontSize(context),
                                color: Colors.grey[600],
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  // ✅ Complete filter redesign - replace entire _showFilterBottomSheet method:

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7, // ✅ Reduced height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedBrands.clear();
                        _selectedCategories.clear();
                        // ✅ Remove price range reset
                      });
                    },
                    child: Text('Reset'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performSearch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Apply'),
                  ),
                ],
              ),
            ),
            
            // Content - ✅ Remove price filter
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Remove: _buildNewPriceFilter(),
                    _buildNewCategoryFilter(),
                    SizedBox(height: 32),
                    _buildNewBrandFilter(),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Add this new category filter design:

  Widget _buildNewCategoryFilter() {
    final categories = [
      {'name': 'Tops', 'icon': Icons.checkroom},
      {'name': 'Bottoms', 'icon': Icons.architecture},
      {'name': 'Dresses', 'icon': Icons.woman},
      {'name': 'Outerwear', 'icon': Icons.dry_cleaning},
      {'name': 'Footwear', 'icon': Icons.emoji_people},
      {'name': 'Accessories', 'icon': Icons.watch},
    ];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Categories',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                if (_selectedCategories.isNotEmpty)
                  Text(
                    '${_selectedCategories.length} selected',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategories.contains(category['name']);
                
                return GestureDetector(
                  onTap: () {
                    // ✅ Update both states
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category['name']);
                      } else {
                        _selectedCategories.add(category['name'] as String);
                      }
                    });
                    setModalState(() {}); // ✅ Update modal state
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[100] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 20,
                          color: isSelected ? Colors.blue[700] : Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category['name'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.blue[800] : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.blue[600],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ✅ Replace _buildCategoryFilter with overflow-safe version:
  Widget _buildNewBrandFilter() {
    // ✅ Use real brands from your products
    final popularBrands = [
      'Nike', 'Adidas', 'Supreme', 'Gucci', 'Louis Vuitton', 
      'Prada', 'Chanel', 'Versace', 'Balenciaga', 'Off-White',
      'Vintage', 'Uniqlo', 'H&M', 'Zara', 'Forever 21'
    ];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Brands',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                if (_selectedBrands.isNotEmpty)
                  Text(
                    '${_selectedBrands.length} selected',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            Container(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: popularBrands.map((brand) {
                  final isSelected = _selectedBrands.contains(brand);
                  return GestureDetector(
                    onTap: () {
                      // ✅ Update both states
                      setState(() {
                        if (isSelected) {
                          _selectedBrands.remove(brand);
                        } else {
                          _selectedBrands.add(brand);
                        }
                      });
                      setModalState(() {}); // ✅ Update modal state
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                          ],
                          Text(
                            brand,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _hasActiveFilters() {
    return _selectedBrands.isNotEmpty ||
           _selectedCategories.isNotEmpty;
           // ✅ Remove price range checks
  }

  void _clearAllFilters() {
    setState(() {
      _selectedBrands.clear();
      _selectedCategories.clear();
      // ✅ Remove: _priceRange = RangeValues(0, 10000);
      _sortBy = 'newest';
      _searchController.clear();
      _searchResults.clear();
      _hasSearched = false;
    });
  }

  void _applyFilters() {
    _performSearch();
  }

  String _getSortDisplayName(String sortBy) {
    switch (sortBy) {
      case 'newest': return 'Newest';
      case 'oldest': return 'Oldest';
      case 'price_low': return 'Price ↑';
      case 'price_high': return 'Price ↓';
      case 'name_az': return 'A-Z';
      case 'name_za': return 'Z-A';
      default: return 'Sort';
    }
  }
}