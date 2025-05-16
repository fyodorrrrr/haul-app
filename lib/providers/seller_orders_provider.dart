import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerOrdersProvider extends ChangeNotifier {
  final List<String> statusOptions = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchSellerOrders() async {
    _isLoading = true;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _orders = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();

    final sellerOrders = <Map<String, dynamic>>[];

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      final sellerItems = items.where((item) => item['sellerId'] == user.uid).toList();

      if (sellerItems.isNotEmpty) {
        sellerOrders.add({
          'orderId': data['orderId'],
          'orderNumber': data['orderNumber'],
          'buyerId': data['userId'],
          'documentId': doc.id,
          'items': sellerItems,
          'total': data['total'],
          'status': data['status'],
          'createdAt': data['createdAt'],
          'shippingAddress': data['shippingAddress'],
        });
      }
    }
    _orders = sellerOrders;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(String documentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(documentId)
          .update({'status': newStatus});
      await fetchSellerOrders();
      return true;
    } catch (e) {
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
      case 'confirmed': return Colors.blue;
      case 'shipped': return Colors.purple;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}