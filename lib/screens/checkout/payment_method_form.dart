import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/screens/buyer/payment_methods_screen.dart';
import '/models/payment_method.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodForm extends StatefulWidget {
  final Function(PaymentMethod) onContinue;
  final VoidCallback onBack;

  const PaymentMethodForm({
    Key? key,
    required this.onContinue,
    required this.onBack,
  }) : super(key: key);

  @override
  State<PaymentMethodForm> createState() => _PaymentMethodFormState();
}

class _PaymentMethodFormState extends State<PaymentMethodForm> {
  String? _selectedMethod;
  List<Map<String, dynamic>> _savedPaymentMethods = [];
  final List<String> _defaultPaymentMethods = [
    'Cash on Delivery',
    'Credit/Debit Card',
    'PayPal',
    'GCash',
    'Maya (PayMaya)',
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPaymentMethods();
  }

  Future<void> _loadSavedPaymentMethods() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payment_methods')
            .get();
        
        setState(() {
          _savedPaymentMethods = snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();
          
          // Set default payment method
          final defaultMethod = _savedPaymentMethods.firstWhere(
            (method) => method['isDefault'] == true,
            orElse: () => {},
          );
          
          if (defaultMethod.isNotEmpty) {
            _selectedMethod = '${defaultMethod['name']} (${defaultMethod['type']})';
          } else {
            _selectedMethod = 'Cash on Delivery';
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _selectedMethod = 'Cash on Delivery';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _selectedMethod = 'Cash on Delivery';
        _isLoading = false;
      });
      print('Error loading payment methods: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ Show saved payment methods first
                  if (_savedPaymentMethods.isNotEmpty) ...[
                    Text(
                      'Saved Payment Methods',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._savedPaymentMethods.map((method) {
                      return _buildSavedPaymentOption(method);
                    }).toList(),
                    SizedBox(height: 20),
                  ],
                  
                  // ✅ Show default options
                  Text(
                    'Other Payment Options',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  ..._defaultPaymentMethods.map((method) {
                    return _buildPaymentOption(method);
                  }).toList(),
                  
                  // ✅ Add this after the default payment methods
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.add, color: Colors.grey.shade600),
                      title: Text(
                        'Add New Payment Method',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PaymentMethodsScreen()),
                        ).then((_) {
                          // Reload payment methods when returning
                          _loadSavedPaymentMethods();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedMethod != null ? () {
                    // ✅ Create PaymentMethod with all required parameters
                    final paymentMethod = PaymentMethod(
                      id: _generatePaymentMethodId(),
                      type: _getPaymentType(),
                      cardLastFour: _getCardLastFour(),
                      cardType: _getCardType(),
                      cardholderName: _getCardholderName(),
                      expiryMonth: _getExpiryMonth(),
                      expiryYear: _getExpiryYear(),
                      isDefault: _isDefaultPaymentMethod(),
                    );
                    
                    print('Selected payment method:');
                    print('  ID: ${paymentMethod.id}');
                    print('  Type: ${paymentMethod.type}');
                    print('  Card Last Four: ${paymentMethod.cardLastFour}');
                    print('  Card Type: ${paymentMethod.cardType}');
                    
                    widget.onContinue(paymentMethod);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSavedPaymentOption(Map<String, dynamic> method) {
    final displayName = '${method['name']} (${method['type']})';
    final bool isSelected = _selectedMethod == displayName;
    
    IconData getIcon() {
      switch (method['type']) {
        case 'gcash':
          return Icons.monetization_on;
        case 'maya':
          return Icons.credit_card;
        case 'paypal':
          return Icons.account_balance_wallet;
        case 'bank':
          return Icons.account_balance;
        case 'cod':
          return Icons.money;
        default:
          return Icons.payment;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.black.withOpacity(0.05) : null,
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(getIcon(), color: isSelected ? Colors.black : Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'],
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    method['details'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (method['isDefault'] == true)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Default',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        value: displayName,
        groupValue: _selectedMethod,
        activeColor: Colors.black,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onChanged: (value) {
          setState(() {
            _selectedMethod = value!;
          });
        },
      ),
    );
  }

  Widget _buildPaymentOption(String method) {
    final bool isSelected = _selectedMethod == method;
    
    IconData getIcon() {
      switch (method) {
        case 'Cash on Delivery':
          return Icons.money;
        case 'Credit/Debit Card':
          return Icons.credit_card;
        case 'PayPal':
          return Icons.account_balance_wallet;
        case 'GCash':
          return Icons.monetization_on;
        case 'Maya (PayMaya)':
          return Icons.credit_card;
        default:
          return Icons.payment;
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            Icon(getIcon(), color: isSelected ? Colors.black : Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              method,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        value: method,
        groupValue: _selectedMethod,
        activeColor: Colors.black,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onChanged: (value) {
          setState(() {
            _selectedMethod = value!;
          });
        },
      ),
    );
  }

  Map<String, dynamic>? _getPaymentDetails() {
    if (_selectedMethod == null) return null;
    
    // Check if it's a saved payment method
    for (var method in _savedPaymentMethods) {
      final displayName = '${method['name']} (${method['type']})';
      if (_selectedMethod == displayName) {
        return {
          'savedMethodId': method['id'],
          'originalDetails': method['details'], // ✅ Include original details
          'isDefault': method['isDefault'] ?? false,
        };
      }
    }
    
    // Return details for default payment methods
    switch (_selectedMethod) {
      case 'Cash on Delivery':
        return {'payOnDelivery': true};
      case 'Credit/Debit Card':
        return {'requiresCardInput': true};
      case 'PayPal':
        return {'requiresPayPalLogin': true};
      case 'GCash':
        return {'requiresGCashNumber': true};
      case 'Maya (PayMaya)':
        return {'requiresMayaAccount': true};
      default:
        return {};
    }
  }
  
  // ✅ Add this method to extract clean payment type
  String _getPaymentType() {
    if (_selectedMethod == null) return 'Cash on Delivery';
    
    // Check if it's a saved payment method
    for (var method in _savedPaymentMethods) {
      final displayName = '${method['name']} (${method['type']})';
      if (_selectedMethod == displayName) {
        return method['type']; // Return the stored type
      }
    }
    
    // Map default payment methods to clean types
    switch (_selectedMethod) {
      case 'Cash on Delivery':
        return 'Cash on Delivery';
      case 'Credit/Debit Card':
        return 'Credit/Debit Card';
      case 'PayPal':
        return 'PayPal';
      case 'GCash':
        return 'GCash';
      case 'Maya (PayMaya)':
        return 'Maya';
      default:
        return _selectedMethod ?? 'Cash on Delivery';
    }
  }
  
  // ✅ Add these helper methods to _PaymentMethodFormState:

  String _generatePaymentMethodId() {
    // Generate a unique ID for the payment method
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString();
    return 'pm_$random';
  }

  String? _getCardLastFour() {
    if (_selectedMethod == null) return null;
    
    // Check if it's a saved payment method with card info
    for (var method in _savedPaymentMethods) {
      final displayName = '${method['name']} (${method['type']})';
      if (_selectedMethod == displayName) {
        return method['lastFour']; // Return saved card last four
      }
    }
    
    // For new card selections, return null (would be filled in card form)
    if (_selectedMethod == 'Credit/Debit Card') {
      return null; // This would be filled when user enters card details
    }
    
    return null;
  }

  String? _getCardType() {
    if (_selectedMethod == null) return null;
    
    // Check if it's a saved payment method with card info
    for (var method in _savedPaymentMethods) {
      final displayName = '${method['name']} (${method['type']})';
      if (_selectedMethod == displayName) {
        return method['cardType']; // Return saved card type
      }
    }
    
    // For new card selections, return null
    if (_selectedMethod == 'Credit/Debit Card') {
      return null; // This would be determined when user enters card details
    }
    
    return null;
  }

  String? _getCardholderName() {
    if (_selectedMethod == null) return null;
    
    // Check if it's a saved payment method
    for (var method in _savedPaymentMethods) {
      final displayName = '${method['name']} (${method['type']})';
      if (_selectedMethod == displayName) {
        return method['cardholderName'];
      }
    }
    
    return null;
  }

  String? _getExpiryMonth() {
    if (_selectedMethod == null) return null;
    
    // Check if it's a saved payment method
    for (var method in _savedPaymentMethods) {
      final displayName = '${method['name']} (${method['type']})';
      if (_selectedMethod == displayName) {
        return method['expiryMonth'];
      }
    }
    
    return null;
  }

  String? _getExpiryYear() {
    if (_selectedMethod == null) return null;
    
    // Check if it's a saved payment method
    for (var method in _savedPaymentMethods) {
      final displayName = '${method['name']} (${method['type']})';
      if (_selectedMethod == displayName) {
        return method['expiryYear'];
      }
    }
    
    return null;
  }

  bool _isDefaultPaymentMethod() {
    if (_selectedMethod == null) return false;
    
    // Check if it's a saved payment method marked as default
    for (var method in _savedPaymentMethods) {
      final displayName = '${method['name']} (${method['type']})';
      if (_selectedMethod == displayName) {
        return method['isDefault'] ?? false;
      }
    }
    
    return false;
  }
}