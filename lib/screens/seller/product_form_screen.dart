import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../services/brand_logo_service.dart';
import '../../widgets/brand_logo_widget.dart';

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
  
  // Brand-related variables
  List<String> _filteredBrands = [];
  bool _showBrandDropdown = false;
  final FocusNode _brandFocusNode = FocusNode();
  String _selectedBrandCategory = 'all';
  
  List<String> get _availableBrands {
    if (_selectedBrandCategory == 'all') {
      return BrandLogoService.getAllKnownBrands();
    } else {
      return BrandLogoService.getBrandsByCategory(_selectedBrandCategory);
    }
  }

  String? _priceWarning;
  Color _sellingPriceColor = Colors.black;
  
  @override
  void initState() {
    super.initState();
    _filteredBrands = BrandLogoService.getAllKnownBrands();
    
    // Add brand focus listener
    _brandFocusNode.addListener(() {
      if (_brandFocusNode.hasFocus) {
        setState(() {
          _showBrandDropdown = true;
          if (_brandController.text.isEmpty) {
            _filteredBrands = _availableBrands;
          }
        });
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
      _stockController.text = product.currentStock.toString();
      _skuController.text = product.sku;
      _brandController.text = product.brand;
      _minimumStockController.text = product.minimumStock.toString();
      
      _selectedMainCategory = product.category;
      _selectedSubcategory = product.subcategory;
      _existingImageUrls = List.from(product.images);
      _isActive = product.isActive;
    } else {
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

  // Safe setState method
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
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

  void _onBrandSearchChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _filteredBrands = _availableBrands;
      } else {
        final knownMatches = _availableBrands
            .where((brand) => brand.toLowerCase().contains(value.toLowerCase()))
            .toList();
        
        _filteredBrands = knownMatches;
        
        if (value.isNotEmpty && !_filteredBrands.any((brand) => 
            brand.toLowerCase() == value.toLowerCase())) {
          _filteredBrands.insert(0, value);
        }
      }
      
      _showBrandDropdown = true;
    });
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'sports': return 'Sports & Athletic';
      case 'luxury': return 'Luxury & Designer';
      case 'streetwear': return 'Streetwear';
      case 'classic': return 'Classic Fashion';
      case 'contemporary': return 'Contemporary';
      case 'basic': return 'Basic & Essentials';
      default: return 'Other';
    }
  }

  void _selectBrand(String brand) {
    _brandController.text = brand;
    setState(() {
      _showBrandDropdown = false;
    });
    _brandFocusNode.unfocus();
    
    if (BrandLogoService.isOtherBrand(brand)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Custom brand "$brand" will be displayed as "Other Brands" in filters',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _clearBrandSelection() {
    _brandController.clear();
    setState(() {
      _filteredBrands = _availableBrands;
      _showBrandDropdown = false;
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
      
      if (stock == 0) {
        _isActive = false;
      }
      
      if (widget.product == null) {
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
        Navigator.of(context).pop();
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
                      
                      // SKU and Brand as vertical list
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSKUField(),
                          const SizedBox(height: 20),
                          _buildBrandSelector(),
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

                      // Subcategories
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
                          onChanged: int.tryParse(_stockController.text) == 0
                              ? null
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
    required dynamic imageSource,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code, size: 20, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text(
                'SKU (Stock Keeping Unit)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  'Optional',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          TextFormField(
            controller: _skuController,
            decoration: InputDecoration(
              hintText: 'Enter SKU or leave empty for auto-generation',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: Container(
                margin: EdgeInsets.all(4),
                child: ElevatedButton.icon(
                  onPressed: _generateSKU,
                  icon: Icon(Icons.auto_fix_high, size: 16),
                  label: Text(
                    'Generate',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size(0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
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
          
          SizedBox(height: 12),
          
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SKU helps you track inventory. If left empty, we\'ll auto-generate one using brand and category.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBrandSelector() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildBrandIcon(),
              SizedBox(width: 8),
              Text(
                'Brand',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'Required',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[600],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Brand Category Filter
          Text(
            'Brand Category',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          _buildBrandCategoryFilter(),
          SizedBox(height: 16),
          
          // Brand Search Field
          Text(
            'Search or Enter Brand',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _brandController,
            focusNode: _brandFocusNode,
            decoration: InputDecoration(
              hintText: 'Search brand or type custom name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Container(
                padding: EdgeInsets.all(12),
                child: BrandLogoWidget(
                  brandName: _brandController.text.trim().isEmpty ? 'Default' : _brandController.text.trim(),
                  size: 20,
                  circular: true,
                  showBorder: false,
                ),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_brandController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                      onPressed: _clearBrandSelection,
                    ),
                  IconButton(
                    icon: Icon(
                      _showBrandDropdown ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Colors.grey[600],
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
            onChanged: _onBrandSearchChanged,
            onTap: () {
              setState(() {
                _showBrandDropdown = true;
                if (_brandController.text.isEmpty) {
                  _filteredBrands = _availableBrands;
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
          
          // Brand Dropdown
          if (_showBrandDropdown && _filteredBrands.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8),
              child: _buildBrandDropdown(),
            ),
      
        SizedBox(height: 12),
        _buildBrandHelper(),
      ],
    )
  );
  }

  // ✅ Alternative: Grid layout for brand categories:

  Widget _buildBrandCategoryFilter() {
    final categories = [
      {'key': 'all', 'label': 'All', 'icon': Icons.apps},
      {'key': 'sports', 'label': 'Sports', 'icon': Icons.sports},
      {'key': 'luxury', 'label': 'Luxury', 'icon': Icons.diamond},
      {'key': 'streetwear', 'label': 'Street', 'icon': Icons.style},
      {'key': 'classic', 'label': 'Classic', 'icon': Icons.history_edu},
      {'key': 'contemporary', 'label': 'Modern', 'icon': Icons.face},
      {'key': 'basic', 'label': 'Basic', 'icon': Icons.check_circle_outline},
    ];

    return Container(
      width: double.infinity,
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // ✅ 4 buttons per row
          childAspectRatio: 1.5, // ✅ Width to height ratio
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedBrandCategory == category['key'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBrandCategory = category['key'] as String;
                _filteredBrands = _availableBrands;
                if (_brandController.text.isNotEmpty) {
                  _onBrandSearchChanged(_brandController.text);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  SizedBox(height: 2),
                  Text(
                    category['label'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandIcon() {
    final brandName = _brandController.text.trim();
    
    if (brandName.isEmpty) {
      return Icon(Icons.business, color: Colors.grey[400]);
    }
    
    return Container(
      width: 24,
      height: 24,
      margin: EdgeInsets.all(12),
      child: BrandLogoWidget(
        brandName: brandName,
        size: 24,
        circular: true,
        showBorder: false,
      ),
    );
  }

  Widget _buildBrandDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      constraints: BoxConstraints(maxHeight: 240),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  '${_filteredBrands.length} brands found',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showBrandDropdown = false;
                    });
                  },
                  child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          // Brand List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _filteredBrands.length,
              itemBuilder: (context, index) {
                final brand = _filteredBrands[index];
                final isKnownBrand = BrandLogoService.isKnownBrand(brand);
                final hasLogo = BrandLogoService.hasBrandLogo(brand);
                final category = BrandLogoService.getBrandCategory(brand);
                final isSelected = _brandController.text == brand;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : null,
                    border: index < _filteredBrands.length - 1 
                        ? Border(bottom: BorderSide(color: Colors.grey[100]!))
                        : null,
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      child: BrandLogoWidget(
                        brandName: brand,
                        size: 40,
                        circular: true,
                        showBorder: true,
                      ),
                    ),
                    title: Text(
                      brand,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.blue[700] : Colors.grey[800],
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        if (hasLogo) ...[
                          Icon(Icons.verified, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            isKnownBrand ? _getCategoryDisplayName(category) : 'Custom Brand',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: isKnownBrand ? Colors.blue[600] : Colors.orange[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelected 
                        ? Icon(Icons.check_circle, size: 20, color: Colors.blue[600])
                        : (isKnownBrand 
                            ? Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400])
                            : Icon(Icons.edit, size: 16, color: Colors.orange[400])),
                    onTap: () => _selectBrand(brand),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHelper() {
    final brandName = _brandController.text.trim();
    
    if (brandName.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue[600]),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search from our curated brand list or add your own custom brand.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final isKnown = BrandLogoService.isKnownBrand(brandName);
    final hasLogo = BrandLogoService.hasBrandLogo(brandName);
    
    if (isKnown) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[100]!),
        ),
        child: Row(
          children: [
            Icon(
              hasLogo ? Icons.verified : Icons.check_circle_outline,
              size: 16,
              color: Colors.green[600],
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                hasLogo 
                    ? 'Verified brand with logo - customers will see the brand logo'
                    : 'Verified brand (logo coming soon)',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[100]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.orange[600]),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Custom brand - will be categorized as "Other Brands" in search filters',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange[700],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Pricing section
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
        SizedBox(height: 12),
        
        // Cost Price and Selling Price in same row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _costPriceController,
                decoration: InputDecoration(
                  labelText: 'Cost Price',
                  prefixText: '₱', // ✅ Changed from $ to ₱
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Must be greater than 0';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _sellingPriceController,
                decoration: InputDecoration(
                  labelText: 'Selling Price',
                  prefixText: '₱', // ✅ Changed from $ to ₱
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Must be greater than 0';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Sale Price (Optional)
        TextFormField(
          controller: _salePriceController,
          decoration: InputDecoration(
            labelText: 'Sale Price (Optional)',
            prefixText: '₱', // ✅ Changed from $ to ₱
            hintText: 'Leave empty if not on sale',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'Invalid number';
              }
              if (double.parse(value) <= 0) {
                return 'Must be greater than 0';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}