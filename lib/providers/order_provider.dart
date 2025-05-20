import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerOrdersProvider with ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;

  // Add this getter for error
  String? get error => _error;

  // Existing getters
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;

  // Add this getter for order status options
  List<String> get statusOptions => [
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled'
  ];

  Future<void> fetchSellerOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Order loading failed: User not logged in');
        _error = 'Please log in to view your orders';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('Fetching orders for seller: ${user.uid}');

      // Try with a simpler query first to debug
      // This query doesn't require a composite index
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .limit(50)  // Limit to first 50 orders for performance
          .get();

      print('Found ${snapshot.docs.length} orders');

      if (snapshot.docs.isEmpty) {
        // Check if there are any orders for this seller at all
        print('No orders found. Checking if sellerId field exists...');
        
        // Check a sample order to see if your field names are correct
        final sampleOrder = await FirebaseFirestore.instance
            .collection('orders')
            .limit(1)
            .get();
            
        if (sampleOrder.docs.isNotEmpty) {
          print('Sample order fields: ${sampleOrder.docs.first.data().keys}');
        }
      }

      _orders = snapshot.docs.map((doc) {
        final data = doc.data();
        // Check if createdAt exists and convert from Timestamp if needed
        if (data['createdAt'] is Timestamp) {
          data['createdAtFormatted'] = _formatDate(data['createdAt'] as Timestamp);
        }
        
        return {
          ...data,
          'documentId': doc.id,
        };
      }).toList();

      // Sort the orders locally since we removed the orderBy
      _orders.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching orders: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper function to format timestamps
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      // Update local data too
      final index = _orders.indexWhere((order) => order['documentId'] == orderId);
      if (index >= 0) {
        _orders[index] = {
          ..._orders[index],
          'status': newStatus,
        };
        notifyListeners();
      }

      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  Future<void> updateOrderStatusWithFeedback(String documentId, String newStatus, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(documentId)
          .update({'status': newStatus});
      await fetchSellerOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.indigo;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}