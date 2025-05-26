import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/models/cart_model.dart';
import '/models/shipping_address.dart';
import '/models/payment_method.dart';
import '/providers/checkout_provider.dart';
import '/screens/checkout/order_confirmation.dart';
import '../../utils/currency_formatter.dart'; // ✅ Add this import

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
                  _buildPriceRow('Subtotal', CurrencyFormatter.format(widget.subtotal)), // ✅ Changed from $ to ₱
                  _buildPriceRow('Shipping', CurrencyFormatter.format(widget.shipping)), // ✅ Changed from $ to ₱
                  _buildPriceRow('Tax', CurrencyFormatter.format(widget.tax)), // ✅ Changed from $ to ₱
                  const Divider(thickness: 1),
                  _buildPriceRow('Total', CurrencyFormatter.format(widget.total), isTotal: true), // ✅ Changed from $ to ₱
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
                            
                            // ✅ Fix: Include missing parameters
                            final success = await checkoutProvider.placeOrder(
                              cartItems: widget.cartItems,
                              shippingAddress: widget.shippingAddress, // ✅ Add this
                              paymentMethod: widget.paymentMethod,     // ✅ Add this
                              subtotal: widget.subtotal,
                              shipping: widget.shipping,
                              tax: widget.tax,
                              total: widget.total,
                            );
                            
                            Navigator.pop(context);
                            if (success) {
                              final orderId = checkoutProvider.orderId;
                              if (orderId != null && orderId.isNotEmpty) { // ✅ Add null check
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => OrderConfirmation(
                                      orderId: orderId,
                                      total: widget.total,
                                      onContinueShopping: () {
                                        Navigator.of(context).pushNamedAndRemoveUntil(
                                          '/', // Your home route
                                          (route) => false,
                                        );
                                      },
                                    ),
                                  ),
                                  (route) => false,
                                );
                              } else {
                                throw Exception('Order ID is null or empty');
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    checkoutProvider.errorMessage ?? 'Failed to place order',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context);
                            print('❌ Order placement error: $e');
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
              widget.shippingAddress.fullName ?? 'No Name', // ✅ Handle null
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(widget.shippingAddress.addressLine1 ?? ''), // ✅ Handle null
            if ((widget.shippingAddress.addressLine2?.isNotEmpty ?? false)) // ✅ Handle null
              Text(widget.shippingAddress.addressLine2!),
            Text('${widget.shippingAddress.city ?? ''}, ${widget.shippingAddress.state ?? ''} ${widget.shippingAddress.zipCode ?? ''}'), // ✅ Handle null
            Text(widget.shippingAddress.country ?? ''), // ✅ Handle null
            const SizedBox(height: 4),
            Text(widget.shippingAddress.phoneNumber ?? ''), // ✅ Handle null
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    // Define icon based on payment method
    IconData getIcon() {
      final type = widget.paymentMethod.type ?? '';
      switch (type) {
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
          widget.paymentMethod.type ?? 'Unknown Payment Method', // ✅ Handle null
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: _buildPaymentSubtitle(),
      ),
    );
  }

  // ✅ Add helper method for payment subtitle
  Widget? _buildPaymentSubtitle() {
    final type = widget.paymentMethod.type ?? '';
    
    if (type == 'Credit/Debit Card') {
      final cardType = widget.paymentMethod.cardType;
      final lastFour = widget.paymentMethod.cardLastFour;
      
      if (cardType != null && lastFour != null) {
        return Text('$cardType ending in $lastFour');
      }
    }
    
    return null; // No subtitle for other payment methods
  }

  // ✅ Enhanced order item with better information display:
  Widget _buildOrderItem(CartModel item) {
    final itemTotal = (item.productPrice ?? 0.0) * item.quantity;
    
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
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade300,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (item.imageURL?.isNotEmpty == true)
                    ? Image.network(
                        item.imageURL!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      )
                    : Container(
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
                  // Product Name
                  Text(
                    item.productName ?? 'Unknown Product',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Brand (if available)
                  if (item.brand?.isNotEmpty == true)
                    Text(
                      item.brand!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  
                  // Size and Condition (if available)
                  if (item.size?.isNotEmpty == true || item.condition?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          if (item.size?.isNotEmpty == true) 'Size: ${item.size}',
                          if (item.condition?.isNotEmpty == true) 'Condition: ${item.condition}',
                        ].join(' • '),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 8),
                  
                  // Price and Quantity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Qty: ${item.quantity}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (item.quantity > 1)
                            Text(
                              CurrencyFormatter.format(item.productPrice ?? 0.0) + ' each', // ✅ Changed from $ to ₱
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          Text(
                            CurrencyFormatter.format(itemTotal), // ✅ Changed from $ to ₱
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
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