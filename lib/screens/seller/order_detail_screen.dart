import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haul/screens/buyer/package_tracking_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/currency_formatter.dart'; // ✅ Add this import

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
    _loadOrderData();
  }

  // ✅ COMPLETELY REPLACE your _loadOrderData method with this:
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
          // ✅ JUST USE THE RAW DATA - NO PROCESSING AT ALL
          _orderData = Map<String, dynamic>.from(doc.data()!);
          _orderData!['documentId'] = doc.id;
          
          // ✅ ONLY fix total - DO NOT CALL _addMissingTotalOnly
          if (_orderData!['total'] == null || _orderData!['total'] == 0.0) {
            double calculatedTotal = 0.0;
            if (_orderData!['items'] != null) {
              final items = _orderData!['items'] as List;
              for (var item in items) {
                if (item is Map<String, dynamic>) {
                  final price = (item['price'] ?? 0.0).toDouble();
                  final qty = (item['quantity'] ?? 1).toInt();
                  calculatedTotal += (price * qty);
                }
              }
              _orderData!['total'] = calculatedTotal;
            }
          }
          
          _isLoading = false;
        });
        
        // ✅ Debug IMMEDIATELY after loading
        print('🔍 IMMEDIATE DEBUG - Order keys: ${_orderData!.keys.toList()}');
        print('🔍 Has shipping: ${_orderData!.containsKey('shippingAddress')}');
        print('🔍 Has payment: ${_orderData!.containsKey('paymentMethod')}');
        
        if (_orderData!.containsKey('shippingAddress')) {
          print('✅ Shipping data: ${_orderData!['shippingAddress']}');
        }
        if (_orderData!.containsKey('paymentMethod')) {
          print('✅ Payment data: ${_orderData!['paymentMethod']}');
        }
        
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
                    CurrencyFormatter.format(totalPrice),
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
    final imageFields = ['imageURL', 'imageUrl', 'image', 'productImage', 'productImageUrl'];
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
                CurrencyFormatter.format(price),
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

  // ✅ Enhanced shipping info with better field mapping and debugging
  Widget _buildShippingInfo() {
    print('🚚 DEBUG Shipping Info FIXED:');
    print('Available order keys: ${_orderData!.keys.toList()}');
    
    // ✅ Direct access to shipping address
    Map<String, dynamic>? shippingAddress = _orderData!['shippingAddress'] as Map<String, dynamic>?;
    
    if (shippingAddress != null) {
      print('✅ Found shipping address: $shippingAddress');
    } else {
      print('❌ No shipping address found in _orderData');
      print('❌ Full _orderData keys: ${_orderData!.keys.toList()}');
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
            
            if (shippingAddress != null) ...[
              _buildInfoRow('Name', _extractShippingName(shippingAddress)),
              _buildInfoRow('Address', _formatShippingAddress(shippingAddress)),
              if (_extractPhoneNumber(shippingAddress).isNotEmpty)
                _buildInfoRow('Phone', _extractPhoneNumber(shippingAddress)),
              if (shippingAddress['email'] != null)
                _buildInfoRow('Email', shippingAddress['email'].toString()),
            ] else ...[
              // ✅ Enhanced debug info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No shipping information found',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEBUG: Available fields in _orderData:',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _orderData!.keys.join(', '),
                          style: GoogleFonts.robotoMono(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Helper methods for shipping data extraction
  String _extractShippingName(Map<String, dynamic> shippingData) {
    final nameFields = [
      'fullName', 'name', 'firstName', 'customerName', 
      'recipient', 'recipientName', 'buyerName'
    ];
    
    for (String field in nameFields) {
      if (shippingData[field] != null && shippingData[field].toString().isNotEmpty) {
        return shippingData[field].toString();
      }
    }
    
    // Try to combine first and last name
    final firstName = shippingData['firstName']?.toString() ?? '';
    final lastName = shippingData['lastName']?.toString() ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    
    return 'N/A';
  }

  String _formatShippingAddress(Map<String, dynamic> address) {
    List<String> parts = [];
    
    // Try different field name variations
    final addressFields = [
      ['addressLine1', 'address1', 'street', 'streetAddress'],
      ['addressLine2', 'address2', 'apartment', 'apt', 'suite'],
      ['city', 'locality'],
      ['state', 'province', 'region'],
      ['zipCode', 'zip', 'postalCode', 'postcode'],
      ['country']
    ];
    
    for (List<String> fieldGroup in addressFields) {
      for (String field in fieldGroup) {
        if (address[field] != null && address[field].toString().trim().isNotEmpty) {
          parts.add(address[field].toString());
          break; // Found a value for this group, move to next
        }
      }
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'No address provided';
  }

  String _extractPhoneNumber(Map<String, dynamic> shippingData) {
    final phoneFields = [
      'phoneNumber', 'phone', 'mobile', 'contactNumber', 
      'telephone', 'cellphone'
    ];
    
    for (String field in phoneFields) {
      if (shippingData[field] != null && shippingData[field].toString().isNotEmpty) {
        return shippingData[field].toString();
      }
    }
    
    return '';
  }

  // ✅ Enhanced payment info with better field mapping and debugging
  Widget _buildPaymentInfo() {
    print('💳 DEBUG Payment Info:');
    
    // ✅ Try multiple possible field names for payment method
    Map<String, dynamic>? paymentMethod;
    String? paymentType;
    
    final paymentFields = [
      'paymentMethod',
      'payment_method',
      'paymentInfo',
      'payment',
      'paymentDetails',
      'billing'
    ];
    
    for (String field in paymentFields) {
      if (_orderData![field] != null) {
        print('Found payment data in field: $field');
        print('Payment data: ${_orderData![field]}');
        
        if (_orderData![field] is Map<String, dynamic>) {
          paymentMethod = _orderData![field] as Map<String, dynamic>;
          break;
        } else if (_orderData![field] is String) {
          paymentType = _orderData![field] as String;
          break;
        }
      }
    }
    
    // ✅ Try to get payment type from root level
    if (paymentType == null && paymentMethod == null) {
      final typeFields = ['paymentType', 'payment_type', 'method'];
      for (String field in typeFields) {
        if (_orderData![field] != null) {
          paymentType = _orderData![field].toString();
          print('Found payment type: $paymentType');
          break;
        }
      }
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
            
            if (paymentMethod != null) ...[
              // ✅ Enhanced payment method display
              _buildInfoRow(
                'Method', 
                _extractPaymentMethod(paymentMethod)
              ),
              
              // ✅ Payment status
              if (paymentMethod['status'] != null)
                _buildInfoRow(
                  'Status', 
                  paymentMethod['status'].toString().toUpperCase()
                ),
                
              // ✅ Transaction ID
              if (paymentMethod['transactionId'] != null || paymentMethod['id'] != null)
                _buildInfoRow(
                  'Transaction ID', 
                  (paymentMethod['transactionId'] ?? paymentMethod['id']).toString()
                ),
                
              // ✅ Card details (if available and appropriate to show)
              if (paymentMethod['last4'] != null)
                _buildInfoRow(
                  'Card', 
                  '**** **** **** ${paymentMethod['last4']}'
                ),
                
              // ✅ Payment date
              // if (paymentMethod['paidAt'] != null || paymentMethod['paymentDate'] != null) {
              //   final paymentDate = paymentMethod['paidAt'] ?? paymentMethod['paymentDate'];
              //   String dateStr = 'N/A';
                
              //   if (paymentDate is Timestamp) {
              //     dateStr = DateFormat('MMM dd, yyyy at h:mm a').format(paymentDate.toDate());
              //   } else if (paymentDate is String) {
              //     try {
              //       final date = DateTime.parse(paymentDate);
              //       dateStr = DateFormat('MMM dd, yyyy at h:mm a').format(date);
              //     } catch (e) {
              //       dateStr = paymentDate;
              //     }
              //   }
                
              //   _buildInfoRow('Payment Date', dateStr);
              // }
              
            ] else if (paymentType != null) ...[
              _buildInfoRow('Method', paymentType),
              
            ] else ...[
              // ✅ No payment info found - show debug info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No payment information found',
                    style: GoogleFonts.poppins(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  ExpansionTile(
                    title: Text(
                      'Debug: Payment Related Fields',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getPaymentDebugInfo(),
                          style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            
            // ✅ Payment amount breakdown
            if (_orderData!['paymentAmount'] != null || _orderData!['amountPaid'] != null) ...[
              Divider(height: 20),
              _buildInfoRow(
                'Amount Paid', 
                CurrencyFormatter.format(((_orderData!['paymentAmount'] ?? _orderData!['amountPaid']) as num).toDouble())
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ Helper methods for payment data extraction
  String _extractPaymentMethod(Map<String, dynamic> paymentData) {
    final methodFields = [
      'type', 'method', 'name', 'brand', 'provider'
    ];
    
    for (String field in methodFields) {
      if (paymentData[field] != null && paymentData[field].toString().isNotEmpty) {
        return paymentData[field].toString();
      }
    }
    
    return 'N/A';
  }

  String _getPaymentDebugInfo() {
    final paymentRelatedFields = _orderData!.keys
        .where((key) => key.toLowerCase().contains('pay') || 
                        key.toLowerCase().contains('bill') ||
                        key.toLowerCase().contains('method') ||
                        key.toLowerCase().contains('transaction'))
        .toList();
    
    if (paymentRelatedFields.isEmpty) {
      return 'No payment-related fields found';
    }
    
    return paymentRelatedFields.map((field) => '$field: ${_orderData![field]}').join('\n');
  }

  // ✅ Enhanced _buildPricingBreakdown method:

  Widget _buildPricingBreakdown() {
    final pricing = _orderData!['pricing'] as Map<String, dynamic>?;
    final topLevelTotal = _orderData!['total'];
    
    // Use nested pricing if available, otherwise use top-level values
    final subtotal = pricing?['subtotal'] ?? _orderData!['subtotal'] ?? 0.0;
    final shipping = pricing?['shipping'] ?? _orderData!['shipping'] ?? 0.0;
    final tax = pricing?['tax'] ?? _orderData!['tax'] ?? 0.0;
    final total = pricing?['total'] ?? topLevelTotal ?? 0.0;
    
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
            SizedBox(height: 12),
            
            _buildInfoRow('Subtotal', CurrencyFormatter.format(subtotal)),
            if (shipping > 0)
              _buildInfoRow('Shipping', CurrencyFormatter.format(shipping)),
            if (tax > 0)
              _buildInfoRow('Tax', CurrencyFormatter.format(tax)),
            
            Divider(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(total),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageTrackingScreen(
        ),
      ),
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

  // ✅ Enhanced helper methods in order_detail_screen.dart
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

  String? _getItemImageUrl(Map<String, dynamic> item) {
    // ✅ Try both imageURL and imageUrl
    final imageFields = ['imageURL', 'imageUrl', 'image', 'productImage', 'productImageUrl'];
    
    for (String field in imageFields) {
      if (item[field] != null && item[field].toString().trim().isNotEmpty) {
        return item[field].toString();
      }
    }
    
    return null;
  }

  // ✅ Enhanced total calculation with both pricing structures
  String _calculateOrderTotal(Map<String, dynamic> order, List<Map<String, dynamic>> orderItems) {
    // ✅ Try top-level total first (new format)
    if (order['total'] != null && order['total'] != 0.0) {
      return _formatOrderTotal(order['total']);
    }
    
    // ✅ Try nested pricing total (your current format)
    if (order['pricing'] != null && order['pricing']['total'] != null) {
      return _formatOrderTotal(order['pricing']['total']);
    }
    
    // ✅ Calculate from items if no total found
    double calculatedTotal = 0.0;
    for (var item in orderItems) {
      final price = _getItemPrice(item);
      final quantity = _getItemQuantity(item);
      calculatedTotal += price * quantity;
    }
    
    return CurrencyFormatter.format(calculatedTotal);
  }

  // ✅ Update the _formatOrderTotal method (around line 1850)
  String _formatOrderTotal(dynamic total) {
    if (total == null) return CurrencyFormatter.format(0.0);
    
    if (total is num) {
      return CurrencyFormatter.format(total.toDouble());
    }
    
    if (total is String) {
      final parsed = double.tryParse(total);
      return CurrencyFormatter.format(parsed ?? 0.0);
    }
    
    return CurrencyFormatter.format(0.0);
  }

  // Add this missing method
  // String _formatOrderTotal(dynamic total) {
  //   if (total == null) return '0.00';
    
  //   if (total is num) {
  //     return total.toStringAsFixed(2);
  //   }
    
  //   if (total is String) {
  //     final parsed = double.tryParse(total);
  //     return parsed?.toStringAsFixed(2) ?? '0.00';
  //   }
    
  //   return '0.00';
  // }

  // ✅ Add this missing method for quantity extraction
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

  // ✅ Add missing total field only if it's not present
  // void _addMissingTotalOnly(Map<String, dynamic> orderData) {
  //   // ✅ Only calculate total if it's missing or 0
  //   if (orderData['total'] == null || orderData['total'] == 0.0) {
  //     if (orderData['items'] != null) {
  //       double calculatedTotal = 0.0; // ✅ Define the variable here
  //       final items = orderData['items'] as List;
        
  //       for (var item in items) {
  //         if (item is Map<String, dynamic>) {
  //           final price = (item['price'] ?? item['productPrice'] ?? 0.0).toDouble();
  //           final quantity = (item['quantity'] ?? 1).toInt();
  //           calculatedTotal += (price * quantity);
  //         }
  //       }
        
  //       // ✅ Only update total if it's missing or 0
  //       if (orderData['total'] == null || orderData['total'] == 0.0) {
  //         orderData['total'] = calculatedTotal;
  //       }
  //       if (orderData['subtotal'] == null) {
  //         orderData['subtotal'] = calculatedTotal;
  //       }
        
  //       print('💰 Calculated missing total: \$${calculatedTotal.toStringAsFixed(2)}');
  //     }
  //   }
    
  //   // ✅ Add imageURL field if only imageUrl exists (for compatibility)
  //   if (orderData['items'] != null) {
  //     final items = orderData['items'] as List;
  //     for (var item in items) {
  //       if (item is Map<String, dynamic>) {
  //         // Add imageURL if only imageUrl exists
  //         if (item['imageURL'] == null && item['imageUrl'] != null) {
  //           item['imageURL'] = item['imageUrl'];
  //         }
  //         // Add imageUrl if only imageURL exists
  //         if (item['imageUrl'] == null && item['imageURL'] != null) {
  //           item['imageUrl'] = item['imageURL'];
  //         }
  //       }
  //     }
  //   }
  // }
}