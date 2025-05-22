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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('Fetching orders for seller: ${user.uid}');

      // This query should now work with your index:
      // sellerIds (array-contains) + createdAt (orderBy)
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerIds', arrayContains: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${ordersQuery.docs.length} orders');

      _orders = ordersQuery.docs.map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id; // Add document ID for updates
        return data;
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching seller orders: $e');
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

      // Refresh the orders list from Firestore
      await fetchSellerOrders();

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