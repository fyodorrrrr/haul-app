import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? orderData; // Optional for when we already have the data
  final bool isSellerView; // true for seller view, false for buyer view

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
    this.orderData,
    this.isSellerView = false,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _error;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderData != null) {
      _orderData = widget.orderData;
      _isLoading = false;
    } else {
      _loadOrderData();
    }
  }

  Future<void> _loadOrderData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (doc.exists) {
        setState(() {
          _orderData = doc.data();
          _orderData!['documentId'] = doc.id;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Order not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (_orderData != null) ...[
            IconButton(
              icon: Icon(Icons.copy),
              onPressed: () => _copyOrderId(),
              tooltip: 'Copy Order ID',
            ),
            if (widget.isSellerView)
              IconButton(
                icon: Icon(Icons.phone),
                onPressed: () => _contactBuyer(),
                tooltip: 'Contact Buyer',
              ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading order details...',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error Loading Order',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrderData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orderData == null) {
      return Center(
        child: Text(
          'No order data available',
          style: GoogleFonts.poppins(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrderData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            SizedBox(height: 20),
            _buildOrderStatus(),
            SizedBox(height: 20),
            _buildOrderItems(),
            SizedBox(height: 20),
            _buildShippingInfo(),
            SizedBox(height: 20),
            _buildPaymentInfo(),
            SizedBox(height: 20),
            _buildPricingBreakdown(),
            SizedBox(height: 20),
            if (widget.isSellerView) _buildSellerActions(),
            if (!widget.isSellerView) _buildBuyerActions(),
            SizedBox(height: 20),
            _buildOrderTimeline(),
          ],
        ),
      ),
    );
  }

  // ✅ Enhanced _buildOrderHeader method with proper price handling:

  Widget _buildOrderHeader() {
    final orderNumber = _orderData!['orderNumber'] ?? _orderData!['orderId'] ?? widget.orderId;
    final createdAt = (_orderData!['createdAt'] as Timestamp?)?.toDate();

    // ✅ Enhanced total price calculation with multiple fallbacks
    double totalPrice = 0.0;
    
    // Try to get total from different possible fields
    final totalFields = ['total', 'totalAmount', 'totalPrice', 'grandTotal'];
    for (String field in totalFields) {
      if (_orderData![field] != null) {
        try {
          if (_orderData![field] is String) {
            totalPrice = double.parse(_orderData![field]);
          } else if (_orderData![field] is num) {
            totalPrice = _orderData![field].toDouble();
          }
          if (totalPrice > 0) break;
        } catch (e) {
          print('❌ Error parsing total from field $field: ${_orderData![field]}');
        }
      }
    }
    
    // ✅ If no total found, calculate from items + shipping + tax
    if (totalPrice <= 0) {
      double calculatedSubtotal = 0.0;
      final items = _orderData!['items'];
      
      if (items is List) {
        for (var item in items) {
          if (item is Map<String, dynamic>) {
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
            
            // Get quantity with fallbacks
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
                  print('❌ Error parsing item quantity: $e');
                }
              }
            }
            
            calculatedSubtotal += (itemPrice * quantity);
          }
        }
      }
      
      // Add shipping and tax
      double shipping = 0.0;
      final shippingFields = ['shipping', 'shippingFee', 'shippingCost'];
      for (String field in shippingFields) {
        if (_orderData![field] != null) {
          try {
            if (_orderData![field] is String) {
              shipping = double.parse(_orderData![field]);
            } else if (_orderData![field] is num) {
              shipping = _orderData![field].toDouble();
            }
            if (shipping > 0) break;
          } catch (e) {
            print('❌ Error parsing shipping: $e');
          }
        }
      }
      
      double tax = 0.0;
      final taxFields = ['tax', 'taxAmount', 'taxes'];
      for (String field in taxFields) {
        if (_orderData![field] != null) {
          try {
            if (_orderData![field] is String) {
              tax = double.parse(_orderData![field]);
            } else if (_orderData![field] is num) {
              tax = _orderData![field].toDouble();
            }
            if (tax > 0) break;
          } catch (e) {
            print('❌ Error parsing tax: $e');
          }
        }
      }
      
      totalPrice = calculatedSubtotal + shipping + tax;
    }

    // ✅ Debug logging for header price
    print('💰 Order Header Price Debug:');
    print('  Order ID: $orderNumber');
    print('  Raw total from order data: ${_orderData!['total']}');
    print('  Calculated total price: \$${totalPrice.toStringAsFixed(2)}');
    print('  Available order data keys: ${_orderData!.keys.toList()}');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${orderNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (createdAt != null) ...[
                        SizedBox(height: 4),
                        Text(
                          'Placed on ${DateFormat('MMM dd, yyyy at h:mm a').format(createdAt)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusChip(_orderData!['status'] ?? 'pending'),
              ],
            ),
            SizedBox(height: 12),
            
            // ✅ Enhanced total price display with better formatting
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Total: ',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            // ✅ Add item count for better context
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                SizedBox(width: 6),
                Text(
                  '${_getItemCount()} item${_getItemCount() == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_orderData!['status'] != null) ...[
                  SizedBox(width: 16),
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Status: ${(_orderData!['status'] as String).toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildOrderStatus() {
    final status = _orderData!['status'] ?? 'pending';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            _buildStatusTimeline(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final statuses = [
      {'key': 'pending', 'label': 'Order Placed', 'icon': Icons.receipt},
      {'key': 'processing', 'label': 'Processing', 'icon': Icons.settings},
      {'key': 'shipped', 'label': 'Shipped', 'icon': Icons.local_shipping},
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    int currentIndex = statuses.indexWhere((s) => s['key'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      children: statuses.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> statusData = entry.value;
        bool isCompleted = index <= currentIndex;
        bool isCurrent = index == currentIndex;

        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusData['icon'],
                size: 18,
                color: isCompleted ? Colors.white : Colors.grey[600],
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusData['label'],
                    style: GoogleFonts.poppins(
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                      color: isCompleted ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  if (isCurrent) ...[
                    SizedBox(height: 2),
                    Text(
                      'Current status',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (index < statuses.length - 1)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? Colors.green : Colors.grey[300],
                margin: EdgeInsets.only(left: 15, top: 8),
              ),
          ],
        );
      }).toList(),
    );
  }

  // ✅ Enhanced _buildOrderItems method:

  Widget _buildOrderItems() {
    final items = _orderData!['items'];
    
    // ✅ Handle different data structures
    List<Map<String, dynamic>> itemsList = [];
    
    if (items == null) {
      print('⚠️ No items found in order data');
    } else if (items is List) {
      try {
        itemsList = List<Map<String, dynamic>>.from(
          items.map((item) => item is Map<String, dynamic> ? item : {})
        );
      } catch (e) {
        print('❌ Error parsing items list: $e');
        print('❌ Items data: $items');
      }
    } else {
      print('⚠️ Items is not a list: ${items.runtimeType}');
      print('⚠️ Items data: $items');
    }
    
    // ✅ Debug logging
    print('📦 Order Items Debug:');
    print('  Total items: ${itemsList.length}');
    for (int i = 0; i < itemsList.length; i++) {
      print('  Item $i: ${itemsList[i]}');
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_bag, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Items (${itemsList.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            if (itemsList.isEmpty) ...[
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No items found in this order',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        print('🔍 Full order data for debugging:');
                        print(_orderData);
                      },
                      child: Text('Debug Order Data'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: itemsList.length,
                separatorBuilder: (_, __) => Divider(
                  height: 24,
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (context, index) {
                  final item = itemsList[index];
                  return _buildItemRow(item);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Enhanced _buildItemRow method to handle different data structures:
  Widget _buildItemRow(Map<String, dynamic> item) {
    // ✅ Multiple fallbacks for image URL
    String? imageUrl;
    final imageFields = ['imageURL', 'imageUrl', 'image', 'productImage', 'thumbnail'];
    for (String field in imageFields) {
      if (item[field] != null && item[field].toString().isNotEmpty) {
        imageUrl = item[field].toString();
        break;
      }
    }
    
    // ✅ Multiple fallbacks for product name
    String productName = 'Unknown Product';
    final nameFields = ['productName', 'name', 'title', 'itemName'];
    for (String field in nameFields) {
      if (item[field] != null && item[field].toString().isNotEmpty) {
        productName = item[field].toString();
        break;
      }
    }
    
    // ✅ Multiple fallbacks for price with proper type conversion
    double price = 0.0;
    final priceFields = ['productPrice', 'price', 'unitPrice', 'itemPrice'];
    for (String field in priceFields) {
      if (item[field] != null) {
        try {
          if (item[field] is String) {
            price = double.parse(item[field]);
          } else if (item[field] is num) {
            price = item[field].toDouble();
          }
          if (price > 0) break;
        } catch (e) {
          print('❌ Error parsing price from field $field: ${item[field]}');
        }
      }
    }
    
    // ✅ Multiple fallbacks for quantity
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
          print('❌ Error parsing quantity from field $field: ${item[field]}');
        }
      }
    }

    // ✅ Debug logging
    print('📦 Order Item Debug:');
    print('  Name: $productName');
    print('  Price: \$${price.toStringAsFixed(2)}');
    print('  Quantity: $quantity');
    print('  Image URL: ${imageUrl ?? "No image"}');
    print('  Raw item data: $item');

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Enhanced Product Image with better error handling
          Container(
            width: 70,
            height: 70,
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
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Image load error for URL: $imageUrl');
                      print('❌ Error: $error');
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),
          SizedBox(width: 16),
          
          // ✅ Enhanced Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                
                // ✅ Additional product details
                if (item['brand'] != null && item['brand'].toString().isNotEmpty) ...[
                  Text(
                    'Brand: ${item['brand']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2),
                ],
                
                if (item['size'] != null && item['size'].toString().isNotEmpty) ...[
                  Text(
                    'Size: ${item['size']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2),
                ],
                
                if (item['condition'] != null && item['condition'].toString().isNotEmpty) ...[
                  Text(
                    'Condition: ${item['condition']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2),
                ],
                
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // ✅ Enhanced Price Display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.green.shade700,
                ),
              ),
              if (quantity > 1) ...[
                SizedBox(height: 4),
                Text(
                  'each',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Total: \$${(price * quantity).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.image_not_supported,
        size: 24,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildShippingInfo() {
    final shippingAddress = _orderData!['shippingAddress'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Shipping Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (shippingAddress != null && shippingAddress is Map<String, dynamic>) ...[
              _buildInfoRow('Name', shippingAddress['fullName'] ?? shippingAddress['name'] ?? 'N/A'),
              _buildInfoRow('Address', _formatAddress(shippingAddress)),
              if (shippingAddress['phoneNumber'] != null)
                _buildInfoRow('Phone', shippingAddress['phoneNumber']),
            ] else ...[
              Text(
                'No shipping information available',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ],
            if (_orderData!['trackingNumber'] != null) ...[
              Divider(height: 20),
              _buildInfoRow('Tracking Number', _orderData!['trackingNumber']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final paymentMethod = _orderData!['paymentMethod'];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Payment Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (paymentMethod != null && paymentMethod is Map<String, dynamic>) ...[
              _buildInfoRow('Method', paymentMethod['type'] ?? paymentMethod['name'] ?? 'N/A'),
              if (paymentMethod['details'] != null) ...[
                ...((paymentMethod['details'] as Map<String, dynamic>).entries.map(
                  (entry) => _buildInfoRow(
                    entry.key.toString().replaceAll('_', ' ').toUpperCase(),
                    entry.value.toString(),
                  ),
                )),
              ],
            ] else if (paymentMethod is String) ...[
              _buildInfoRow('Method', paymentMethod),
            ] else ...[
              Text(
                'No payment information available',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Enhanced _buildPricingBreakdown method:

  Widget _buildPricingBreakdown() {
    // ✅ Calculate subtotal from items if missing
    double calculatedSubtotal = 0.0;
    final items = _orderData!['items'];
    
    if (items is List) {
      for (var item in items) {
        if (item is Map<String, dynamic>) {
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
          
          // Get quantity with fallbacks
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
                print('❌ Error parsing item quantity: $e');
              }
            }
          }
          
          calculatedSubtotal += (itemPrice * quantity);
        }
      }
    }
    
    // ✅ Use order data or calculated values
    final subtotal = _orderData!['subtotal'] ?? calculatedSubtotal;
    final shipping = _orderData!['shipping'] ?? _orderData!['shippingFee'] ?? 0.0;
    final tax = _orderData!['tax'] ?? 0.0;
    final total = _orderData!['total'] ?? (subtotal + shipping + tax);

    print('💰 Pricing Debug:');
    print('  Calculated Subtotal: \$${calculatedSubtotal.toStringAsFixed(2)}');
    print('  Order Subtotal: \$${(_orderData!['subtotal'] ?? 0.0).toStringAsFixed(2)}');
    print('  Using Subtotal: \$${subtotal.toStringAsFixed(2)}');
    print('  Shipping: \$${shipping.toStringAsFixed(2)}');
    print('  Tax: \$${tax.toStringAsFixed(2)}');
    print('  Total: \$${total.toStringAsFixed(2)}');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Order Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildPriceRow('Subtotal', subtotal),
            if (shipping > 0) _buildPriceRow('Shipping', shipping),
            if (tax > 0) _buildPriceRow('Tax', tax),
            Divider(height: 24, thickness: 1),
            _buildPriceRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerActions() {
    final status = _orderData!['status'] ?? 'pending';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            if (status != 'delivered' && status != 'cancelled') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdatingStatus ? null : () => _showUpdateStatusDialog(),
                  icon: _isUpdatingStatus 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.update),
                  label: Text(_isUpdatingStatus ? 'Updating...' : 'Update Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _contactBuyer(),
                icon: Icon(Icons.phone),
                label: Text('Contact Buyer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerActions() {
    final status = _orderData!['status'] ?? 'pending';
    bool canCancel = !['delivered', 'cancelled'].contains(status.toLowerCase());
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _trackOrder(),
                    icon: Icon(Icons.local_shipping),
                    label: Text('Track Order'),
                  ),
                ),
                if (canCancel) ...[
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelOrder(),
                      icon: Icon(Icons.cancel),
                      label: Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (status == 'delivered') ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _leaveReview(),
                  icon: Icon(Icons.star),
                  label: Text('Leave Review'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTimeline() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            _buildTimelineItem(
              'Order Placed',
              (_orderData!['createdAt'] as Timestamp?)?.toDate(),
              Icons.receipt,
              true,
            ),
            // Add more timeline items based on order history
            // This would ideally come from a subcollection or order updates
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime? date, IconData icon, bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isCompleted ? Colors.white : Colors.grey[600],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (date != null) ...[
                SizedBox(height: 2),
                Text(
                  DateFormat('MMM dd, yyyy at h:mm a').format(date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, dynamic value, {bool isTotal = false}) {
    final amount = (value ?? 0.0).toDouble();
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green[700] : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    List<String> parts = [];
    
    if (address['addressLine1'] != null) parts.add(address['addressLine1']);
    if (address['addressLine2'] != null && address['addressLine2'].toString().isNotEmpty) {
      parts.add(address['addressLine2']);
    }
    if (address['city'] != null) parts.add(address['city']);
    if (address['state'] != null) parts.add(address['state']);
    if (address['zipCode'] != null) parts.add(address['zipCode']);
    if (address['country'] != null) parts.add(address['country']);
    
    return parts.join(', ');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Action Methods
  void _copyOrderId() {
    final orderNumber = _orderData!['orderNumber'] ?? _orderData!['orderId'] ?? widget.orderId;
    Clipboard.setData(ClipboardData(text: orderNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ID copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _contactBuyer() {
    // Implement contact buyer functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact buyer feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showUpdateStatusDialog() {
    final currentStatus = _orderData!['status'] ?? 'pending';
    final statusOptions = ['pending', 'processing', 'shipped', 'delivered'];
    String selectedStatus = currentStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Order Status',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select new status for this order:',
              style: GoogleFonts.poppins(),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedStatus = value;
                }
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(selectedStatus);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      setState(() {
        _orderData!['status'] = newStatus;
        _isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${newStatus.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isUpdatingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _trackOrder() {
    // Navigate to package tracking screen
    Navigator.pushNamed(
      context,
      '/package-tracking',
      arguments: widget.orderId,
    );
  }

  void _cancelOrder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Order',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus('cancelled');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _leaveReview() {
    // Implement review functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Review feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ✅ Add this helper method to the _OrderDetailScreenState class:

  int _getItemCount() {
    final items = _orderData!['items'];
    int totalCount = 0;
    
    if (items is List) {
      for (var item in items) {
        if (item is Map<String, dynamic>) {
          // Get quantity with fallbacks
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
                print('❌ Error parsing item quantity for count: $e');
              }
            }
          }
          totalCount += quantity;
        }
      }
    }
    
    return totalCount > 0 ? totalCount : 1; // Return at least 1 if no items found
  }
}