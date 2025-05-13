import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/models/cart_model.dart';
import '/models/shipping_address.dart';
import '/models/payment_method.dart';
import '/providers/checkout_provider.dart';

class OrderSummary extends StatefulWidget {
  final List<CartModel> cartItems;
  final ShippingAddress shippingAddress;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double shipping;
  final double tax;
  final double total;
  final VoidCallback onPlaceOrder;
  final VoidCallback onBack;

  const OrderSummary({
    Key? key,
    required this.cartItems,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.onPlaceOrder,
    required this.onBack,
  }) : super(key: key);

  @override
  State<OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<OrderSummary> {
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
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
                  // Shipping Address Section
                  _buildSectionHeader('Shipping Address'),
                  _buildAddressCard(),
                  const SizedBox(height: 20),

                  // Payment Method Section
                  _buildSectionHeader('Payment Method'),
                  _buildPaymentMethodCard(),
                  const SizedBox(height: 20),

                  // Order Items Section
                  _buildSectionHeader('Items (${widget.cartItems.length})'),
                  ...widget.cartItems.map((item) => _buildOrderItem(item)).toList(),
                  const SizedBox(height: 20),

                  // Order Total Section
                  _buildSectionHeader('Order Total'),
                  _buildPriceRow('Subtotal', '\$${widget.subtotal.toStringAsFixed(2)}'),
                  _buildPriceRow('Shipping', '\$${widget.shipping.toStringAsFixed(2)}'),
                  _buildPriceRow('Tax', '\$${widget.tax.toStringAsFixed(2)}'),
                  const Divider(thickness: 1),
                  _buildPriceRow('Total', '\$${widget.total.toStringAsFixed(2)}', isTotal: true),
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
                  onPressed: _isPlacingOrder
                      ? null
                      : () async {
                          setState(() => _isPlacingOrder = true);
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          try {
                            final checkoutProvider = Provider.of<CheckoutProvider>(
                              context,
                              listen: false,
                            );
                            final success = await checkoutProvider.placeOrder(
                              cartItems: widget.cartItems,
                              subtotal: widget.subtotal,
                              shipping: widget.shipping,
                              tax: widget.tax,
                              total: widget.total,
                            );
                            Navigator.pop(context);
                            if (success) {
                              widget.onPlaceOrder();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    checkoutProvider.errorMessage ??
                                        'Failed to place order',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('An error occurred: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _isPlacingOrder = false);
                          }
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
                    _isPlacingOrder ? 'Processing...' : 'Place Order',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.shippingAddress.fullName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(widget.shippingAddress.addressLine1),
            if (widget.shippingAddress.addressLine2.isNotEmpty)
              Text(widget.shippingAddress.addressLine2),
            Text('${widget.shippingAddress.city}, ${widget.shippingAddress.state} ${widget.shippingAddress.zipCode}'),
            Text(widget.shippingAddress.country),
            const SizedBox(height: 4),
            Text(widget.shippingAddress.phoneNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    // Define icon based on payment method
    IconData getIcon() {
      switch (widget.paymentMethod.type) {
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(getIcon(), color: Colors.black),
        title: Text(
          widget.paymentMethod.type,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: widget.paymentMethod.details != null && widget.paymentMethod.type == 'Credit/Debit Card'
            ? Text('${widget.paymentMethod.details!['cardType']} ending in ${widget.paymentMethod.details!['last4']}')
            : null,
      ),
    );
  }

  Widget _buildOrderItem(CartModel item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageURL,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${item.productPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}