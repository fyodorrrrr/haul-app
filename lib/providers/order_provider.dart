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
        _error = 'Please log in to view your orders';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('Fetching orders for seller: ${user.uid}');
      
      // Get all recent orders - will filter for seller on client side
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      print('Found ${snapshot.docs.length} total orders, filtering for seller items');

      List<Map<String, dynamic>> sellerOrders = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Check if this order contains items from this seller
        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        final sellerItems = items.where((item) => 
            item['sellerId'] == user.uid).toList();
        
        // Only include orders with items from this seller
        if (sellerItems.isNotEmpty) {
          // Add formatted date
          if (data['createdAt'] is Timestamp) {
            data['createdAtFormatted'] = _formatDate(data['createdAt'] as Timestamp);
          }
          
          sellerOrders.add({
            ...data,
            'documentId': doc.id,
            'items': sellerItems, // Only include this seller's items
          });
        }
      }
      
      _orders = sellerOrders;
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