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

  // Flag to prevent duplicate order submission
  bool _isProcessingOrder = false;

  void setShippingAddress(ShippingAddress address) {
    _shippingAddress = address;
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void goToNextStep() {
    if (_currentStep < 3) { // Allow up to step 3
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
    required List<CartModel> cartItems,
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
  }) async {
    print('placeOrder called at ${DateTime.now()}');
    if (_isProcessingOrder) {
      print('Order submission already in progress, ignoring duplicate request');
      return false;
    }

    // Existing validation code...
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
    _isProcessingOrder = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Create a batch for atomic operations
      final batch = FirebaseFirestore.instance.batch();

      // Create order document
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final String orderId = orderRef.id;
      final String orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final sellerIds = cartItems.map((item) => item.sellerId).toSet().toList();
      final orderData = {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'userId': user.uid,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'shippingAddress': _shippingAddress!.toMap(),
        'paymentMethod': _paymentMethod!.toMap(),
        'subtotal': subtotal,
        'shipping': shipping,
        'tax': tax,
        'total': total,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'sellerIds': {for (var id in sellerIds) id: true},
      };

      // Add order to batch
      batch.set(orderRef, orderData);
      
      // Count quantities for each product (since you don't have a quantity field)
      Map<String, int> productQuantities = {};
      for (var item in cartItems) {
        if (productQuantities.containsKey(item.productId)) {
          productQuantities[item.productId] = productQuantities[item.productId]! + 1;
        } else {
          productQuantities[item.productId] = 1;
        }
      }
      
      // Update stock for each product
      for (var entry in productQuantities.entries) {
        final productId = entry.key;
        final quantity = entry.value;
        
        final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
        
        // Get current product data
        final productDoc = await productRef.get();
        if (productDoc.exists) {
          final productData = productDoc.data()!;
          
          // Calculate new stock
          int currentStock = productData['stock'] ?? 0;
          int newStock = currentStock - quantity;
          
          // Prevent negative stock
          if (newStock < 0) newStock = 0;
          
          // Prepare update data
          Map<String, dynamic> updateData = {'stock': newStock};
          
          // If stock is zero, mark product as inactive
          if (newStock == 0) {
            updateData['isActive'] = false;
          }
          
          // Add product update to batch
          batch.update(productRef, updateData);
        }
      }
      
      // Commit all operations atomically
      await batch.commit();
      
      // Clear the cart
      await _clearCart(user.uid);

      _orderId = orderId;
      _isLoading = false;
      _isProcessingOrder = false;
      notifyListeners();
      return true;

    } catch (e) {
      print('Error placing order: $e');
      _isLoading = false;
      _isProcessingOrder = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Helper method to clear cart after successful order
  Future<void> _clearCart(String userId) async {
    try {
      final cartRef = FirebaseFirestore.instance.collection('carts');
      final cartSnapshot = await cartRef.where('userId', isEqualTo: userId).get();

      if (cartSnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in cartSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error clearing cart: $e');
    }
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