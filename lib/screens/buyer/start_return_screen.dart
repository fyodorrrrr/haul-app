import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../utils/currency_formatter.dart'; // ✅ Add this import

class StartReturnScreen extends StatefulWidget {
  final String? orderId;
  
  const StartReturnScreen({Key? key, this.orderId}) : super(key: key);

  @override
  _StartReturnScreenState createState() => _StartReturnScreenState();
}

class _StartReturnScreenState extends State<StartReturnScreen> {
  bool _isLoading = true;
  List<OrderModel> _returnableOrders = [];
  OrderModel? _selectedOrder;
  List<Map<String, dynamic>> _selectedItems = [];
  String _returnReason = '';
  String _returnDescription = '';
  bool _isSubmitting = false;
  
  final List<String> _returnReasons = [
    'Defective or damaged item',
    'Wrong item received',
    'Item doesn\'t match description',
    'Changed my mind',
    'Item arrived too late',
    'Quality not as expected',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadReturnableOrders();
  }

  Future<void> _loadReturnableOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['delivered', 'processing', 'shipped'])
          .orderBy('createdAt', descending: true)
          .get();

      List<OrderModel> orders = [];
      for (var doc in querySnapshot.docs) {
        try {
          final order = OrderModel.fromMap(doc.id, doc.data());
          
          // Check if order is within return window (30 days)
          final daysSinceOrder = DateTime.now().difference(order.createdAt).inDays;
          if (daysSinceOrder <= 30) {
            orders.add(order);
          }
        } catch (e) {
          print('Error parsing order: $e');
        }
      }

      setState(() {
        _returnableOrders = orders;
        if (widget.orderId != null) {
          _selectedOrder = orders.firstWhere(
            (order) => order.id == widget.orderId,
            orElse: () => orders.isNotEmpty ? orders.first : OrderModel(
              id: '', 
              buyerId: '', // ✅ Add the missing buyerId parameter
              total: 0, 
              items: [], 
              createdAt: DateTime.now(), 
              status: '', 
              sellerIds: [],
              orderNumber: null, // ✅ Add orderNumber if required
            ),
          );
          if (_selectedOrder != null) {
            _initializeSelectedItems();
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading returnable orders: $e');
      setState(() => _isLoading = false);
    }
  }

  // ✅ Add this helper method to safely access item properties
  Map<String, dynamic> _getItemData(dynamic item) {
    if (item is Map<String, dynamic>) {
      return item;
    } else {
      // Handle OrderItem or other custom objects
      return {
        'name': item.name ?? 'Unknown Product',
        'price': item.price ?? 0.0,
        'quantity': item.quantity ?? 1,
        'productId': item.productId ?? '',
        'imageUrl': item.imageUrl ?? '',
        'sellerId': item.sellerId ?? '',
      };
    }
  }

  // ✅ Then update _initializeSelectedItems to use this helper
  void _initializeSelectedItems() {
    if (_selectedOrder == null) return;
    
    setState(() {
      _selectedItems = _selectedOrder!.items.map((item) {
        final itemData = _getItemData(item);
        return {
          'item': item,
          'itemData': itemData, // ✅ Store processed data separately
          'selected': false,
          'quantity': 1,
          'maxQuantity': itemData['quantity'] ?? 1,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Start Return',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _selectedOrder != null && _selectedItems.any((item) => item['selected'])
          ? _buildBottomActionBar()
          : null,
    );
  }

  Widget _buildBody() {
    if (_returnableOrders.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedOrder == null) ...[
            _buildOrderSelection(),
          ] else ...[
            _buildSelectedOrderSummary(),
            SizedBox(height: 24),
            _buildItemSelection(),
            SizedBox(height: 24),
            _buildReturnReason(),
            SizedBox(height: 24),
            _buildReturnDescription(),
            SizedBox(height: 100), // Space for bottom bar
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'No Returnable Orders',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You don\'t have any orders eligible for return at the moment.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Order to Return',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Choose from your recent orders (within 30 days)',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _returnableOrders.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(_returnableOrders[index]);
          },
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedOrder = order;
            });
            _initializeSelectedItems();
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.orderNumber ?? 'Order #${order.id.substring(0, 12)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(order.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.shopping_bag, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      '${order.items.length} items',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    Text(
                      CurrencyFormatter.format(order.total), // ✅ Changed from $ to ₱
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedOrderSummary() {
    if (_selectedOrder == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Selected Order',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedOrder = null;
                    _selectedItems.clear();
                  });
                },
                child: Text('Change'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _selectedOrder!.orderNumber ?? 'Order #${_selectedOrder!.id.substring(0, 12)}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Ordered on ${DateFormat('MMM d, yyyy').format(_selectedOrder!.createdAt)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Items to Return',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Choose which items you want to return',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _selectedItems.length,
          itemBuilder: (context, index) {
            return _buildItemCard(index);
          },
        ),
      ],
    );
  }

  // ✅ Update _buildItemCard to use itemData
  Widget _buildItemCard(int index) {
    final itemInfo = _selectedItems[index];
    final itemData = itemInfo['itemData'] as Map<String, dynamic>;
    final isSelected = itemInfo['selected'];
    final quantity = itemInfo['quantity'];
    final maxQuantity = itemInfo['maxQuantity'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 3 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        _selectedItems[index]['selected'] = value ?? false;
                      });
                    },
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemData['name'] ?? 'Product Name',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(itemData['price'] ?? 0.0), // ✅ Changed from ₱ to use formatter
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    Column(
                      children: [
                        Text(
                          'Quantity',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: quantity > 1 ? () {
                                  setState(() {
                                    _selectedItems[index]['quantity'] = quantity - 1;
                                  });
                                } : null,
                                icon: Icon(Icons.remove, size: 16),
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                              Text(
                                '$quantity',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: quantity < maxQuantity ? () {
                                  setState(() {
                                    _selectedItems[index]['quantity'] = quantity + 1;
                                  });
                                } : null,
                                icon: Icon(Icons.add, size: 16),
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason for Return',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _returnReasons.length,
          itemBuilder: (context, index) {
            final reason = _returnReasons[index];
            return RadioListTile<String>(
              title: Text(
                reason,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              value: reason,
              groupValue: _returnReason,
              onChanged: (value) {
                setState(() {
                  _returnReason = value ?? '';
                });
              },
              contentPadding: EdgeInsets.zero,
            );
          },
        ),
      ],
    );
  }

  Widget _buildReturnDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Details (Optional)',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Provide more details about the return request',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),
        TextField(
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the issue or reason in more detail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) {
            setState(() {
              _returnDescription = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    final selectedItemsCount = _selectedItems.where((item) => item['selected']).length;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$selectedItemsCount item${selectedItemsCount != 1 ? 's' : ''} selected',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Return Request',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmitReturn() ? _submitReturnRequest : null,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Submit Return Request',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmitReturn() {
    return _selectedItems.any((item) => item['selected']) &&
           _returnReason.isNotEmpty &&
           !_isSubmitting;
  }

  Future<void> _submitReturnRequest() async {
    if (!_canSubmitReturn()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final selectedItems = _selectedItems
          .where((item) => item['selected'])
          .map((item) => {
                'item': item['item'],
                'quantity': item['quantity'],
              })
          .toList();

      final returnRequest = {
        'userId': user.uid,
        'orderId': _selectedOrder!.id,
        'orderNumber': _selectedOrder!.orderNumber,
        'items': selectedItems,
        'reason': _returnReason,
        'description': _returnDescription,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('returns')
          .add(returnRequest);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            'Return Request Submitted',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Your return request has been submitted successfully. You will receive updates via email.',
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('OK'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting return request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}