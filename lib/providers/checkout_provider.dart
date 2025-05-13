import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/cart_model.dart';
import '/models/shipping_address.dart';
import '/models/payment_method.dart';
import '/models/order.dart' as my_order;

class CheckoutProvider with ChangeNotifier {
  // Current checkout step
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Shipping address
  ShippingAddress? _shippingAddress;
  ShippingAddress? get shippingAddress => _shippingAddress;

  // Payment method
  PaymentMethod? _paymentMethod;
  PaymentMethod? get paymentMethod => _paymentMethod;

  // Order ID after successful checkout
  String? _orderId;
  String? get orderId => _orderId;

  // Loading and error states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setShippingAddress(ShippingAddress address) {
    _shippingAddress = address;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void goToNextStep() {
    if (_currentStep < 2) {
      _currentStep++;
      notifyListeners();
    }
  }

  void goToPreviousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  Future<bool> placeOrder({
    required List<CartModel> items,
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
  }) async {
    if (_shippingAddress == null) {
      _errorMessage = "Shipping address is required";
      notifyListeners();
      return false;
    }

    if (_paymentMethod == null) {
      _errorMessage = "Payment method is required";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Create the order in Firestore
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      
      final order = my_order.Order(
        id: orderRef.id,
        userId: user.uid,
        items: items,
        shippingAddress: _shippingAddress!,
        paymentMethod: _paymentMethod!,
        subtotal: subtotal,
        shipping: shipping,
        tax: tax,
        total: total,
      );
      
      // Save the order
      await orderRef.set(order.toMap());

      // Store the order ID for confirmation
      _orderId = orderRef.id;
      
      // Process seller notifications
      await _notifySellers(items, orderRef.id);
      
      // Clear the cart
      await _clearCart(user.uid);
      
      _isLoading = false;
      notifyListeners();
      return true;
      
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  // Helper method to notify sellers about the order
  Future<void> _notifySellers(List<CartModel> items, String orderId) async {
    // Group items by seller
    final Map<String, List<CartModel>> itemsBySeller = {};
    for (var item in items) {
      if (item.sellerId != null) {
        if (!itemsBySeller.containsKey(item.sellerId)) {
          itemsBySeller[item.sellerId!] = [];
        }
        itemsBySeller[item.sellerId!]!.add(item);
      }
    }
    
    // Create seller-specific orders
    final batch = FirebaseFirestore.instance.batch();
    
    itemsBySeller.forEach((sellerId, sellerItems) {
      final sellerOrderRef = FirebaseFirestore.instance
          .collection('seller_orders')
          .doc();
          
      batch.set(sellerOrderRef, {
        'orderId': orderId,
        'sellerId': sellerId,
        'items': sellerItems.map((item) => item.toMap()).toList(),
        'status': 'new',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Also create notification for seller
      final notificationRef = FirebaseFirestore.instance
          .collection('seller_notifications')
          .doc();
          
      batch.set(notificationRef, {
        'sellerId': sellerId,
        'type': 'new_order',
        'title': 'New Order',
        'message': 'You have received a new order!',
        'orderId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    
    await batch.commit();
  }
  
  // Helper method to clear cart after successful order
  Future<void> _clearCart(String userId) async {
    final cartRef = FirebaseFirestore.instance.collection('carts');
    final cartSnapshot = await cartRef.where('userId', isEqualTo: userId).get();
    
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
  
  void resetCheckout() {
    _currentStep = 0;
    _shippingAddress = null;
    _paymentMethod = null;
    _orderId = null;
    _errorMessage = null;
    notifyListeners();
  }
}