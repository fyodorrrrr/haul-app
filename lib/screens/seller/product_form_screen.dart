import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../utils/safe_state.dart';
import '../../utils/currency_formatter.dart';

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
  
  @override
  void initState() {
    super.initState();
    
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
        safeSetState(() {
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
        const SnackBar(content: Text('Please add at least one product image')),
      );
      return;
    }
    
    if (_selectedMainCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a main category')),
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
          const SnackBar(content: Text('Selling price must be higher than cost price')),
        );
        return;
      }
      
      if (salePrice != null && salePrice >= sellingPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale price must be lower than selling price')),
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
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
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
                    const SizedBox(height: 12),
                    
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
                            margin: const EdgeInsets.only(right: 8),
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
                    
                    const SizedBox(height: 24),
                    
                    // Product Details
                    Text(
                      'Product Details',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
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
                    const SizedBox(height: 16),
                    
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
                    const SizedBox(height: 16),
                    
                    // SKU and Brand in same row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skuController,
                            decoration: InputDecoration(
                              labelText: 'SKU',
                              hintText: 'Auto-generated if empty',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _brandController,
                            decoration: InputDecoration(
                              labelText: 'Brand',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter brand';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Pricing section
                    Text(
                      'Pricing',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Cost Price & Selling Price in same row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _costPriceController,
                            decoration: InputDecoration(
                              labelText: 'Cost Price',
                              prefixText: '${CurrencyFormatter.symbol} ', // Using the utility
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceController,
                            decoration: InputDecoration(
                              labelText: 'Selling Price',
                              prefixText: '₱ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Sale Price (optional)
                    TextFormField(
                      controller: _salePriceController,
                      decoration: InputDecoration(
                        labelText: 'Sale Price (Optional)',
                        prefixText: '₱ ',
                        hintText: 'Leave empty if not on sale',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Invalid price';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Inventory section
                    Text(
                      'Inventory',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
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
                        const SizedBox(width: 16),
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
                    const SizedBox(height: 24),
                    
                    // Categories
                    Text(
                      'Categories',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Main categories
                    Text(
                      'Main Category',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      Text(
                        'Subcategory',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 24),
                      
                      // Product Status
                      Text(
                        'Product Status',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
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
                    
                    const SizedBox(height: 32),
                    
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
    );
  }

  Widget _buildImageTile({
    required bool isNetworkImage,
    required dynamic imageSource, // String for URL, File for local
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Icon(
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
}