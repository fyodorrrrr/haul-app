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
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('Fetching orders for seller: ${user.uid}');

      // SIMPLIFIED: Get all orders and filter client-side to avoid query permission issues
      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .get();

      print('Retrieved ${querySnapshot.docs.length} total orders');

      // Filter orders that contain this seller's products
      final sellerOrders = querySnapshot.docs.where((doc) {
        final data = doc.data();
        
        // FIXED: Handle both List and Map formats for sellerIds
        final sellerIds = data['sellerIds'];
        bool hasSellerProduct = false;
        
        if (sellerIds is Map<String, dynamic>) {
          // Map format: {"sellerId1": true, "sellerId2": true}
          hasSellerProduct = sellerIds.containsKey(user.uid);
        } else if (sellerIds is List<dynamic>) {
          // List format: ["sellerId1", "sellerId2"]
          hasSellerProduct = sellerIds.contains(user.uid);
        } else {
          // Fallback: Check items for seller products
          final items = data['items'] as List<dynamic>?;
          if (items != null) {
            hasSellerProduct = items.any((item) {
              if (item is Map<String, dynamic>) {
                return item['sellerId'] == user.uid;
              }
              return false;
            });
          }
        }
        
        if (hasSellerProduct) {
          print('Order ${doc.id} contains seller products');
        }
        
        return hasSellerProduct;
      }).map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id;
        return data;
      }).toList();

      // Sort by creation date (client-side)
      sellerOrders.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime); // Descending order
      });

      print('Found ${sellerOrders.length} orders for seller');
      _orders = sellerOrders;

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