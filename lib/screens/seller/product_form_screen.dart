import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../utils/safe_state.dart';

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
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  final List<String> _categories = [
    // Clothing Types
    'T-Shirts',
    'Shirts',
    'Blouses',
    'Sweaters',
    'Jackets',
    'Coats',
    'Dresses',
    'Skirts',
    'Jeans',
    'Pants',
    'Shorts',
    
    // Styles
    'Vintage',
    'Retro',
    'Y2K',
    'Streetwear',
    'Casual',
    'Formal',
    'Bohemian',
    'Athletic',
    
    // Eras
    '90s',
    '80s',
    '70s',
    '60s',
    'Y2K',
    
    // Accessories
    'Bags',
    'Jewelry',
    'Hats',
    'Belts',
    'Scarves',
    
    // Footwear
    'Sneakers',
    'Boots',
    'Heels',
    'Sandals',
    
    // Condition types
    'Like New',
    'Gently Used',
    'Vintage Condition',
    
    // Other
    'Designer',
    'Sustainable',
    'Unisex',
    'Other',
  ];
  List<String> _selectedCategories = [];
  
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
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _selectedCategories = List.from(widget.product!.categories);
      _existingImageUrls = List.from(widget.product!.images);
      _isActive = widget.product!.isActive;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
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
    
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }
    
    safeSetState(() => _isLoading = true);
    
    final provider = Provider.of<ProductProvider>(context, listen: false);
    bool success;
    
    try {
      final price = double.parse(_priceController.text);
      final stock = int.parse(_stockController.text);
      
      if (widget.product == null) {
        // Add new product
        success = await provider.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          stock: stock,
          images: _newImageFiles,
          categories: _selectedCategories,
        );
      } else {
        // Update existing product
        success = await provider.updateProduct(
          productId: widget.product!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          stock: stock,
          newImages: _newImageFiles,
          existingImageUrls: _existingImageUrls,
          categories: _selectedCategories,
          isActive: _isActive,
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
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a product description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Price & Stock in same row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Price',
                              prefixText: '\$ ',
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
                            controller: _stockController,
                            decoration: InputDecoration(
                              labelText: 'Stock',
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
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        final isSelected = _selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            safeSetState(() {
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
                        subtitle: Text('Product is visible to customers'),
                        value: _isActive,
                        onChanged: (value) {
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
                color: Colors.black54,
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