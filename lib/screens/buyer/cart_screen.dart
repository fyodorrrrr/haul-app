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

            // Calculate totals
            final subtotal = cart.fold(0.0, (sum, item) => sum + item.productPrice);
            final shipping = cart.isNotEmpty ? 5.99 : 0.0;
            final tax = subtotal * 0.1; // 10% tax
            final total = subtotal + shipping + tax;

            if (cart.isEmpty) {
              return Center(
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
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                    child: Text(
                      'Your Cart',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

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
                        _buildSummaryRow('Subtotal', CurrencyFormatter.format(subtotal)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Shipping', '\$${shipping.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          'Total',
                          CurrencyFormatter.format(total),
                          isTotal: true,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final cartProvider = Provider.of<CartProvider>(context, listen: false);
                              await cartProvider.updateCartItemsWithSellerId();

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChangeNotifierProvider(
                                    create: (_) => CheckoutProvider(),
                                    child: CheckoutScreen(
                                      cartItems: cart,
                                      subtotal: subtotal,
                                      shipping: shipping,
                                      tax: tax,
                                      total: total,
                                    ),
                                  ),
                                ),
                              );
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
                              'Proceed to Checkout',
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
              image: cartItem.imageURL.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(cartItem.imageURL),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: cartItem.imageURL.isEmpty
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cartItem.productName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${cartItem.productPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Remove Button
          Container(
            width: 40,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 12.0, right: 12.0),
            child: IconButton(
              onPressed: () => cartProvider.removeFromCart(cartItem.productId),
              icon: Icon(
                Icons.close,
                size: 18,
                color: Colors.grey.shade500,
              ),
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