import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/seller_orders_provider.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({Key? key}) : super(key: key);

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<SellerOrdersProvider>(context, listen: false).fetchSellerOrders());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.poppins()),
      ),
      body: Consumer<SellerOrdersProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.orders.isEmpty) {
            return Center(
              child: Text(
                'No orders yet.',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }
          final orders = provider.orders;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
              final orderItems = List<Map<String, dynamic>>.from(order['items']);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order['orderNumber'] ?? order['orderId']}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: provider.getStatusColor(order['status']).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order['status'].toString().toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: provider.getStatusColor(order['status']),
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
                          Text(
                            'Total: \$${order['total'].toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontSize: 13),
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
                          final hasImage = item['imageURL'] != null && item['imageURL'].toString().isNotEmpty;
                          return Container(
                            width: 70,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: hasImage
                                ? Image.network(
                                    item['imageURL'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                                  )
                                : Center(
                                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                                  ),
                          );
                        },
                      ),
                    ),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showOrderDetails(context, order, provider),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('View Details'),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _showStatusUpdateDialog(context, order, provider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Update Status'),
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
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, Map<String, dynamic> order, SellerOrdersProvider provider) {
    String selectedStatus = order['status'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status', style: GoogleFonts.poppins()),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Order #${order['orderNumber']}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                ...List.generate(provider.statusOptions.length, (index) {
                  final status = provider.statusOptions[index];
                  return RadioListTile<String>(
                    title: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: provider.getStatusColor(status),
                        fontWeight: selectedStatus == status
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    value: status,
                    groupValue: selectedStatus,
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value!;
                      });
                    },
                  );
                }),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close the dialog first
              await Future.delayed(const Duration(milliseconds: 100)); // Ensure dialog is closed

              if (selectedStatus != order['status']) {
                final success = await provider.updateOrderStatus(order['documentId'], selectedStatus);

                // Use a post-frame callback to show snackbar after dialog is closed
                if (mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Order status updated to $selectedStatus'
                              : 'Failed to update order status'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  });
                }
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order, SellerOrdersProvider provider) {
    final orderItems = List<Map<String, dynamic>>.from(order['items']);
    final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
    final shippingAddress = order['shippingAddress'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: provider.getStatusColor(order['status']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order['status'].toString().toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: provider.getStatusColor(order['status']),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Order #${order['orderNumber'] ?? order['orderId']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    'Placed on ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                Divider(height: 24),
                // Order items with images
                Text(
                  'Items',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => Divider(height: 16),
                  itemCount: orderItems.length,
                  itemBuilder: (context, index) {
                    final item = orderItems[index];
                    final hasImage = item['imageURL'] != null && item['imageURL'].toString().isNotEmpty;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product image
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: hasImage
                              ? Image.network(
                                  item['imageURL'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                                  ),
                                )
                              : Center(
                                  child: Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
                                ),
                        ),
                        SizedBox(width: 12),
                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['productName'] ?? 'Product',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Quantity: ${item['quantity'] ?? 1}',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              Text(
                                '\$${(item['productPrice'] ?? 0.0).toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Shipping address section
                if (shippingAddress != null) ...[
                  Divider(height: 24),
                  Text(
                    'Shipping Address',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${shippingAddress['name'] ?? ''}\n'
                    '${shippingAddress['street'] ?? ''}\n'
                    '${shippingAddress['city'] ?? ''}, ${shippingAddress['state'] ?? ''} ${shippingAddress['postalCode'] ?? ''}\n'
                    '${shippingAddress['country'] ?? ''}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ],
                Divider(height: 24),
                // Order summary
                Text(
                  'Order Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    Text(
                      '\$${order['total'].toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                // Update status button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showStatusUpdateDialog(context, order, provider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Update Status'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}