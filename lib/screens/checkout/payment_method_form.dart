import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/models/payment_method.dart';

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
  String _selectedMethod = 'Cash on Delivery';
  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'Credit/Debit Card',
    'PayPal',
    'GCash',
  ];

  @override
  Widget build(BuildContext context) {
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
                children: _paymentMethods.map((method) {
                  return _buildPaymentOption(method);
                }).toList(),
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
                  onPressed: () {
                    final paymentMethod = PaymentMethod(
                      type: _selectedMethod,
                      details: _selectedMethod == 'Credit/Debit Card' ? 
                        {'cardType': 'Visa', 'last4': '1234'} : null,
                    );
                    widget.onContinue(paymentMethod);
                  },
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

  Widget _buildPaymentOption(String method) {
    final bool isSelected = _selectedMethod == method;
    
    // Define icon based on payment method
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
}