import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import 'dart:math' as math;
import '../seller/order_detail_screen.dart';
import '../../utils/currency_formatter.dart'; // ✅ Add this import

class PackageTrackingScreen extends StatefulWidget {
  const PackageTrackingScreen({Key? key}) : super(key: key);

  @override
  _PackageTrackingScreenState createState() => _PackageTrackingScreenState();
}

class _PackageTrackingScreenState extends State<PackageTrackingScreen> {
  bool _isLoading = true;
  bool _isSearching = false;
  List<OrderModel> _activeOrders = [];
  final TextEditingController _trackingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    setState(() => _isLoading = true);
    
    // First run the debug query
    await _debugDatabaseQuery();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in for package tracking');
        setState(() => _isLoading = false);
        return;
      }

      print('\n🔍 Loading orders for package tracking...');
      print('User ID: ${user.uid}');

      // Try both field names
      QuerySnapshot querySnapshot;
      
      // First try userId (most likely correct based on order history)
      try {
        querySnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
        
        print('✅ Query with userId returned ${querySnapshot.docs.length} orders');
        
        if (querySnapshot.docs.isEmpty) {
          // Try buyerId as fallback
          querySnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .where('buyerId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .get();
          
          print('🔄 Fallback query with buyerId returned ${querySnapshot.docs.length} orders');
        }
        
      } catch (e) {
        print('❌ Query error: $e');
        setState(() => _isLoading = false);
        return;
      }

      List<OrderModel> orders = [];
      for (var doc in querySnapshot.docs) {
        try {
          final order = OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
          orders.add(order);
          print('✅ Successfully parsed order: ${order.id}');
        } catch (e) {
          print('❌ Error parsing order ${doc.id}: $e');
          print('Order data: ${doc.data()}');
        }
      }

      setState(() {
        _activeOrders = orders;
        _isLoading = false;
      });
      
      print('\n📊 Final results:');
      print('Total orders loaded: ${_activeOrders.length}');
      for (int i = 0; i < _activeOrders.length; i++) {
        final order = _activeOrders[i];
        print('Order $i: ${order.id} - Status: ${order.status}');
      }
      
    } catch (e) {
      print('❌ Load orders error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Track Package',
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
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Track by Order Number
                  _buildQuickTrackSection(),
                  
                  SizedBox(height: 24),
                  
                  // Active Orders Section
                  _buildActiveOrdersSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickTrackSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.search,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Quick Track',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Enter your order number to track your package',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _trackingController,
                  decoration: InputDecoration(
                    hintText: 'Enter complete order number (e.g., ORD-1748091978310)',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.receipt_long, color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    // ADD THESE VALIDATION HELPERS
                    helperText: 'Must be complete order number',
                    helperStyle: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  // ADD INPUT VALIDATION
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50), // Reasonable max length
                  ],
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _trackByOrderNumber(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Track',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Orders', // ✅ Changed from "Active Orders" to include all statuses
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        
        SizedBox(height: 12),
        
        if (_activeOrders.isEmpty)
          _buildEmptyState()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _activeOrders.length,
            itemBuilder: (context, index) {
              return _buildOrderTrackingCard(_activeOrders[index]);
            },
          ),
      ],
    );
  }

  Widget _buildOrderTrackingCard(OrderModel order) {
    final isPending = order.status.toLowerCase() == 'pending';
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final isActive = !isPending && !isCancelled;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(order.status).withOpacity(0.3),
          width: isCancelled ? 2 : 1, // ✅ Thicker border for cancelled orders
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Order Header with Status Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.orderNumber ?? 'Order #${order.id}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // ✅ Dim text for cancelled orders
                    color: isCancelled ? Colors.grey[600] : Colors.black87,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Row(
                children: [
                  // ✅ Special indicator for pending orders
                  if (isPending) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.orange[600],
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AWAITING',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // ✅ Special indicator for cancelled orders
                  if (isCancelled) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel, size: 12, color: Colors.red[600]),
                          SizedBox(width: 4),
                          Text(
                            'CANCELLED',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  // ✅ Regular status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(order.status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Order Details
          Row(
            children: [
              Icon(
                Icons.store,
                size: 16,
                color: isCancelled ? Colors.grey[400] : Colors.grey[600],
              ),
              SizedBox(width: 6),
              Text(
                order.sellerIds.isNotEmpty 
                  ? 'Seller ${order.sellerIds.first.substring(0, 8)}' 
                  : 'Unknown Seller',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isCancelled ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: isCancelled ? Colors.grey[400] : Colors.grey[600],
              ),
              SizedBox(width: 6),
              Text(
                DateFormat('MMM d, yyyy').format(order.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isCancelled ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // ✅ Conditional content based on status
          if (isPending) ...[
            // Pending order message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order is pending seller confirmation',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isCancelled) ...[
            // Cancelled order message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order has been cancelled',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Active order tracking progress
            _buildTrackingProgress(order.status),
          ],
          
          SizedBox(height: 16),
          
          // ✅ Action Buttons with different styles for different statuses
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showOrderDetails(order),
                  icon: Icon(Icons.info_outline, size: 16),
                  label: Text(
                    'View Details',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    foregroundColor: isCancelled ? Colors.grey[600] : null,
                    side: BorderSide(
                      color: isCancelled ? Colors.grey[400]! : _getStatusColor(order.status),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isActive ? () => _showTrackingDetails(order) : null,
                  icon: Icon(
                    isPending ? Icons.schedule : 
                    isCancelled ? Icons.history : 
                    Icons.local_shipping, 
                    size: 16
                  ),
                  label: Text(
                    isPending ? 'Waiting' : 
                    isCancelled ? 'History' : 
                    'Track Live',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending ? Colors.orange[400] : 
                                   isCancelled ? null : 
                                   Theme.of(context).primaryColor,
                    foregroundColor: isCancelled ? null : Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingProgress(String status) {
    final statuses = ['confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered'];
    final currentIndex = statuses.indexOf(status);
    
    return Column(
      children: [
        Row(
          children: statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final isCompleted = index <= currentIndex;
            final isActive = index == currentIndex;
            
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 3,
                            )
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            )
                          : Container(),
                    ),
                  ),
                  if (index < statuses.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        
        SizedBox(height: 8),
        
        Row(
          children: statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final statusText = _getStatusText(entry.value);
            
            return Expanded(
              child: Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: index <= currentIndex
                      ? Theme.of(context).primaryColor
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Active Orders',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You don\'t have any packages to track at the moment.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange; // ✅ Orange for pending
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red; // ✅ Red for cancelled
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  void _trackByOrderNumber() {
    final orderNumber = _trackingController.text.trim();
    if (orderNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an order number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // IMMEDIATE STRICT VALIDATION
    if (!_isValidOrderNumberFormat(orderNumber)) {
      print('❌ STRICT VALIDATION FAILED for: "$orderNumber"');
      print('   Length: ${orderNumber.length}');
      print('   Clean length: ${orderNumber.replaceAll('ORD-', '').replaceAll('#', '').trim().length}');
      _showInvalidFormatDialog(orderNumber);
      return;
    }

    setState(() => _isSearching = true);

    print('🔍 STRICT SEARCH - Looking for exact match: $orderNumber');
    print('Available orders: ${_activeOrders.length}');
    
    // Remove prefixes and clean the search term
    String searchTerm = orderNumber
        .replaceAll('ORD-', '')
        .replaceAll('#', '')
        .trim();
    
    print('🔍 Cleaned search term: $searchTerm');
    
    // ULTRA STRICT SEARCH: Only EXACT matches allowed
    OrderModel? foundOrder;
    
    for (int i = 0; i < _activeOrders.length; i++) {
      final order = _activeOrders[i];
      print('Checking order $i: ${order.id}');
      print('  Order Number: ${order.orderNumber}');
      
      // ULTRA STRICT MATCHING: Only EXACT matches, no partial matches
      bool isExactMatch = false;
      
      if (order.orderNumber != null) {
        // Exact order number match (with or without ORD- prefix)
        if (order.orderNumber == orderNumber ||
            order.orderNumber == 'ORD-$searchTerm' ||
            order.orderNumber?.replaceAll('ORD-', '') == searchTerm) {
          isExactMatch = true;
          print('✅ EXACT ORDER NUMBER MATCH');
        }
      }
      
      // Exact Order ID match (for backward compatibility)
      if (order.id == searchTerm) {
        isExactMatch = true;
        print('✅ EXACT ORDER ID MATCH');
      }
      
      if (isExactMatch) {
        foundOrder = order;
        print('✅ Found EXACT matching order: ${order.id}');
        print('✅ Order Number: ${order.orderNumber}');
        break;
      } else {
        print('❌ No exact match for this order');
      }
    }
    
    setState(() => _isSearching = false);
    
    if (foundOrder != null) {
      print('🎯 Navigating to order: ${foundOrder.id}');
      _showTrackingDetails(foundOrder);
    } else {
      print('❌ NO EXACT MATCH found for: $orderNumber');
      _showOrderNotFoundDialog(orderNumber);
    }
  }

  // MUCH STRICTER VALIDATION - REQUIRES EXACT MATCHES ONLY
  bool _isValidOrderNumberFormat(String orderNumber) {
    // Remove common prefixes for validation
    String cleanNumber = orderNumber
        .replaceAll('ORD-', '')
        .replaceAll('#', '')
        .trim();
    
    // STRICT: Must be exact length and format
    return _isValidCompleteOrderId(cleanNumber) || 
           _isValidCompleteTimestamp(cleanNumber) ||
           _isValidCompleteOrderNumber(orderNumber);
  }

  bool _isValidCompleteOrderId(String id) {
    // STRICT: Must be exactly 20 characters (Firestore document ID format)
    // No partial matches allowed
    return id.length == 20 && RegExp(r'^[a-zA-Z0-9]{20}$').hasMatch(id);
  }

  bool _isValidCompleteTimestamp(String timestamp) {
    // STRICT: Must be exactly 13 digits (Unix timestamp in milliseconds)
    // OR exactly 10 digits (Unix timestamp in seconds)
    return (timestamp.length == 13 && RegExp(r'^\d{13}$').hasMatch(timestamp)) ||
           (timestamp.length == 10 && RegExp(r'^\d{10}$').hasMatch(timestamp));
  }

  bool _isValidCompleteOrderNumber(String orderNumber) {
    // STRICT: Must match exact patterns only
    if (orderNumber.startsWith('ORD-')) {
      String numberPart = orderNumber.substring(4);
      // Must be exactly 13 digits after ORD-
      return numberPart.length == 13 && RegExp(r'^\d{13}$').hasMatch(numberPart);
    }
    
    if (orderNumber.startsWith('#')) {
      String numberPart = orderNumber.substring(1);
      // Must be exactly 13 digits after #
      return numberPart.length == 13 && RegExp(r'^\d{13}$').hasMatch(numberPart);
    }
    
    // Without prefix, must be exactly 13 digits
    return orderNumber.length == 13 && RegExp(r'^\d{13}$').hasMatch(orderNumber);
  }

  // ADD THIS NEW VALIDATION METHOD
  void _showInvalidFormatDialog(String invalidInput) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: EdgeInsets.all(16), // Add padding from screen edges
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8, // Max 80% of screen height
            maxWidth: MediaQuery.of(context).size.width * 0.9,   // Max 90% of screen width
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with error icon
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red[600],
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Invalid Order Number',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Error message
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '"$invalidInput" is not a valid order number.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getValidationErrorMessage(invalidInput),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Valid formats section
                      Text(
                        'Required Format:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Format examples - more compact
                      _buildFormatExampleCard('ORD-1748091978310', '13 digits after ORD-'),
                      _buildFormatExampleCard('1748091978310', '13 digits (no prefix)'),
                      _buildFormatExampleCard('k1GrzEceRFpa2GCa9hz7', '20 characters (document ID)'),
                      
                      SizedBox(height: 12),
                      
                      // Warning about partial numbers - more compact
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[600], size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Partial order numbers are not accepted.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Info tip - more compact
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue[600],
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Tip:',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Copy the complete order number from your order confirmation email.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action button - fixed at bottom
              Container(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Got it',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
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

  Widget _buildFormatExampleCard(String example, String description) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example,
                  style: TextStyle( // ✅ FIXED: Use TextStyle for monospace
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_outline,
            color: Colors.green[600],
            size: 18,
          ),
        ],
      ),
    );
  }

  // ADD THIS NEW METHOD TO SHOW AVAILABLE ORDERS
  void _showAvailableOrdersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Your Orders'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: _activeOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders found'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _activeOrders.length,
                  itemBuilder: (context, index) {
                    final order = _activeOrders[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          order.orderNumber ?? 'Order #${order.id.substring(0, 12)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${_getStatusText(order.status)}'),
                            Text('Date: ${DateFormat('MMM d, yyyy').format(order.createdAt)}'),
                            if (order.orderNumber != null)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Copy: ${order.orderNumber}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.copy, size: 16),
                              onPressed: () {
                                // Copy to clipboard
                                _copyToClipboard(order.orderNumber ?? order.id);
                              },
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showTrackingDetails(order);
                              },
                              child: Text('Track', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  // ADD COPY TO CLIPBOARD FUNCTIONALITY
  void _copyToClipboard(String text) {
    // You'll need to add this import: import 'package:flutter/services.dart';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order number copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showOrderDetails(OrderModel order) {
    // Navigate to existing OrderDetailScreen instead of showing modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          orderId: order.id,
          isSellerView: false, // Set to false for buyer view
        ),
      ),
    );
  }

  void _showTrackingDetails(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(order: order),
      ),
    );
  }

  void _showOrderNotFoundDialog(String searchTerm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Not Found'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order "$searchTerm" was not found.'),
              SizedBox(height: 16),
              
              if (_activeOrders.isNotEmpty) ...[
                Text('Available orders:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _activeOrders.length,
                    itemBuilder: (context, index) {
                      final order = _activeOrders[index];
                      return Card(
                        child: ListTile(
                          title: Text('Order #${order.id.substring(0, 12)}...'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${order.status}'),
                              Text('Date: ${DateFormat('MMM d, yyyy').format(order.createdAt)}'),
                              Text('Full ID: ${order.id}'),
                            ],
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showTrackingDetails(order);
                            },
                            child: Text('Track'),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Text('You have no orders in the system.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Add this method to your package tracking screen for testing
  void _testOrderParsing() {
    print('🧪 Testing order parsing...');
    for (var order in _activeOrders) {
      print('Order: ${order.id}');
      print('  buyerId: ${order.buyerId}');
      print('  items count: ${order.items.length}');
      print('  total: ${order.total}');
      print('  status: ${order.status}');
    }
  }

  Future<void> _debugDatabaseQuery() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('🔍 Current user ID: ${user.uid}');
      
      // Try different query combinations
      print('\n=== Testing different queries ===');
      
      // Query 1: All orders (no filters)
      final allOrders = await FirebaseFirestore.instance
          .collection('orders')
          .get();
      print('📊 Total orders in database: ${allOrders.docs.length}');
      
      // Query 2: Orders with userId field
      final userIdOrders = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();
      print('👤 Orders with userId=${user.uid}: ${userIdOrders.docs.length}');
      
      // Query 3: Orders with buyerId field
      final buyerIdOrders = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .get();
      print('🛒 Orders with buyerId=${user.uid}: ${buyerIdOrders.docs.length}');
      
      // Print sample order data
      if (allOrders.docs.isNotEmpty) {
        print('\n=== Sample order structure ===');
        final sampleOrder = allOrders.docs.first;
        print('📄 Order ID: ${sampleOrder.id}');
        print('📋 Order data keys: ${sampleOrder.data().keys.toList()}');
        print('📝 Full order data: ${sampleOrder.data()}');
      }
      
      // Print user ID orders if any
      if (userIdOrders.docs.isNotEmpty) {
        print('\n=== Your orders (userId) ===');
        for (int i = 0; i < userIdOrders.docs.length; i++) {
          final doc = userIdOrders.docs[i];
          final data = doc.data();
          print('Order $i: ${doc.id}');
          print('  Status: ${data['status']}');
          print('  Created: ${data['createdAt']}');
          print('  User ID: ${data['userId']}');
        }
      }
      
      if (buyerIdOrders.docs.isNotEmpty) {
        print('\n=== Your orders (buyerId) ===');
        for (int i = 0; i < buyerIdOrders.docs.length; i++) {
          final doc = buyerIdOrders.docs[i];
          final data = doc.data();
          print('Order $i: ${doc.id}');
          print('  Status: ${data['status']}');
          print('  Created: ${data['createdAt']}');
          print('  Buyer ID: ${data['buyerId']}');
        }
      }
      
    } catch (e) {
      print('❌ Debug query error: $e');
    }
  }
}

// Live Tracking Screen for detailed tracking
class LiveTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const LiveTrackingScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 12)}', // Use order.id
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Estimated Delivery: ${_getEstimatedDelivery()}',
                    style: GoogleFonts.poppins(
                      color: Colors.green[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Tracking Timeline
            _buildTrackingTimeline(),
            
            SizedBox(height: 24),
            
            // Contact Support
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.support_agent, color: Colors.blue[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Help?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          'Contact our support team for assistance',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement contact support
                    },
                    child: Text('Contact'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline() {
    final events = _getTrackingEvents();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tracking History',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isLast = index == events.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: event['isCompleted'] 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 50,
                        color: Colors.grey[300],
                      ),
                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: event['isCompleted'] 
                                ? Colors.black87
                                : Colors.grey[600],
                          ),
                        ),
                        if (event['description'] != null)
                          Text(
                            event['description'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (event['timestamp'] != null)
                          Text(
                            event['timestamp'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getTrackingEvents() {
    // Mock tracking events - replace with real data
    return [
      {
        'title': 'Order Delivered',
        'description': 'Package has been delivered to your address',
        'timestamp': null,
        'isCompleted': order.status == 'delivered',
      },
      {
        'title': 'Out for Delivery',
        'description': 'Package is on its way to your address',
        'timestamp': order.status == 'out_for_delivery' 
            ? 'Today, 9:00 AM' 
            : null,
        'isCompleted': ['out_for_delivery', 'delivered'].contains(order.status),
      },
      {
        'title': 'Package Shipped',
        'description': 'Package has left the fulfillment center',
        'timestamp': ['shipped', 'out_for_delivery', 'delivered'].contains(order.status)
            ? DateFormat('MMM d, h:mm a').format(order.createdAt.add(Duration(days: 1)))
            : null,
        'isCompleted': ['shipped', 'out_for_delivery', 'delivered'].contains(order.status),
      },
      {
        'title': 'Order Processing',
        'description': 'Seller is preparing your order',
        'timestamp': ['processing', 'shipped', 'out_for_delivery', 'delivered'].contains(order.status)
            ? DateFormat('MMM d, h:mm a').format(order.createdAt.add(Duration(hours: 2)))
            : null,
        'isCompleted': ['processing', 'shipped', 'out_for_delivery', 'delivered'].contains(order.status),
      },
      {
        'title': 'Order Confirmed',
        'description': 'Your order has been confirmed',
        'timestamp': DateFormat('MMM d, h:mm a').format(order.createdAt),
        'isCompleted': true,
      },
    ];
  }

  String _getEstimatedDelivery() {
    final estimatedDate = order.createdAt.add(Duration(days: 3));
    return DateFormat('EEEE, MMMM d').format(estimatedDate);
  }
}

String _getValidationErrorMessage(String input) {
  String cleanInput = input.replaceAll('ORD-', '').replaceAll('#', '').trim();
  
  if (input.isEmpty) {
    return 'Order number cannot be empty';
  }
  
  if (cleanInput.length < 10) {
    return 'Too short - needs at least 10 digits';
  }
  
  if (cleanInput.length > 20) {
    return 'Too long - maximum 20 characters';
  }
  
  if (input.startsWith('ORD-')) {
    String numberPart = input.substring(4);
    if (numberPart.length != 13) {
      return 'ORD- format needs exactly 13 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(numberPart)) {
      return 'ORD- format must contain only numbers';
    }
  }
  
  if (RegExp(r'^[a-zA-Z0-9]+$').hasMatch(cleanInput)) {
    if (cleanInput.length != 20) {
      return 'Document IDs must be exactly 20 characters';
    }
  }
  
  if (RegExp(r'^\d+$').hasMatch(cleanInput)) {
    if (cleanInput.length != 10 && cleanInput.length != 13) {
      return 'Timestamp must be 10 or 13 digits';
    }
  }
  
  return 'Invalid format - check examples below';
}