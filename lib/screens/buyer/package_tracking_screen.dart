import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import 'dart:math' as math;

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
                    hintText: 'Enter order number (e.g., ORD-123456)',
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
                  ),
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
          'Active Orders',
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
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(order.status).withOpacity(0.3),
          width: 1,
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
          // Order Header - CHANGED TO USE ORDER NUMBER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber ?? 'Order #${order.id}', // SHOW ORDER NUMBER
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          
          SizedBox(height: 12),
          
          // Order Details
          Row(
            children: [
              Icon(
                Icons.store,
                size: 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: 6),
              Text(
                order.sellerIds.isNotEmpty 
                  ? 'Seller ${order.sellerIds.first.substring(0, 8)}' 
                  : 'Unknown Seller',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              SizedBox(width: 6),
              Text(
                DateFormat('MMM d, yyyy').format(order.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Tracking Progress
          _buildTrackingProgress(order.status),
          
          SizedBox(height: 16),
          
          // Action Buttons
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
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTrackingDetails(order),
                  icon: Icon(Icons.local_shipping, size: 16),
                  label: Text(
                    'Track Live',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
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
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
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
      default:
        return 'Unknown';
    }
  }

  void _trackByOrderNumber() {
    final orderNumber = _trackingController.text.trim();
    if (orderNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter an order number')),
      );
      return;
    }

    setState(() => _isSearching = true);

    print('🔍 Searching for: $orderNumber');
    print('Available orders: ${_activeOrders.length}');
    
    // Remove prefixes and clean the search term
    String searchTerm = orderNumber
        .replaceAll('ORD-', '')
        .replaceAll('#', '')
        .trim();
    
    print('🔍 Cleaned search term: $searchTerm');
    
    // Search through all orders
    OrderModel? foundOrder;
    
    for (int i = 0; i < _activeOrders.length; i++) {
      final order = _activeOrders[i];
      print('Checking order $i: ${order.id}');
      
      // Get the timestamp for this order
      final orderTimestamp = order.createdAt.millisecondsSinceEpoch.toString();
      final orderTimestampSeconds = (order.createdAt.millisecondsSinceEpoch ~/ 1000).toString();
      
      print('  Order ID: ${order.id}');
      print('  Order Number: ${order.orderNumber}');
      print('  Order timestamp (ms): $orderTimestamp');
      print('  Order timestamp (seconds): $orderTimestampSeconds');
      print('  Order created at: ${order.createdAt}');
      
      // Try different matching strategies including ORDER NUMBER
      if (
        // Order ID matches
        order.id == searchTerm ||                                    
        order.id.startsWith(searchTerm) ||                          
        order.id.contains(searchTerm) ||                            
        order.id.substring(0, math.min(8, order.id.length)) == searchTerm || 
        
        // ORDER NUMBER matches (NEW!)
        (order.orderNumber != null && order.orderNumber == orderNumber) ||           // Exact order number match with prefix
        (order.orderNumber != null && order.orderNumber?.replaceAll('ORD-', '') == searchTerm) || // Order number without prefix
        (order.orderNumber != null && order.orderNumber!.contains(searchTerm)) ||    // Order number contains search term
        
        // Timestamp matches
        orderTimestamp.contains(searchTerm) ||                      
        orderTimestampSeconds.contains(searchTerm) ||               
        orderTimestampSeconds.startsWith(searchTerm.substring(0, math.min(10, searchTerm.length)))
      ) {
        foundOrder = order;
        print('✅ Found matching order: ${order.id}');
        print('✅ Order Number: ${order.orderNumber}');
        print('✅ Match type: Order number or ID match');
        break;
      }
    }
    
    setState(() => _isSearching = false);
    
    if (foundOrder != null) {
      print('🎯 Navigating to order: ${foundOrder.id}');
      _showTrackingDetails(foundOrder);
    } else {
      print('❌ No order found for: $orderNumber');
      print('💡 Available order numbers for reference:');
      for (var order in _activeOrders) {
        final timestamp = (order.createdAt.millisecondsSinceEpoch ~/ 1000).toString();
        print('   Order ID: ${order.id}');
        print('   Order Number: ${order.orderNumber}');
        print('   Timestamp: $timestamp');
        print('   ---');
      }
      _showOrderNotFoundDialog(orderNumber);
    }
  }

  void _showOrderDetails(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            
            _buildDetailRow('Order ID', order.id),
            _buildDetailRow('Status', _getStatusText(order.status)),
            _buildDetailRow('Seller', order.sellerIds.isNotEmpty ? order.sellerIds.first : 'Unknown'),
            _buildDetailRow('Total Amount', '₱${order.total.toStringAsFixed(2)}'), // FIXED: Use order.total
            _buildDetailRow('Order Date', DateFormat('MMMM d, yyyy at h:mm a').format(order.createdAt)),
            
            if (order.trackingNumber != null)
              _buildDetailRow('Tracking Number', order.trackingNumber!),
            
            if (order.shippingAddress != null)
              _buildDetailRow('Delivery Address', order.shippingAddress!),
            
            Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
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