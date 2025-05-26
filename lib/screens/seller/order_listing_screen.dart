import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import 'order_detail_screen.dart';
import '../../utils/currency_formatter.dart'; // ✅ Add this import

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
                              'Order #${_getOrderNumber(order)}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: provider.getStatusColor(order['status'] ?? 'pending').withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (order['status'] ?? 'pending').toString().toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: provider.getStatusColor(order['status'] ?? 'pending'),
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
                          // ✅ Enhanced total calculation and display
                          Text(
                            'Total: \$${_calculateOrderTotal(order, orderItems)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.green.shade700,
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              'Placed: ${DateFormat('MMM dd, yyyy').format(createdAt)}',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    
                    // ✅ Enhanced product images with debug info
                    if (orderItems.isNotEmpty)
                      Container(
                        height: 80,
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: orderItems.length > 5 ? 5 : orderItems.length,
                          itemBuilder: (context, itemIndex) {
                            final item = orderItems[itemIndex];
                            // ✅ Debug each item
                            _debugItemData(item, itemIndex);
                            return _buildEnhancedProductImage(
                              item, 
                              itemIndex == 4 && orderItems.length > 5 ? orderItems.length - 5 : 0
                            );
                          },
                        ),
                      ),
                    
                    // Action buttons remain the same...
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // ✅ Debug before navigation
                                _debugOrderData(order);
                                _showOrderDetails(context, order, provider);
                              },
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

  // ✅ Dialog methods
  void _showStatusUpdateDialog(BuildContext context, Map<String, dynamic> order, SellerOrdersProvider provider) {
    final safeOrder = _getSafeOrderData(order);
    String selectedStatus = safeOrder['status'];

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
                  'Order #${safeOrder['orderNumber']}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Total: \$${_formatOrderTotal(safeOrder['total'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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
              Navigator.pop(context);
              await Future.delayed(const Duration(milliseconds: 100));

              if (selectedStatus != safeOrder['status']) {
                try {
                  final success = await provider.updateOrderStatus(
                    safeOrder['documentId'], 
                    selectedStatus,
                  );

                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Order status updated to ${selectedStatus.toUpperCase()}'
                                : 'Failed to update order status'),
                            backgroundColor: success ? Colors.green : Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error updating order status: $e'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    });
                  }
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
    final safeOrder = _getSafeOrderData(order);
    
    if (safeOrder['documentId'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load order details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
        orderId: order['orderId'] ?? order['documentId'],
        isSellerView: true,
        ),
      ),
    );
  }

  // ✅ Data extraction methods
  String _getOrderNumber(Map<String, dynamic> order) {
    return order['orderNumber'] ?? 
           order['orderId'] ?? 
           order['id'] ?? 
           order['documentId'] ?? 
           'N/A';
  }

  // Enhanced order total calculation
  String _calculateOrderTotal(Map<String, dynamic> order, List<Map<String, dynamic>> orderItems) {
    // Try to get total from order
    if (order['total'] != null) {
      if (order['total'] is num) {
        return CurrencyFormatter.format(order['total'].toDouble());
      }
      if (order['total'] is String) {
        final parsed = double.tryParse(order['total']);
        return CurrencyFormatter.format(parsed ?? 0.0);
      }
    }
    
    // Calculate from items if no total in order
    double calculatedTotal = 0.0;
    for (var item in orderItems) {
      final price = _getItemPrice(item);
      final quantity = _getItemQuantity(item);
      calculatedTotal += price * quantity;
    }
    
    return CurrencyFormatter.format(calculatedTotal);
  }

  double _getItemPrice(Map<String, dynamic> item) {
    // Try different possible price field names
    final priceFields = ['price', 'productPrice', 'unitPrice', 'itemPrice'];
    
    for (String field in priceFields) {
      if (item[field] != null) {
        if (item[field] is num) {
          return item[field].toDouble();
        }
        if (item[field] is String) {
          final parsed = double.tryParse(item[field]);
          if (parsed != null) return parsed;
        }
      }
    }
    
    return 0.0;
  }

  int _getItemQuantity(Map<String, dynamic> item) {
    if (item['quantity'] != null) {
      if (item['quantity'] is num) {
        return item['quantity'].toInt();
      }
      if (item['quantity'] is String) {
        final parsed = int.tryParse(item['quantity']);
        if (parsed != null) return parsed;
      }
    }
    return 1; // Default quantity
  }

  String? _getItemImageUrl(Map<String, dynamic> item) {
    // Try different possible image field names
    final imageFields = ['imageURL', 'image', 'productImage', 'imageUrl', 'productImageUrl'];
    
    for (String field in imageFields) {
      if (item[field] != null && item[field].toString().trim().isNotEmpty) {
        return item[field].toString();
      }
    }
    
    return null;
  }

  String? _getItemName(Map<String, dynamic> item) {
    // Try different possible name field names
    final nameFields = ['productName', 'name', 'title', 'itemName'];
    
    for (String field in nameFields) {
      if (item[field] != null && item[field].toString().trim().isNotEmpty) {
        return item[field].toString();
      }
    }
    
    return 'Unknown Product';
  }

  // ✅ Helper methods
  String _formatOrderTotal(dynamic total) {
    if (total == null) return '0.00';
    
    if (total is num) {
      return total.toStringAsFixed(2);
    }
    
    if (total is String) {
      final parsed = double.tryParse(total);
      return parsed?.toStringAsFixed(2) ?? '0.00';
    }
    
    return '0.00';
  }

  Map<String, dynamic> _getSafeOrderData(Map<String, dynamic> order) {
    return {
      'orderId': order['orderId'] ?? order['documentId'] ?? '',
      'orderNumber': order['orderNumber'] ?? order['orderId'] ?? 'N/A',
      'status': order['status'] ?? 'pending',
      'total': order['total'] ?? 0.0,
      'items': order['items'] ?? [],
      'createdAt': order['createdAt'],
      'documentId': order['documentId'] ?? order['orderId'] ?? '',
    };
  }

  // ✅ Widget building methods
  Widget _buildEnhancedProductImage(Map<String, dynamic> item, int extraCount) {
    final imageUrl = _getItemImageUrl(item);
    final productName = _getItemName(item);
    final price = _getItemPrice(item);
    final quantity = _getItemQuantity(item);
    
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    
    return Container(
      width: 70,
      margin: EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Main image or placeholder
          if (hasImage)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
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
                print('❌ Image load error for $imageUrl: $error');
                return _buildImagePlaceholder(productName, price, quantity);
              },
            )
          else
            _buildImagePlaceholder(productName, price, quantity),
          
          // Quantity badge
          if (quantity > 1)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'x$quantity',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        
          // Extra items indicator
          if (extraCount > 0)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '+$extraCount',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Enhanced image placeholder with price info
  Widget _buildImagePlaceholder(String? productName, double price, int quantity) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: Colors.grey.shade400,
            size: 20,
          ),
          if (productName != null && productName.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Text(
                productName.length > 6 ? '${productName.substring(0, 6)}...' : productName,
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // ✅ Show price in placeholder
          if (price > 0)
            Padding(
              padding: EdgeInsets.only(top: 1),
              child: Text(
                '\$${price.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 7,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ✅ Debug methods
  void _debugOrderData(Map<String, dynamic> order) {
    print('🔍 DEBUG ORDER DATA:');
    print('Order keys: ${order.keys.toList()}');
    print('Order total: ${order['total']} (type: ${order['total'].runtimeType})');
    
    if (order['items'] != null) {
      final items = List<Map<String, dynamic>>.from(order['items']);
      print('Items count: ${items.length}');
      
      for (int i = 0; i < items.length && i < 2; i++) {
        print('Item $i keys: ${items[i].keys.toList()}');
        print('Item $i imageURL: ${items[i]['imageURL']}');
        print('Item $i productName: ${items[i]['productName']}');
        print('Item $i price: ${items[i]['price']} (type: ${items[i]['price'].runtimeType})');
      }
    }
  }

  // ✅ Add this missing method
  void _debugItemData(Map<String, dynamic> item, int index) {
    print('🔍 DEBUG ITEM $index:');
    print('Item keys: ${item.keys.toList()}');
    print('Image URL: ${_getItemImageUrl(item)}');
    print('Product Name: ${_getItemName(item)}');
    print('Price: ${_getItemPrice(item)}');
    print('Quantity: ${_getItemQuantity(item)}');
    print('---');
  }
}