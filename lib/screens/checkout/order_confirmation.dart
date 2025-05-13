import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class OrderConfirmation extends StatefulWidget {
  final String orderId;
  final double total;
  final VoidCallback onContinueShopping;

  const OrderConfirmation({
    Key? key,
    required this.orderId,
    required this.total,
    required this.onContinueShopping,
  }) : super(key: key);

  @override
  State<OrderConfirmation> createState() => _OrderConfirmationState();
}

class _OrderConfirmationState extends State<OrderConfirmation> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success animation
            SizedBox(
              height: 200,
              child: Lottie.asset(
                'assets/animations/success.json', // Make sure this asset exists
                controller: _animationController,
                repeat: false,
                onLoaded: (composition) {
                  _animationController
                    ..duration = composition.duration
                    ..forward();
                },
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if animation asset is not available
                  return Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 120,
                        color: Colors.green,
                      ),
                      Text(
                        'Order Confirmed!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Thank You For Your Order!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            Text(
              'Your order has been placed and is being processed.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Order details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Order ID', widget.orderId),
                  const SizedBox(height: 8),
                  _buildDetailRow('Total', '\$${widget.total.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Estimated Delivery', 
                    '${_getEstimatedDeliveryDate()}'
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Continue shopping button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onContinueShopping,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continue Shopping',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // View order button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to order details screen (you can implement this later)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order details will be available soon')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View Order',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  String _getEstimatedDeliveryDate() {
    final now = DateTime.now();
    final estimatedDelivery = now.add(const Duration(days: 5));
    final month = _getMonthName(estimatedDelivery.month);
    return '$month ${estimatedDelivery.day}, ${estimatedDelivery.year}';
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}