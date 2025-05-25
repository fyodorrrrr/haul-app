import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/cart_model.dart';
import '/models/shipping_address.dart';
import '/models/payment_method.dart';
import '/models/order.dart' as my_order;

class CheckoutProvider extends ChangeNotifier {
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

  // ✅ Single, corrected placeOrder method
  Future<bool> placeOrder({
    required List<CartModel> cartItems,
    required double subtotal,
    required double shipping,
    required double tax,
    required double total,
    ShippingAddress? shippingAddress,
    PaymentMethod? paymentMethod,
  }) async {
    print('placeOrder called at ${DateTime.now()}');
    
    if (_isProcessingOrder) {
      print('Order submission already in progress, ignoring duplicate request');
      return false;
    }

    // Use provided parameters or fall back to stored values
    final finalShippingAddress = shippingAddress ?? _shippingAddress;
    final finalPaymentMethod = paymentMethod ?? _paymentMethod;

    // Validation
    if (finalShippingAddress == null) {
      _errorMessage = "Shipping address is required";
      notifyListeners();
      return false;
    }

    if (finalPaymentMethod == null) {
      _errorMessage = "Payment method is required";
      notifyListeners();
      return false;
    }

    if (cartItems.isEmpty) {
      _errorMessage = "Cart is empty";
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

      // ✅ Clean sellerIds map to remove empty keys
      Map<String, dynamic> sellerIds = {};
      for (var item in cartItems) {
        final sellerId = item.sellerId?.trim();
        if (sellerId != null && sellerId.isNotEmpty) {
          sellerIds[sellerId] = true;
        }
      }

      // ✅ Validate we have at least one valid seller
      if (sellerIds.isEmpty) {
        throw Exception('No valid sellers found in cart items');
      }

      // Create order document
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final String orderId = orderRef.id;
      final String orderNumber = _generateOrderNumber();

      // ✅ Create order data with structure that matches order detail screen
      final orderData = {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'userId': user.uid,
        'userEmail': user.email,
        'status': 'pending',
        'items': cartItems.map((item) => {
          'productId': item.productId?.trim() ?? '',
          'productName': item.productName?.trim() ?? 'Unknown Product',
          'quantity': item.quantity ?? 1,
          'price': item.productPrice ?? 0.0,
          // ✅ ADD BOTH imageUrl AND imageURL for compatibility
          'imageUrl': item.imageURL?.trim() ?? '',
          'imageURL': item.imageURL?.trim() ?? '',  // ✅ Order detail screen expects this
          'sellerId': item.sellerId?.trim() ?? '',
          'sellerName': item.sellerName?.trim() ?? 'Unknown Seller',
          'brand': item.brand?.trim() ?? '',
          'category': item.category?.trim() ?? '',
          'size': item.size?.trim() ?? '',
          'condition': item.condition?.trim() ?? '',
        }).toList(),
        'sellerIds': sellerIds,
        'shippingAddress': {
          'fullName': finalShippingAddress.fullName?.trim() ?? '',
          'addressLine1': finalShippingAddress.addressLine1?.trim() ?? '',
          'addressLine2': finalShippingAddress.addressLine2?.trim() ?? '',
          'city': finalShippingAddress.city?.trim() ?? '',
          'state': finalShippingAddress.state?.trim() ?? '',
          'zipCode': finalShippingAddress.zipCode?.trim() ?? '',
          'country': finalShippingAddress.country?.trim() ?? '',
          'phoneNumber': finalShippingAddress.phoneNumber?.trim() ?? '',
        },
        'paymentMethod': {
          'type': finalPaymentMethod.type?.trim() ?? '',
          'cardLastFour': finalPaymentMethod.cardLastFour?.trim() ?? '',
          'last4': finalPaymentMethod.cardLastFour?.trim() ?? '', // ✅ Add both formats
          'cardType': finalPaymentMethod.cardType?.trim() ?? '',
          'brand': finalPaymentMethod.cardType?.trim() ?? '', // ✅ Add both formats
          'status': 'completed', // ✅ Add payment status
          'paidAt': FieldValue.serverTimestamp(), // ✅ Add payment timestamp
        },
        
        // ✅ ADD: Top-level financial data (what order detail screen expects)
        'subtotal': subtotal,
        'shipping': shipping,
        'tax': tax,
        'total': total,
        
        // ✅ KEEP: Nested pricing for backward compatibility
        'pricing': {
          'subtotal': subtotal,
          'shipping': shipping,
          'tax': tax,
          'total': total,
        },
        
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'documentId': orderId, // ✅ Add document ID for easier access
      };

      // ✅ Validate the order data before sending
      _validateOrderData(orderData);

      // Create a batch for atomic operations
      final batch = FirebaseFirestore.instance.batch();

      // Add order to batch
      batch.set(orderRef, orderData);
      
      // ✅ Update product stock
      Map<String, int> productQuantities = {};
      for (var item in cartItems) {
        final productId = item.productId?.trim();
        if (productId != null && productId.isNotEmpty) {
          if (productQuantities.containsKey(productId)) {
            productQuantities[productId] = productQuantities[productId]! + (item.quantity ?? 1);
          } else {
            productQuantities[productId] = item.quantity ?? 1;
          }
        }
      }
      
      // Update stock for each product
      for (var entry in productQuantities.entries) {
        final productId = entry.key;
        final quantity = entry.value;
        
        final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
        
        try {
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
        } catch (e) {
          print('Warning: Could not update stock for product $productId: $e');
          // Continue with order even if stock update fails
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
      
      print('✅ Order placed successfully with ID: $orderId');
      return true;

    } catch (e) {
      print('❌ Error placing order: $e');
      _isLoading = false;
      _isProcessingOrder = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ Validation method
  void _validateOrderData(Map<String, dynamic> orderData) {
    // Check sellerIds
    final sellerIds = orderData['sellerIds'] as Map<String, dynamic>?;
    if (sellerIds == null || sellerIds.isEmpty) {
      throw Exception('No valid sellers found');
    }

    // Check for empty keys in sellerIds
    for (String key in sellerIds.keys) {
      if (key.trim().isEmpty) {
        throw Exception('Empty seller ID found');
      }
    }

    // Check items
    final items = orderData['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) {
      throw Exception('No items in order');
    }

    // Validate each item has required fields
    for (var item in items) {
      final itemMap = item as Map<String, dynamic>;
      if ((itemMap['productId'] as String?)?.trim().isEmpty ?? true) {
        throw Exception('Item missing product ID');
      }
      if ((itemMap['sellerId'] as String?)?.trim().isEmpty ?? true) {
        throw Exception('Item missing seller ID');
      }
    }

    print('✅ Order data validation passed');
  }

  // ✅ Helper method to clear cart after successful order
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
      
      print('✅ Cart cleared after order placement');
    } catch (e) {
      print('⚠️ Warning: Failed to clear cart: $e');
      // Don't throw error here as order was successful
    }
  }

  // ✅ Order number generation
  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$random';
  }

  // Reset checkout state
  void resetCheckout() {
    _currentStep = 0;
    _shippingAddress = null;
    _paymentMethod = null;
    _orderId = null;
    _errorMessage = null;
    _isProcessingOrder = false;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set current step manually
  void setCurrentStep(int step) {
    if (step >= 0 && step <= 3) {
      _currentStep = step;
      notifyListeners();
    }
  }
}