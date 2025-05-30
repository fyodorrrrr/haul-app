import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/screens/seller/order_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/widgets/not_logged_in.dart';
import '/providers/user_profile_provider.dart';
import '../../../utils/currency_formatter.dart'; // ✅ Add this import

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchBuyerOrders();
  }

  Future<void> _fetchBuyerOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['documentId'] = doc.id;
        return data;
      }).toList();

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        // Show not logged in screen if user isn't logged in
        if (!userProfileProvider.isProfileLoaded) {
          return const NotLoggedInScreen(
            message: 'Please log in to view your orders',
            icon: Icons.shopping_bag_outlined,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('My Orders', style: GoogleFonts.poppins()),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Failed to load orders',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchBuyerOrders,
              child: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No orders yet',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Your order history will appear here once you make a purchase.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBuyerOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
          final orderItems = List<Map<String, dynamic>>.from(order['items'] ?? []);
          final status = order['status'] ?? 'pending';

          return GestureDetector(
            onLongPress: () {
              _copyOrderId(order['orderNumber'] ?? order['orderId'] ?? order['documentId']);
              _showCopyTooltip(); // Optional: Show a tooltip explaining long press
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Order #${order['orderNumber'] ?? order['orderId']}',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Tooltip(
                                message: 'Copy Order ID',
                                child: GestureDetector(
                                  onTap: () => _copyOrderId(order['orderNumber'] ?? order['orderId'] ?? order['documentId']),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'Items: ${orderItems.length}',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        
                        // ✅ Enhanced price display with multiple fallbacks
                        Builder(
                          builder: (context) {
                            double totalPrice = 0.0;
                            
                            // Try to get total from different possible fields
                            final totalFields = ['total', 'totalAmount', 'totalPrice', 'grandTotal'];
                            for (String field in totalFields) {
                              if (order[field] != null) {
                                try {
                                  if (order[field] is String) {
                                    totalPrice = double.parse(order[field]);
                                  } else if (order[field] is num) {
                                    totalPrice = order[field].toDouble();
                                  }
                                  if (totalPrice > 0) break;
                                } catch (e) {
                                  print('❌ Error parsing total from field $field: ${order[field]}');
                                }
                              }
                            }
                            
                            // ✅ If no total found, calculate from items
                            if (totalPrice <= 0) {
                              for (var item in orderItems) {
                                // Get price with multiple fallbacks
                                double itemPrice = 0.0;
                                final priceFields = ['productPrice', 'price', 'unitPrice', 'itemPrice'];
                                for (String field in priceFields) {
                                  if (item[field] != null) {
                                    try {
                                      if (item[field] is String) {
                                        itemPrice = double.parse(item[field]);
                                      } else if (item[field] is num) {
                                        itemPrice = item[field].toDouble();
                                      }
                                      if (itemPrice > 0) break;
                                    } catch (e) {
                                      print('❌ Error parsing item price: $e');
                                    }
                                  }
                                }
                                
                                // Get quantity
                                int quantity = 1;
                                final quantityFields = ['quantity', 'qty', 'count'];
                                for (String field in quantityFields) {
                                  if (item[field] != null) {
                                    try {
                                      if (item[field] is String) {
                                        quantity = int.parse(item[field]);
                                      } else if (item[field] is num) {
                                        quantity = item[field].toInt();
                                      }
                                      if (quantity > 0) break;
                                    } catch (e) {
                                      print('❌ Error parsing quantity: $e');
                                    }
                                  }
                                }
                                
                                totalPrice += (itemPrice * quantity);
                              }
                              
                              // Add shipping and tax if available
                              final shipping = double.tryParse(order['shipping']?.toString() ?? '0') ?? 0.0;
                              final tax = double.tryParse(order['tax']?.toString() ?? '0') ?? 0.0;
                              totalPrice += shipping + tax;
                            }
                            
                            // ✅ Debug logging for price
                            print('💰 Order History Price Debug:');
                            print('  Order: ${order['orderNumber'] ?? order['orderId']}');
                            print('  Calculated total: \$${totalPrice.toStringAsFixed(2)}');
                            print('  Raw total from order: ${order['total']}');
                            
                            return Text(
                              CurrencyFormatter.format(totalPrice), // ✅ Changed from $ to ₱
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            );
                          },
                        ),
                        
                        if (createdAt != null)
                          Text(
                            'Placed: ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  // Product images row
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orderItems.length,
                      itemBuilder: (context, itemIndex) {
                        final item = orderItems[itemIndex];
                        
                        // ✅ Multiple fallbacks for image URL
                        String? imageUrl;
                        final imageFields = ['imageURL', 'imageUrl', 'image', 'productImage', 'thumbnail'];
                        for (String field in imageFields) {
                          if (item[field] != null && item[field].toString().trim().isNotEmpty) {
                            imageUrl = item[field].toString();
                            break;
                          }
                        }
                        
                        // ✅ Debug logging for images
                        if (itemIndex == 0) { // Only log for first item to avoid spam
                          print('🖼️ Order History Image Debug:');
                          print('  Item fields: ${item.keys.toList()}');
                          print('  Image URL found: ${imageUrl ?? "No image"}');
                        }
                        
                        return Container(
                          width: 70,
                          height: 70,
                          margin: EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('❌ Order history image error: $error');
                                    return _buildImagePlaceholder();
                                  },
                                )
                              : _buildImagePlaceholder(),
                        );
                      },
                    ),
                  ),
                  // Action button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showOrderDetails(context, order),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('View Details'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order['documentId'] ?? order['orderId'] ?? '',
          orderData: order,
          isSellerView: false,
        ),
      ),
    );
  }

  // Add this new method to show a confirmation dialog before cancelling
  void _showCancelConfirmation(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['documentId'];
    final orderNumber = order['orderNumber'] ?? orderId.substring(0, 8);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel this order?'),
            SizedBox(height: 12),
            Text(
              'Order #$orderNumber',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No, Keep Order'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close the confirmation dialog
              Navigator.pop(context);
              // Close the order details dialog
              Navigator.pop(context);
              // Cancel the order
              _cancelOrder(orderId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
  }

  // Add this method to handle the actual order cancellation
  Future<void> _cancelOrder(String orderId) async {
    try {
      setState(() => _isLoading = true);
      
      // Update order status to cancelled in Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'cancelled'});
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh orders list
      await _fetchBuyerOrders();
      // _fetchBuyerOrders already sets _isLoading = false when it completes
    } catch (e) {
      print('Error cancelling order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _copyOrderId(String orderId) {
    Clipboard.setData(ClipboardData(text: orderId)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ID $orderId copied to clipboard'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _showCopyTooltip() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💡 Tip: Long press any order card to copy its ID'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ✅ Add this helper method for image placeholders:

  Widget _buildImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 20,
            color: Colors.grey[400],
          ),
          SizedBox(height: 2),
          Text(
            'No Image',
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}