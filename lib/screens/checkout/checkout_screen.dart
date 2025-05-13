import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/models/cart_model.dart';
import '/providers/checkout_provider.dart';
import '/providers/cart_providers.dart';
import 'shipping_address_form.dart'; 
import 'payment_method_form.dart';    
import 'order_summary.dart';         
import 'order_confirmation.dart';     

class CheckoutScreen extends StatelessWidget {
  final List<CartModel> cartItems;
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckoutProvider>(
      builder: (context, checkoutProvider, _) {
        return WillPopScope(
          onWillPop: () async {
            if (checkoutProvider.currentStep > 0) {
              checkoutProvider.goToPreviousStep();
              return false;
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _getStepTitle(checkoutProvider.currentStep),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              elevation: 0,
              leading: checkoutProvider.currentStep > 0
                  ? BackButton(
                      onPressed: () => checkoutProvider.goToPreviousStep(),
                    )
                  : null,
            ),
            body: _buildCurrentStep(context, checkoutProvider),
          ),
        );
      },
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0: return 'Shipping Address';
      case 1: return 'Payment Method';
      case 2: return 'Order Review';
      case 3: return 'Order Confirmation';
      default: return 'Checkout';
    }
  }

  Widget _buildCurrentStep(BuildContext context, CheckoutProvider provider) {
    print('Current checkout step: ${provider.currentStep}');
    switch (provider.currentStep) {
      case 0:
        return ShippingAddressForm(
          onContinue: (address) {
            provider.setShippingAddress(address);
            provider.goToNextStep();
          },
        );
      
      case 1:
        return PaymentMethodForm(
          onContinue: (method) {
            provider.setPaymentMethod(method);
            provider.goToNextStep();
          },
          onBack: () => provider.goToPreviousStep(),
        );
      
      case 2:
        return OrderSummary(
          cartItems: cartItems,
          shippingAddress: provider.shippingAddress!,
          paymentMethod: provider.paymentMethod!,
          subtotal: subtotal,
          shipping: shipping,
          tax: tax,
          total: total,
          onPlaceOrder: () async {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            
            final success = await provider.placeOrder(
              cartItems: cartItems,
              subtotal: subtotal,
              shipping: shipping,
              tax: tax,
              total: total,
            );
            
            // Close loading dialog
            Navigator.pop(context);
            
            if (success) {
              print('Order placed successfully, advancing step');
              provider.goToNextStep();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage ?? 'Failed to place order'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          onBack: () => provider.goToPreviousStep(),
        );
      
      case 3:
        return OrderConfirmation(
          orderId: provider.orderId!,
          total: total,
          onContinueShopping: () {
            // Reset and return to home screen
            provider.resetCheckout();
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
        );
      
      default:
        return Center(child: Text('Invalid step'));
    }
  }
}