import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // Null for new products

  const ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();
  final _brandController = TextEditingController();
  final _minimumStockController = TextEditingController();
  
  final Map<String, List<String>> _categoryMap = {
    'Tops': [
      'T-Shirts',
      'Blouses',
      'Sweaters',
      'Tank Tops',
      'Shirts',
      'Crop Tops'
    ],
    'Bottoms': [
      'Jeans',
      'Pants',
      'Shorts',
      'Skirts',
      'Leggings'
    ],
    'Dresses': [
      'Mini',
      'Midi',
      'Maxi',
      'Casual',
      'Formal'
    ],
    'Outerwear': [
      'Jackets',
      'Coats',
      'Blazers',
      'Cardigans',
      'Hoodies'
    ],
    'Activewear': [
      'Sports Tops',
      'Leggings',
      'Shorts',
      'Sweatpants',
      'Sweatshirts'
    ],
    'Footwear': [
      'Sneakers',
      'Boots',
      'Heels',
      'Sandals',
      'Flats'
    ],
    'Accessories': [
      'Bags',
      'Jewelry',
      'Hats',
      'Belts',
      'Scarves'
    ],
    'Styles': [
      'Vintage',
      'Streetwear',
      'Casual',
      'Formal',
      'Y2K',
      'Retro'
    ],
    'Condition': [
      'Like New',
      'Gently Used',
      'Vintage Condition',
      'Well Loved'
    ],
  };

  String _selectedMainCategory = '';
  String _selectedSubcategory = '';
  
  List<File> _newImageFiles = [];
  List<String> _existingImageUrls = [];
  bool _isActive = true;
  
  bool _isLoading = false;
  final _picker = ImagePicker();
  
  // Add these new state variables
  List<String> _filteredBrands = [];
  bool _showBrandDropdown = false;
  final FocusNode _brandFocusNode = FocusNode();
  String? _priceWarning;
  Color _sellingPriceColor = Colors.black;
  
  // Enhanced brand list - Focus on vintage brands
  final List<String> _popularBrands = [
    // Vintage Fashion Brands
    'Vintage', 'Retro', 'Thrifted', 'Pre-loved', 'Second-hand',
    
    // Classic Vintage Brands
    'Levi\'s Vintage', 'Wrangler Vintage', 'Lee Vintage', 'Guess Vintage',
    'Tommy Hilfiger Vintage', 'Calvin Klein Vintage', 'Ralph Lauren Vintage',
    
    // Designer Vintage
    'Chanel Vintage', 'Dior Vintage', 'Versace Vintage', 'Armani Vintage',
    'Yves Saint Laurent Vintage', 'Givenchy Vintage', 'Prada Vintage',
    
    // Vintage Sportswear
    'Nike Vintage', 'Adidas Vintage', 'Champion Vintage', 'Converse Vintage',
    'Reebok Vintage', 'Puma Vintage', 'Fila Vintage',
    
    // Vintage Casual
    'Gap Vintage', 'Old Navy Vintage', 'American Eagle Vintage',
    'Hollister Vintage', 'Abercrombie Vintage',
    
    // Local Vintage/Thrift
    'Local Vintage', 'Philippine Vintage', 'Imported Vintage',
    'Deadstock', 'NOS (New Old Stock)', 'Vintage Band Tee',
    
    // Era-specific
    '70s Vintage', '80s Vintage', '90s Vintage', '2000s Vintage',
    'Y2K', 'Grunge Era', 'Punk Era',
    
    // Generic Categories
    'Unknown Brand', 'No Brand/Generic', 'Unbranded Vintage',
    'Custom Vintage', 'Handmade Vintage', 'Reconstructed',
  ];

  @override
  void initState() {
    super.initState();
    _filteredBrands = _popularBrands;
    
    // Add brand focus listener with better state management
    _brandFocusNode.addListener(() {
      if (_brandFocusNode.hasFocus) {
        setState(() {
          _showBrandDropdown = true;
          if (_brandController.text.isEmpty) {
            _filteredBrands = _popularBrands;
          }
        });
      }
    });
    
    // Add listener to hide dropdown when tapping outside
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Add a global tap listener to close dropdown
      }
    });
    
    // If editing, populate form with existing data
    if (widget.product != null) {
      final product = widget.product!;
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _costPriceController.text = product.costPrice.toString();
      _sellingPriceController.text = product.sellingPrice.toString();
      _salePriceController.text = product.salePrice?.toString() ?? '';
      _stockController.text = product.currentStock.toString(); // Fixed: Changed from 'stock' to 'currentStock'
      _skuController.text = product.sku;
      _brandController.text = product.brand;
      _minimumStockController.text = product.minimumStock.toString();
      
      // Initialize categories from product
      _selectedMainCategory = product.category;
      _selectedSubcategory = product.subcategory;
      
      // Initialize images array
      _existingImageUrls = List.from(product.images); // Fixed: Changed from 'imageUrls' to 'images'
      _isActive = product.isActive;
    } else {
      // Set defaults for new products
      _minimumStockController.text = '5';
    }
  }
  
  @override
  void dispose() {
    _brandFocusNode.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _brandController.dispose();
    _minimumStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
        if (result != null) {
        if (!mounted) return;
        setState(() {
          _newImageFiles.add(File(result.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  void _removeNewImage(int index) {
    safeSetState(() {
      _newImageFiles.removeAt(index);
    });
  }
  
  void _removeExistingImage(int index) {
    safeSetState(() {
      _existingImageUrls.removeAt(index);
    });
  }
  
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_existingImageUrls.isEmpty && _newImageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one product image')),
      );
      return;
    }
    
    if (_selectedMainCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a main category')),
      );
      return;
    }
    
    safeSetState(() => _isLoading = true);
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    bool success;
    
    try {
      final costPrice = double.parse(_costPriceController.text);
      final sellingPrice = double.parse(_sellingPriceController.text);
      final salePrice = _salePriceController.text.isNotEmpty 
          ? double.parse(_salePriceController.text) 
          : null;
      final stock = int.parse(_stockController.text);
      final minimumStock = int.parse(_minimumStockController.text);
      
      // Validate pricing
      if (sellingPrice <= costPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selling price must be higher than cost price')),
        );
        return;
      }
      
      if (salePrice != null && salePrice >= sellingPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale price must be lower than selling price')),
        );
        return;
      }
      
      // If stock is 0, force isActive to false
      if (stock == 0) {
        _isActive = false;
      }
      
      if (widget.product == null) {
        // Add new product - Updated parameters to match enhanced ProductProvider
        success = await provider.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          stock: stock,
          images: _newImageFiles,
          category: _selectedMainCategory,
          brand: _brandController.text.trim(),
          sku: _skuController.text.trim(),
          subcategory: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : _selectedMainCategory,
          salePrice: salePrice,
          minimumStock: minimumStock,
        );
      } else {
        // Update existing product - Updated parameters to match enhanced ProductProvider
        success = await provider.updateProduct(
          productId: widget.product!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          stock: stock,
          newImages: _newImageFiles,
          existingImageUrls: _existingImageUrls,
          category: _selectedMainCategory,
          brand: _brandController.text.trim(),
          isActive: _isActive,
          subcategory: _selectedSubcategory.isNotEmpty ? _selectedSubcategory : _selectedMainCategory,
          salePrice: salePrice,
          minimumStock: minimumStock,
          sku: _skuController.text.trim(),
        );
      }
      
      if (!mounted) return;
      
      if (success) {
        Navigator.of(context).pop(); // Go back to product listing
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to save product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) safeSetState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.product != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'Add New Product',
          style: GoogleFonts.poppins(),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator()) 
          : GestureDetector(
              onTap: () {
                // Close brand dropdown when tapping outside
                if (_showBrandDropdown) {
                  setState(() {
                    _showBrandDropdown = false;
                  });
                  _brandFocusNode.unfocus();
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Images
                      Text(
                        'Product Images',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Image Gallery
                      Container(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // Existing images
                            ..._existingImageUrls.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              return _buildImageTile(
                                isNetworkImage: true,
                                imageSource: url,
                                onRemove: () => _removeExistingImage(index),
                              );
                            }),
                            
                            // New images
                            ..._newImageFiles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              return _buildImageTile(
                                isNetworkImage: false,
                                imageSource: file,
                                onRemove: () => _removeNewImage(index),
                              );
                            }),
                            
                            // Add image button
                            Container(
                              width: 100,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                onPressed: _pickImage,
                                icon: Icon(Icons.add_a_photo, color: theme.primaryColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Product Details
                      Text(
                        'Product Details',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a product name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a product description';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // SKU and Brand in same row - FIXED ALIGNMENT
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Key fix for alignment
                        children: [
                          Expanded(
                            child: _buildSKUField(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBrandSelector(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Pricing section
                      _buildPricingSection(),
                      
                      SizedBox(height: 16),
                      
                      // Inventory section
                      Text(
                        'Inventory',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Stock & Minimum Stock in same row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              decoration: InputDecoration(
                                labelText: 'Current Stock',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minimumStockController,
                              decoration: InputDecoration(
                                labelText: 'Minimum Stock',
                                hintText: 'Low stock alert level',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Categories
                      Text(
                        'Categories',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Main categories
                      Text(
                        'Main Category',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categoryMap.keys.map((category) {
                          final isSelected = _selectedMainCategory == category;
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              safeSetState(() {
                                if (selected) {
                                  _selectedMainCategory = category;
                                  // Reset subcategory when main category changes
                                  _selectedSubcategory = '';
                                } else {
                                  _selectedMainCategory = '';
                                  _selectedSubcategory = '';
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      // Subcategories - only show if a main category is selected
                      if (_selectedMainCategory.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text(
                          'Subcategory',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (_categoryMap[_selectedMainCategory] ?? []).map((subcategory) {
                            final isSelected = _selectedSubcategory == subcategory;
                            return FilterChip(
                              label: Text(subcategory),
                              selected: isSelected,
                              onSelected: (selected) {
                                safeSetState(() {
                                  if (selected) {
                                    _selectedSubcategory = subcategory;
                                  } else {
                                    _selectedSubcategory = '';
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      if (isEditing) ...[
                        SizedBox(height: 24),
                        
                        // Product Status
                        Text(
                          'Product Status',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Active'),
                          subtitle: Text(
                            int.tryParse(_stockController.text) == 0
                                ? 'Out of stock items cannot be activated'
                                : 'Product is visible to customers'
                          ),
                          value: _isActive,
                          // Disable the switch when stock is 0
                          onChanged: int.tryParse(_stockController.text) == 0
                              ? null  // This disables the switch
                              : (value) {
                                  safeSetState(() {
                                    _isActive = value;
                                  });
                                },
                        ),
                      ],
                      
                      SizedBox(height: 32),
                      
                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isEditing ? 'UPDATE PRODUCT' : 'ADD PRODUCT',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  Widget _buildImageTile({
    required bool isNetworkImage,
    required dynamic imageSource, // Fixed: comma instead of semicolon
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          isNetworkImage
              ? Image.network(
                  imageSource as String,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  },
                )
              : Image.file(
                  imageSource as File,
                  fit: BoxFit.cover,
                ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSKUField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SKU (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _skuController,
          decoration: InputDecoration(
            hintText: 'Auto-generated if empty',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: IconButton(
              icon: const Icon(Icons.auto_fix_high, size: 20),
              onPressed: _generateSKU,
              tooltip: 'Generate SKU',
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_-]')),
          ],
          validator: (value) {
            if (value != null && value.trim().isNotEmpty) {
              if (value.trim().length < 3) {
                return 'SKU must be at least 3 characters';
              }
              if (value.trim().length > 50) {
                return 'SKU must be less than 50 characters';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'SKU helps you track inventory. Leave empty for auto-generation.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _generateSKU() {
    final brand = _brandController.text.trim();
    final category = _selectedMainCategory;
    
    if (brand.isNotEmpty && category.isNotEmpty) {
      final brandPrefix = brand.length >= 3 ? brand.substring(0, 3).toUpperCase() : brand.toUpperCase();
      final categoryPrefix = category.length >= 3 ? category.substring(0, 3).toUpperCase() : category.toUpperCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      
      final generatedSKU = '$brandPrefix-$categoryPrefix-$timestamp';
      _skuController.text = generatedSKU;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill brand and category first to generate SKU'),
        ),
      );
    }
  }
  
  Widget _buildBrandSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brand *',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        
        TextFormField(
          controller: _brandController,
          focusNode: _brandFocusNode,
          decoration: InputDecoration(
            hintText: 'Search or type vintage brand name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_brandController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _clearBrandSelection,
                  ),
                IconButton(
                  icon: Icon(
                    _showBrandDropdown ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showBrandDropdown = !_showBrandDropdown;
                      if (_showBrandDropdown) {
                        _brandFocusNode.requestFocus();
                      } else {
                        _brandFocusNode.unfocus();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          onChanged: (value) {
            setState(() {
              _filteredBrands = _popularBrands
                  .where((brand) => brand.toLowerCase().contains(value.toLowerCase()))
                  .toList();
              
              if (value.isNotEmpty && !_filteredBrands.any((brand) => 
                  brand.toLowerCase() == value.toLowerCase())) {
                _filteredBrands.insert(0, value);
              }
              
              _showBrandDropdown = true;
            });
          },
          onTap: () {
            setState(() {
              _showBrandDropdown = true;
              if (_brandController.text.isEmpty) {
                _filteredBrands = _popularBrands;
              }
            });
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please select or enter a brand';
            }
            if (value.trim().length > 50) {
              return 'Brand name must be less than 50 characters';
            }
            return null;
          },
        ),
        
        // Dropdown positioned properly to not affect layout
        if (_showBrandDropdown && _filteredBrands.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filteredBrands.length,
              itemBuilder: (context, index) {
                final brand = _filteredBrands[index];
                final isVintageBrand = _popularBrands.contains(brand);
                final isSelected = _brandController.text == brand;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                    border: index < _filteredBrands.length - 1 
                        ? Border(bottom: BorderSide(color: Colors.grey[200]!))
                        : null,
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Icon(
                      isVintageBrand ? Icons.history : Icons.edit,
                      size: 16,
                      color: isVintageBrand ? Colors.brown : Colors.grey,
                    ),
                    title: Text(
                      brand,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : 
                                    isVintageBrand ? FontWeight.w500 : FontWeight.w400,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    subtitle: !isVintageBrand ? Text(
                      'Custom brand',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ) : brand.contains('Vintage') || brand.contains('70s') || brand.contains('80s') || brand.contains('90s') || brand.contains('2000s') ? Text(
                      'Era-specific vintage',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.brown[600]),
                    ) : null,
                    onTap: () {
                      _selectBrand(brand);
                    },
                  ),
                );
              },
            ),
          ),
      
      const SizedBox(height: 8),
      Text(
        'Search from our vintage brand list or add your own.',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}
  
  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _costPriceController,
                decoration: InputDecoration(
                  labelText: 'Cost Price *',
                  prefixText: '₱ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: 'Amount you paid for this item',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid price';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Must be greater than 0';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                  _validateSellingPrice(_sellingPriceController.text);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _sellingPriceController,
                decoration: InputDecoration(
                  labelText: 'Selling Price *',
                  prefixText: '₱ ',
                  hintText: '0.00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _sellingPriceColor),
                  ),
                  helperText: 'Your selling price',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: _validateSellingPrice,
                onChanged: (value) => setState(() {}),
              ),
            ),
          ],
        ),
        
        // Price feedback
        if (_priceWarning != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _sellingPriceColor.withOpacity(0.1),
              border: Border.all(color: _sellingPriceColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _sellingPriceColor == Colors.red ? Icons.error :
                  _sellingPriceColor == Colors.orange ? Icons.warning :
                  _sellingPriceColor == Colors.blue ? Icons.info :
                  Icons.check_circle,
                  color: _sellingPriceColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _priceWarning!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _sellingPriceColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Sale Price with discount calculator
        TextFormField(
          controller: _salePriceController,
          decoration: InputDecoration(
            labelText: 'Sale Price (Optional)',
            prefixText: '₱ ',
            hintText: 'Leave empty if not on sale',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            helperText: _calculateDiscountPercentage(),
            suffixIcon: _sellingPriceController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.calculate),
                    onPressed: _showDiscountCalculator,
                    tooltip: 'Quick discount calculator',
                  )
                : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: _validateSalePrice,
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  // Add these validation methods
  String? _validateSellingPrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    if (double.tryParse(value) == null) {
      return 'Invalid price';
    }
    
    final sellingPrice = double.parse(value);
    final costPrice = double.tryParse(_costPriceController.text);
    
    if (sellingPrice <= 0) {
      return 'Must be greater than 0';
    }
    
    if (costPrice != null && costPrice > 0) {
      if (sellingPrice <= costPrice) {
        setState(() {
          _sellingPriceColor = Colors.red;
          _priceWarning = 'No profit - selling price must be higher than cost';
        });
        return 'Must be higher than cost price';
      }
      
      final markup = ((sellingPrice - costPrice) / costPrice) * 100;
      
      if (markup < 20) {
        setState(() {
          _sellingPriceColor = Colors.orange;
          _priceWarning = 'Low profit margin: ${markup.toStringAsFixed(1)}%';
        });
      } else if (markup > 300) {
        setState(() {
          _sellingPriceColor = Colors.blue;
          _priceWarning = 'High markup: ${markup.toStringAsFixed(1)}% - verify pricing';
        });
      } else {
        setState(() {
          _sellingPriceColor = Colors.green;
          _priceWarning = 'Good profit margin: ${markup.toStringAsFixed(1)}%';
        });
      }
    }
    
    return null;
  }

  String? _validateSalePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    if (double.tryParse(value) == null) {
      return 'Invalid price';
    }
    
    final salePrice = double.parse(value);
    final sellingPrice = double.tryParse(_sellingPriceController.text);
    
    if (salePrice <= 0) {
      return 'Must be greater than 0';
    }
    
    if (sellingPrice != null && salePrice >= sellingPrice) {
      return 'Must be lower than selling price';
    }
    
    return null;
  }

  String? _calculateDiscountPercentage() {
    final salePrice = double.tryParse(_salePriceController.text);
    final sellingPrice = double.tryParse(_sellingPriceController.text);
    
    if (salePrice != null && sellingPrice != null && salePrice < sellingPrice) {
      final discount = ((sellingPrice - salePrice) / sellingPrice) * 100;
      return '${discount.toStringAsFixed(1)}% discount';
    }
    return 'Set a discounted price for promotions';
  }

  void _showDiscountCalculator() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discount Calculator', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Apply discount to selling price:', style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyDiscount(10),
                    child: const Text('10%'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyDiscount(20),
                    child: const Text('20%'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _applyDiscount(30),
                    child: const Text('30%'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _applyDiscount(double percentage) {
    final sellingPrice = double.tryParse(_sellingPriceController.text);
    if (sellingPrice != null) {
      final salePrice = sellingPrice * (1 - percentage / 100);
      _salePriceController.text = salePrice.toStringAsFixed(2);
      setState(() {});
    }
    Navigator.pop(context);
  }
    // Use setState directly with mounted check when needed
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _clearBrandSelection() {
    _brandController.clear();
    setState(() {
      _filteredBrands = _popularBrands;
      _showBrandDropdown = false;
    });
  }

  void _selectBrand(String brand) {
    _brandController.text = brand;
    setState(() {
      _showBrandDropdown = false;
    });
    _brandFocusNode.unfocus();
  }

  bool _isBrandSelected(String brand) {
    return _brandController.text.trim().toLowerCase() == brand.toLowerCase();
  }
}