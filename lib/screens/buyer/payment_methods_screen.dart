import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodsScreen extends StatefulWidget {
  @override
  _PaymentMethodsScreenState createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payment_methods')
            .get();
        
        setState(() {
          _paymentMethods = doc.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading payment methods: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Methods',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add New Payment Method Button
                  Container(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showAddPaymentMethodDialog,
                      icon: Icon(Icons.add),
                      label: Text('Add Payment Method'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Payment Methods List
                  Text(
                    'Saved Payment Methods',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Expanded(
                    child: _paymentMethods.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _paymentMethods.length,
                            itemBuilder: (context, index) {
                              final method = _paymentMethods[index];
                              return _buildPaymentMethodCard(method);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Payment Methods',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add a payment method to make checkout faster',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    IconData icon;
    Color cardColor;
    
    switch (method['type']) {
      case 'gcash':
        icon = Icons.phone_android;
        cardColor = Colors.blue;
        break;
      case 'maya':
        icon = Icons.credit_card;
        cardColor = Colors.green;
        break;
      case 'bank':
        icon = Icons.account_balance;
        cardColor = Colors.purple;
        break;
      case 'cod':
        icon = Icons.local_shipping;
        cardColor = Colors.orange;
        break;
      default:
        icon = Icons.payment;
        cardColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cardColor),
        ),
        title: Text(
          method['name'] ?? 'Unknown',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          method['details'] ?? '',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (method['isDefault'] == true)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'default',
                  child: Text('Set as Default'),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'default':
                    _setAsDefault(method['id']);
                    break;
                  case 'edit':
                    _editPaymentMethod(method);
                    break;
                  case 'delete':
                    _deletePaymentMethod(method['id']);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentMethodDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _AddPaymentMethodSheet(
        onPaymentMethodAdded: () {
          _loadPaymentMethods();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _setAsDefault(String methodId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final batch = FirebaseFirestore.instance.batch();
        
        // Remove default from all methods
        for (var method in _paymentMethods) {
          final ref = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('payment_methods')
              .doc(method['id']);
          batch.update(ref, {'isDefault': false});
        }
        
        // Set new default
        final newDefaultRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payment_methods')
            .doc(methodId);
        batch.update(newDefaultRef, {'isDefault': true});
        
        await batch.commit();
        _loadPaymentMethods();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting default: $e')),
      );
    }
  }

  Future<void> _deletePaymentMethod(String methodId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('payment_methods')
              .doc(methodId)
              .delete();
          _loadPaymentMethods();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting payment method: $e')),
        );
      }
    }
  }

  void _editPaymentMethod(Map<String, dynamic> method) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }
}

class _AddPaymentMethodSheet extends StatefulWidget {
  final VoidCallback onPaymentMethodAdded;

  _AddPaymentMethodSheet({required this.onPaymentMethodAdded});

  @override
  _AddPaymentMethodSheetState createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> {
  String _selectedType = 'gcash';
  final _nameController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _paymentTypes = [
    {'id': 'gcash', 'name': 'GCash', 'icon': Icons.phone_android, 'color': Colors.blue},
    {'id': 'maya', 'name': 'Maya (PayMaya)', 'icon': Icons.credit_card, 'color': Colors.green},
    {'id': 'bank', 'name': 'Bank Transfer', 'icon': Icons.account_balance, 'color': Colors.purple},
    {'id': 'cod', 'name': 'Cash on Delivery', 'icon': Icons.local_shipping, 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Payment Method',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 24),
            
            // Payment Type Selection
            Text(
              'Payment Type',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            
            ...(_paymentTypes.map((type) => RadioListTile<String>(
              title: Row(
                children: [
                  Icon(type['icon'], color: type['color']),
                  SizedBox(width: 12),
                  Text(type['name']),
                ],
              ),
              value: type['id'],
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            )).toList()),
            
            SizedBox(height: 16),
            
            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name/Alias',
                hintText: 'e.g., My GCash, Primary Bank',
                border: OutlineInputBorder(),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Details Field
            TextField(
              controller: _detailsController,
              decoration: InputDecoration(
                labelText: _getDetailsLabel(),
                hintText: _getDetailsHint(),
                border: OutlineInputBorder(),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Add Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addPaymentMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Add Payment Method',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDetailsLabel() {
    switch (_selectedType) {
      case 'gcash':
      case 'maya':
        return 'Phone Number';
      case 'bank':
        return 'Account Number';
      case 'cod':
        return 'Delivery Instructions';
      default:
        return 'Details';
    }
  }

  String _getDetailsHint() {
    switch (_selectedType) {
      case 'gcash':
      case 'maya':
        return '+63 9XX XXX XXXX';
      case 'bank':
        return 'Your bank account number';
      case 'cod':
        return 'Special delivery instructions';
      default:
        return 'Enter details';
    }
  }

  Future<void> _addPaymentMethod() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name for this payment method')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final isFirstMethod = await _isFirstPaymentMethod(user.uid);
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payment_methods')
            .add({
          'type': _selectedType,
          'name': _nameController.text.trim(),
          'details': _detailsController.text.trim(),
          'isDefault': isFirstMethod, // First method becomes default
          'createdAt': FieldValue.serverTimestamp(),
        });

        widget.onPaymentMethodAdded();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding payment method: $e')),
      );
    }
  }

  Future<bool> _isFirstPaymentMethod(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .get();
    return snapshot.docs.isEmpty;
  }
}