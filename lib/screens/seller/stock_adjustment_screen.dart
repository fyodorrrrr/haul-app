// Create lib/screens/seller/stock_adjustment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/inventory_provider.dart';
import '../../models/product.dart';

class StockAdjustmentScreen extends StatefulWidget {
  final Product? product;

  const StockAdjustmentScreen({Key? key, this.product}) : super(key: key);

  @override
  _StockAdjustmentScreenState createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stockController = TextEditingController();
  final _reasonController = TextEditingController();
  
  Product? _selectedProduct;
  String _adjustmentType = 'set'; // 'set', 'add', 'subtract'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _selectedProduct = widget.product;
      _stockController.text = widget.product!.currentStock.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stock Adjustment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.product == null) _buildProductSelector(provider),
                  if (_selectedProduct != null) ...[
                    _buildProductInfo(),
                    SizedBox(height: 24),
                    _buildAdjustmentTypeSelector(),
                    SizedBox(height: 16),
                    _buildStockInputField(),
                    SizedBox(height: 16),
                    _buildReasonField(),
                    SizedBox(height: 24),
                    _buildPreview(),
                    SizedBox(height: 24),
                    _buildActionButtons(provider),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductSelector(InventoryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Product',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Product>(
              isExpanded: true,
              hint: Text('Choose a product'),
              value: _selectedProduct,
              items: provider.products.map((product) => DropdownMenuItem(
                value: product,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStockColor(product.currentStock).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.currentStock}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStockColor(product.currentStock),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
              onChanged: (product) {
                setState(() {
                  _selectedProduct = product;
                  _stockController.text = product?.currentStock.toString() ?? '';
                });
              },
            ),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProductInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: _selectedProduct!.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _selectedProduct!.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[500],
                            ),
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey[500],
                        ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProduct!.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SKU: ${_selectedProduct!.sku}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Current Stock: ',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStockColor(_selectedProduct!.currentStock).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_selectedProduct!.currentStock}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStockColor(_selectedProduct!.currentStock),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adjustment Type',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption('set', 'Set To', Icons.edit, Colors.blue),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildTypeOption('add', 'Add', Icons.add, Colors.green),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildTypeOption('subtract', 'Remove', Icons.remove, Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon, Color color) {
    final isSelected = _adjustmentType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _adjustmentType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _adjustmentType == 'set' ? 'New Stock Quantity' : 'Quantity to ${_adjustmentType == 'add' ? 'Add' : 'Remove'}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _stockController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter quantity',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    final current = int.tryParse(_stockController.text) ?? 0;
                    if (current > 0) {
                      _stockController.text = (current - 1).toString();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final current = int.tryParse(_stockController.text) ?? 0;
                    _stockController.text = (current + 1).toString();
                  },
                ),
              ],
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a quantity';
            }
            final quantity = int.tryParse(value);
            if (quantity == null || quantity < 0) {
              return 'Please enter a valid positive number';
            }
            if (_adjustmentType == 'subtract' && quantity > _selectedProduct!.currentStock) {
              return 'Cannot remove more than current stock';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason for Adjustment',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter reason for stock adjustment',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please provide a reason for the adjustment';
            }
            return null;
          },
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            'New stock received',
            'Damaged goods',
            'Inventory correction',
            'Return from customer',
            'Lost/stolen',
          ].map((reason) => GestureDetector(
            onTap: () {
              _reasonController.text = reason;
            },
            child: Chip(
              label: Text(reason),
              labelStyle: GoogleFonts.poppins(fontSize: 12),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_selectedProduct == null || _stockController.text.isEmpty) {
      return SizedBox.shrink();
    }

    final inputQuantity = int.tryParse(_stockController.text) ?? 0;
    final currentStock = _selectedProduct!.currentStock;
    int newStock;

    switch (_adjustmentType) {
      case 'set':
        newStock = inputQuantity;
        break;
      case 'add':
        newStock = currentStock + inputQuantity;
        break;
      case 'subtract':
        newStock = currentStock - inputQuantity;
        break;
      default:
        newStock = currentStock;
    }

    return Card(
      elevation: 2,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Current Stock',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStockColor(currentStock).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$currentStock',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStockColor(currentStock),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.blue[600]),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'New Stock',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStockColor(newStock).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$newStock',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStockColor(newStock),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Change: ${newStock - currentStock >= 0 ? '+' : ''}${newStock - currentStock}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildActionButtons(InventoryProvider provider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _submitAdjustment(provider),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Apply Adjustment'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange[600],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitAdjustment(InventoryProvider provider) async {
    if (!_formKey.currentState!.validate() || _selectedProduct == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final inputQuantity = int.parse(_stockController.text);
      final currentStock = _selectedProduct!.currentStock;
      int newStock;

      switch (_adjustmentType) {
        case 'set':
          newStock = inputQuantity;
          break;
        case 'add':
          newStock = currentStock + inputQuantity;
          break;
        case 'subtract':
          newStock = currentStock - inputQuantity;
          break;
        default:
          newStock = currentStock;
      }

      await provider.adjustStock(
        _selectedProduct!.id,
        newStock,
        _reasonController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock adjusted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 5) return Colors.orange;
    return Colors.green;
  }

  @override
  void dispose() {
    _stockController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}