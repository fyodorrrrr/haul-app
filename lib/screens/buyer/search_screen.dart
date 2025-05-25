import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/brand_filter_widget.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/brand_logo_service.dart';

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
  List<String> _selectedConditions = [];
  RangeValues _priceRange = RangeValues(0, 10000);
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
      
      // Get all products first, then filter
      List<Product> allProducts = await productProvider.getAllProducts();
      
      // ✅ Apply search filters with better null checking
      List<Product> filteredProducts = allProducts.where((product) {
        // ✅ Null check for product properties
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

        // Brand filter with null checks
        bool matchesBrand = true;
        if (_selectedBrands.isNotEmpty && product.brand != null) {
          if (_selectedBrands.contains('Other Brands')) {
            // Check if brand is not in known brands list
            final knownBrands = BrandLogoService.getAllKnownBrands();
            matchesBrand = !knownBrands.contains(product.brand!) ||
                         _selectedBrands.any((brand) => brand != 'Other Brands' && brand == product.brand);
          } else {
            matchesBrand = _selectedBrands.contains(product.brand!);
          }
        } else if (_selectedBrands.isNotEmpty && product.brand == null) {
          matchesBrand = false; // If no brand but brand filter is active
        }

        // Category filter with null checks
        bool matchesCategory = _selectedCategories.isEmpty || 
                              (product.category != null && _selectedCategories.contains(product.category!));

        // Price filter with null checks
        final sellingPrice = product.sellingPrice ?? 0;
        bool matchesPrice = sellingPrice >= _priceRange.start && 
                           sellingPrice <= _priceRange.end;

        return matchesText && matchesBrand && matchesCategory && matchesPrice;
      }).toList();

      // Apply sorting
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
          SnackBar(
            content: Text('Error searching products: $e'),
            backgroundColor: Colors.red,
          ),
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

  Widget _buildActiveFilters() {
    List<Widget> filterChips = [];

    // Brand filters
    for (String brand in _selectedBrands) {
      filterChips.add(
        FilterChip(
          label: Text(brand),
          selected: true, // ✅ Add selected parameter
          onSelected: (selected) { // ✅ Add onSelected parameter
            if (!selected) {
              setState(() {
                _selectedBrands.remove(brand);
              });
              _performSearch();
            }
          },
          onDeleted: () {
            setState(() {
              _selectedBrands.remove(brand);
            });
            _performSearch();
          },
          deleteIcon: Icon(Icons.close, size: 16),
        ),
      );
    }

    // Category filters
    for (String category in _selectedCategories) {
      filterChips.add(
        FilterChip(
          label: Text(category),
          selected: true, // ✅ Add selected parameter
          onSelected: (selected) { // ✅ Add onSelected parameter
            if (!selected) {
              setState(() {
                _selectedCategories.remove(category);
              });
              _performSearch();
            }
          },
          onDeleted: () {
            setState(() {
              _selectedCategories.remove(category);
            });
            _performSearch();
          },
          deleteIcon: Icon(Icons.close, size: 16),
        ),
      );
    }

    // Condition filters
    for (String condition in _selectedConditions) {
      filterChips.add(
        FilterChip(
          label: Text(condition),
          selected: true, // ✅ Add selected parameter
          onSelected: (selected) { // ✅ Add onSelected parameter
            if (!selected) {
              setState(() {
                _selectedConditions.remove(condition);
              });
              _performSearch();
            }
          },
          onDeleted: () {
            setState(() {
              _selectedConditions.remove(condition);
            });
            _performSearch();
          },
          deleteIcon: Icon(Icons.close, size: 16),
        ),
      );
    }

    // Price filter
    if (_priceRange.start > 0 || _priceRange.end < 10000) {
      filterChips.add(
        FilterChip(
          label: Text('₱${_priceRange.start.round()}-₱${_priceRange.end.round()}'),
          selected: true, // ✅ Add selected parameter
          onSelected: (selected) { // ✅ Add onSelected parameter
            if (!selected) {
              setState(() {
                _priceRange = RangeValues(0, 10000);
              });
              _performSearch();
            }
          },
          onDeleted: () {
            setState(() {
              _priceRange = RangeValues(0, 10000);
            });
            _performSearch();
          },
          deleteIcon: Icon(Icons.close, size: 16),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Filters',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              TextButton(
                onPressed: _clearAllFilters,
                child: Text('Clear All'),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
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

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to product detail
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Fixed product image with proper null checking
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[200],
                ),
                child: (product.images != null && product.images!.isNotEmpty) // ✅ Fix null check
                    ? Image.network(
                        product.images!.first, // ✅ Add null assertion
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, color: Colors.grey),
                          );
                        },
                      )
                    : Container(
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
              ),
            ),
            
            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Unknown Product', // ✅ Add null check
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${(product.sellingPrice ?? 0).toStringAsFixed(0)}', // ✅ Add null check
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600],
                          ),
                        ),
                        Text(
                          product.brand ?? 'Unknown', // ✅ Add null check
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _performSearch();
                    },
                    child: Text('Done'),
                  ),
                ],
              ),
            ),
            
            // Filter content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Brand filter
                    BrandFilterWidget(
                      selectedBrands: _selectedBrands,
                      onBrandsChanged: (brands) {
                        setState(() {
                          _selectedBrands = brands;
                        });
                      },
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Other filters
                    _buildPriceFilter(),
                    SizedBox(height: 24),
                    _buildCategoryFilter(),
                    SizedBox(height: 24),
                    _buildConditionFilter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 10000,
          divisions: 100,
          labels: RangeLabels(
            '₱${_priceRange.start.round()}',
            '₱${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('₱0', style: GoogleFonts.poppins(fontSize: 12)),
            Text('₱10,000+', style: GoogleFonts.poppins(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Footwear', 'Accessories'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConditionFilter() {
    final conditions = ['Like New', 'Gently Used', 'Vintage Condition', 'Well Loved'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condition',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditions.map((condition) {
            final isSelected = _selectedConditions.contains(condition);
            return FilterChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedConditions.add(condition);
                  } else {
                    _selectedConditions.remove(condition);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedBrands.isNotEmpty ||
           _selectedCategories.isNotEmpty ||
           _selectedConditions.isNotEmpty ||
           _priceRange.start > 0 ||
           _priceRange.end < 10000;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedBrands.clear();
      _selectedCategories.clear();
      _selectedConditions.clear();
      _priceRange = RangeValues(0, 10000);
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