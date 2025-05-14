import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({Key? key}) : super(key: key);

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchSellerOrders();
  }

  Future<List<Map<String, dynamic>>> _fetchSellerOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Fetch all orders where any item belongs to this seller
    final ordersSnapshot = await FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();

    final sellerOrders = <Map<String, dynamic>>[];

    for (final doc in ordersSnapshot.docs) {
      final data = doc.data();
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      final sellerItems = items.where((item) => item['sellerId'] == user.uid).toList();

      if (sellerItems.isNotEmpty) {
        sellerOrders.add({
          'orderId': data['orderId'],
          'orderNumber': data['orderNumber'],
          'buyerId': data['userId'],
          'items': sellerItems,
          'total': data['total'],
          'status': data['status'],
          'createdAt': data['createdAt'],
        });
      }
    }
    return sellerOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.poppins()),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No orders yet.',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }
          final orders = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final createdAt = (order['createdAt'] as Timestamp?)?.toDate();
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(
                    'Order #${order['orderNumber'] ?? order['orderId']}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items: ${order['items'].length}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      Text(
                        'Total: \$${order['total'].toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      if (createdAt != null)
                        Text(
                          'Placed: ${createdAt.toLocal().toString().split(' ')[0]}',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                        ),
                      Text(
                        'Status: ${order['status']}',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Show order details dialog/page
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text('Order Details', style: GoogleFonts.poppins()),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...order['items'].map<Widget>((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                '${item['productName']} - \$${item['productPrice']}',
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            )),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}