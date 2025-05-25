import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import 'order_detail_screen.dart';

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

          if (provider.error != null) {
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
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.fetchSellerOrders(),
                    child: Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.orders.isEmpty) {
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
                    'When customers place orders with you, they\'ll appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order['documentId'] ?? order['orderId'] ?? '',
          orderData: order,
          isSellerView: true,
        ),
      ),
    );
  }
}