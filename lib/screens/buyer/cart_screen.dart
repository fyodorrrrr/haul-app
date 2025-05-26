import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                          _buildSummaryRow('Subtotal', CurrencyFormatter.format(subtotal)),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Shipping', CurrencyFormatter.format(shipping)),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Tax', CurrencyFormatter.format(tax)),
                          const Divider(height: 24),
                          _buildSummaryRow(
                            'Total',
                            CurrencyFormatter.format(total),
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
                                'Proceed to Checkout (${CurrencyFormatter.format(total)})', // ✅ Changed from $ to ₱
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
      height: 130,
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
                  // Product name and brand
                  Flexible(
                    child: Column(
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
                        if (cartItem.brand?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            cartItem.brand!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price and quantity controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Flexible(
                        flex: 2,
                        child: Text(
                          CurrencyFormatter.format(cartItem.productPrice ?? 0.0), // ✅ Changed from $ to ₱
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Quantity controls
                      Flexible(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease button
                            InkWell(
                              onTap: () {
                                // ✅ Add null safety check
                                if (cartItem.id == null || cartItem.id!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Cannot update quantity: Invalid item ID'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (cartItem.quantity > 1) {
                                  cartProvider.updateQuantity(
                                    cartItem.id!,
                                    cartItem.quantity - 1,
                                  ).catchError((error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update quantity'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  });
                                }
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: cartItem.quantity > 1 ? Colors.grey.shade200 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.remove, 
                                  size: 16,
                                  color: cartItem.quantity > 1 ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                            
                            // Quantity display
                            Container(
                              width: 40,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '${cartItem.quantity}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            // Increase button
                            InkWell(
                              onTap: () {
                                // ✅ Add null safety check
                                if (cartItem.id == null || cartItem.id!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Cannot update quantity: Invalid item ID'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                
                                cartProvider.updateQuantity(
                                  cartItem.id!,
                                  cartItem.quantity + 1,
                                ).catchError((error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update quantity'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                });
                              },
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Remove Button
          Container(
            width: 36,
            height: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    // ✅ Check which removal method to use
                    if (cartItem.id != null && cartItem.id!.isNotEmpty) {
                      _showRemoveConfirmation(context, cartProvider, cartItem);
                    } else if (cartItem.productId != null && cartItem.productId!.isNotEmpty) {
                      _showRemoveConfirmationByProductId(context, cartProvider, cartItem);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cannot remove this item: No valid identifier found'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
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

  void _showRemoveConfirmation(BuildContext context, CartProvider cartProvider, CartModel cartItem) {
    // ✅ Check if cart item has valid ID before showing dialog
    if (cartItem.id == null || cartItem.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot remove this item: Invalid item ID'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Remove Item',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to remove this item from your cart?',
                style: GoogleFonts.poppins(),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                        image: (cartItem.imageURL?.isNotEmpty == true)
                            ? DecorationImage(
                                image: NetworkImage(cartItem.imageURL!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (cartItem.imageURL?.isEmpty ?? true)
                          ? Icon(Icons.image_not_supported, size: 16, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cartItem.productName ?? 'Unknown Product',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${cartItem.quantity} • ${CurrencyFormatter.format(cartItem.productPrice ?? 0.0)}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // ✅ Double-check ID before removal
                final itemId = cartItem.id;
                if (itemId == null || itemId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot remove item: Invalid ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Removing item...', style: GoogleFonts.poppins()),
                        ],
                      ),
                    ),
                  ),
                );
                
                try {
                  await cartProvider.removeFromCartById(itemId);
                  
                  // Hide loading
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${cartItem.productName ?? "Item"} removed from cart'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  // Hide loading
                  Navigator.of(context).pop();
                  
                  print('❌ Error removing cart item: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove item. Please try again.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Remove',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveConfirmationByProductId(BuildContext context, CartProvider cartProvider, CartModel cartItem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Item', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Remove "${cartItem.productName}" from cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await cartProvider.removeFromCartByProductId(cartItem.productId!, user.uid);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${cartItem.productName} removed from cart'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove item'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}