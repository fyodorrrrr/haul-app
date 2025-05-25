import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/providers/cart_providers.dart';
import '/providers/user_profile_provider.dart';
import '/models/cart_model.dart';
import '/widgets/not_logged_in.dart';
import '/providers/checkout_provider.dart';
import '/screens/checkout/checkout_screen.dart';
import '../../utils/currency_formatter.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        // Show NotLoggedInScreen if user is not logged in
        if (!userProfileProvider.isProfileLoaded) {
          return const NotLoggedInScreen(
            message: 'Please log in to view your shopping cart',
            icon: Icons.shopping_cart_outlined,
          );
        }

        // Show cart content if user is logged in
        return Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            final cart = cartProvider.cart;

            // Fixed calculations with null safety
            final subtotal = cart.fold(0.0, (sum, item) {
              final price = item.productPrice ?? 0.0;
              final quantity = item.quantity;
              return sum + (price * quantity);
            });
            
            final shipping = cart.isNotEmpty ? 5.99 : 0.0;
            final tax = subtotal * 0.1; // 10% tax
            final total = subtotal + shipping + tax;

            if (cart.isEmpty) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Shopping Cart',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Shopping Cart (${cart.length})',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Cart Items
                    Expanded(
                      child: ListView.builder(
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final cartItem = cart[index];
                          return _buildCartItem(context, cartItem, cartProvider);
                        },
                      ),
                    ),

                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Shipping', '\$${shipping.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
                          const Divider(height: 24),
                          _buildSummaryRow(
                            'Total',
                            '\$${total.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                          const SizedBox(height: 16),
                          
                          // Fixed checkout button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                
                                try {
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                  
                                  // ✅ Update cart items with seller info first
                                  await cartProvider.updateCartItemsWithSellerInfo();
                                  
                                  // Hide loading indicator
                                  Navigator.of(context).pop();
                                  
                                  // Validate cart after update
                                  if (!cartProvider.validateCartForCheckout()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Some items in your cart are missing seller information. Please try again or remove the problematic items.'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 4),
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  // Check for empty cart
                                  if (cartProvider.cart.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Your cart is empty'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  // Proceed to checkout
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CheckoutScreen(
                                        cartItems: cartProvider.cart,
                                        subtotal: cartProvider.subtotal,
                                        shipping: cartProvider.shippingFee,
                                        tax: cartProvider.tax,
                                        total: cartProvider.total,
                                      ),
                                    ),
                                  );
                                  
                                } catch (e) {
                                  // Hide loading indicator if still showing
                                  if (Navigator.canPop(context)) {
                                    Navigator.of(context).pop();
                                  }
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error preparing checkout: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Proceed to Checkout (\$${total.toStringAsFixed(2)})',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(BuildContext context, CartModel cartItem, CartProvider cartProvider) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              image: (cartItem.imageURL?.isNotEmpty == true)
                  ? DecorationImage(
                      image: NetworkImage(cartItem.imageURL!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (cartItem.imageURL?.isEmpty ?? true)
                ? Icon(
                    Icons.image_not_supported,
                    color: Colors.grey.shade400,
                    size: 24,
                  )
                : null,
          ),

          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartItem.productName ?? 'Unknown Product',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (cartItem.brand?.isNotEmpty == true)
                        Text(
                          cartItem.brand!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${(cartItem.productPrice ?? 0.0).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                      
                      // Quantity controls
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (cartItem.quantity > 1) {
                                cartProvider.updateQuantity(
                                  cartItem.id!,
                                  cartItem.quantity - 1,
                                );
                              }
                            },
                            icon: Icon(Icons.remove_circle_outline, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(minWidth: 30, minHeight: 30),
                          ),
                          
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${cartItem.quantity}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                            ),
                          ),
                          
                          IconButton(
                            onPressed: () {
                              cartProvider.updateQuantity(
                                cartItem.id!,
                                cartItem.quantity + 1,
                              );
                            },
                            icon: Icon(Icons.add_circle_outline, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(minWidth: 30, minHeight: 30),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Remove Button
          Container(
            width: 40,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
            child: IconButton(
              onPressed: () => cartProvider.removeFromCartById(cartItem.id!),
              icon: Icon(
                Icons.close,
                size: 18,
                color: Colors.grey.shade500,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}