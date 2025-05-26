import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';
import '../../utils/currency_formatter.dart';
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  String _selectedTimeRange = 'weekly'; // 'daily', 'weekly', 'monthly', 'yearly'
  
  // Analytics data
  Map<String, dynamic> _metricsData = {
    'totalSales': 0.0,
    'totalOrders': 0,
    'averageOrderValue': 0.0,
    'viewCount': 0,
  };
  
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, int> _ordersByStatus = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Get timeframe constraints
      final DateTime now = DateTime.now();
      DateTime startDate;
      
      switch (_selectedTimeRange) {
        case 'daily':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 7));
          break;
        case 'weekly':
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 30));
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1).subtract(Duration(days: 90));
          break;
        case 'yearly':
          startDate = DateTime(now.year, 1, 1).subtract(Duration(days: 365));
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: 30));
      }
      
      print('🔍 Querying orders for seller: ${user.uid}');
      print('📅 Date range: ${startDate.toString()} to ${now.toString()}');
      
      // ✅ Strategy based on seller dashboard success pattern
      QuerySnapshot ordersQuery;
      
      try {
        // Strategy 1: Try sellerIds map structure (like seller dashboard)
        print('🔄 Trying Strategy 1: sellerIds map structure');
        ordersQuery = await FirebaseFirestore.instance
            .collection('orders')
            .where('sellerIds.${user.uid}', isEqualTo: true) // ✅ Map key access
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
            .orderBy('createdAt', descending: false)
            .get();
        
        print('📋 Strategy 1: Found ${ordersQuery.docs.length} orders');
        
        if (ordersQuery.docs.isEmpty) {
          throw Exception('No orders found with map structure');
        }
        
      } catch (e) {
        print('⚠️ Strategy 1 failed: $e');
        
        // Strategy 2: Get all orders and filter manually (like order provider)
        print('🔄 Trying Strategy 2: Manual filtering');
        try {
          ordersQuery = await FirebaseFirestore.instance
              .collection('orders')
              .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
              .orderBy('createdAt', descending: false)
              .get();
          
          print('📋 Strategy 2: Found ${ordersQuery.docs.length} total orders to filter');
          
        } catch (e2) {
          print('⚠️ Strategy 2 failed: $e2');
          
          // Strategy 3: Get all orders without date filter (fallback)
          print('🔄 Trying Strategy 3: All orders fallback');
          ordersQuery = await FirebaseFirestore.instance
              .collection('orders')
              .get();
          
          print('📋 Strategy 3: Found ${ordersQuery.docs.length} total orders');
        }
      }
      
      // Initialize analytics data
      double totalSales = 0;
      int totalOrders = 0;
      Map<String, double> salesByDate = {};
      Map<String, int> ordersByStatus = {
        'pending': 0, 
        'processing': 0, 
        'shipped': 0, 
        'delivered': 0, 
        'cancelled': 0
      };
      Map<String, Map<String, dynamic>> productSales = {};
      Set<String> processedOrderIds = {};
      
      // ✅ Enhanced order filtering based on order provider logic
      print('📝 Processing ${ordersQuery.docs.length} orders...');
      
      for (var doc in ordersQuery.docs) {
        final orderData = doc.data() as Map<String, dynamic>;
        final orderId = doc.id;
        
        bool hasSellerItems = false;
        double sellerOrderTotal = 0.0;
        
        // ✅ Check sellerIds in multiple formats (from order provider pattern)
        final sellerIds = orderData['sellerIds'];
        
        if (sellerIds is Map<String, dynamic>) {
          // Map format: {"sellerId1": true, "sellerId2": true}
          hasSellerItems = sellerIds.containsKey(user.uid) && sellerIds[user.uid] == true;
          print('  Order $orderId: Map format check - $hasSellerItems');
        } else if (sellerIds is List<dynamic>) {
          // List format: ["sellerId1", "sellerId2"]
          hasSellerItems = sellerIds.contains(user.uid);
          print('  Order $orderId: List format check - $hasSellerItems');
        }
        
        // ✅ Also check sellerId field
        if (!hasSellerItems && orderData['sellerId'] == user.uid) {
          hasSellerItems = true;
          print('  Order $orderId: sellerId field check - $hasSellerItems');
        }
        
        // ✅ Fallback: Check items for seller products
        if (!hasSellerItems) {
          final items = orderData['items'] as List<dynamic>?;
          if (items != null) {
            for (var item in items) {
              if (item is Map<String, dynamic> && item['sellerId'] == user.uid) {
                hasSellerItems = true;
                print('  Order $orderId: Items check - found seller item');
                break;
              }
            }
          }
        }
        
        if (hasSellerItems) {
          // ✅ Calculate order total for seller
          final orderTotal = orderData['total'];
          if (orderTotal != null) {
            sellerOrderTotal = _ensureDouble(orderTotal);
          }
          
          // ✅ Always process items for product tracking
          final items = orderData['items'] as List<dynamic>?;
          if (items != null) {
            for (var item in items) {
              if (item is Map<String, dynamic> && item['sellerId'] == user.uid) {
                final price = _ensureDouble(item['price']);
                final quantity = (item['quantity'] ?? 1).toInt();
                final itemTotal = price * quantity;
                
                // ✅ If no order total, calculate from items
                if (orderTotal == null) {
                  sellerOrderTotal += itemTotal;
                }
                
                // ✅ Enhanced product tracking with better data extraction
                final productId = item['productId']?.toString();
                final productName = item['name']?.toString() ?? 
                                  item['productName']?.toString() ?? 
                                  'Unknown Product';
                final imageUrl = item['imageURL']?.toString() ?? 
                                item['imageUrl']?.toString() ?? 
                                item['image']?.toString() ?? '';
                
                print('📦 Processing product: $productName (ID: $productId, Qty: $quantity, Price: ${CurrencyFormatter.format(price)})');
                
                if (productId != null && productId.isNotEmpty) {
                  if (!productSales.containsKey(productId)) {
                    productSales[productId] = {
                      'productId': productId,
                      'name': productName,
                      'units': 0,
                      'revenue': 0.0,
                      'imageUrl': imageUrl,
                    };
                    print('✅ Created new product entry: $productName');
                  }
                  
                  // ✅ Update product metrics
                  productSales[productId]!['units'] = (productSales[productId]!['units'] as int) + quantity;
                  productSales[productId]!['revenue'] = (productSales[productId]!['revenue'] as double) + itemTotal;
                  
                  print('📊 Updated ${productName}: ${productSales[productId]!['units']} units, ${CurrencyFormatter.format(productSales[productId]!['revenue'] as double)} revenue');
                } else {
                  print('⚠️ Missing productId for item: $productName');
                }
              }
            }
          }
          
          // ✅ Only count if not already processed and has meaningful total
          if (!processedOrderIds.contains(orderId) && sellerOrderTotal > 0) {
            processedOrderIds.add(orderId);
            totalOrders++;
            totalSales += sellerOrderTotal;
            
            // Count by status
            final status = (orderData['status'] ?? 'pending').toString().toLowerCase();
            if (ordersByStatus.containsKey(status)) {
              ordersByStatus[status] = ordersByStatus[status]! + 1;
            } else {
              ordersByStatus['pending'] = (ordersByStatus['pending'] ?? 0) + 1;
            }
            
            // Group by date for chart (only if within date range)
            final createdAt = orderData['createdAt'] as Timestamp?;
            if (createdAt != null) {
              final date = createdAt.toDate();
              if (date.isAfter(startDate) && date.isBefore(now.add(Duration(days: 1)))) {
                String dateKey = _getDateKey(date, startDate);
                salesByDate[dateKey] = (salesByDate[dateKey] ?? 0.0) + sellerOrderTotal;
              }
            }
            
            print('✅ Processed order $orderId: ${CurrencyFormatter.format(sellerOrderTotal)} (Status: ${orderData['status']})');
          }
        }
      }
      
      // Convert sales data to chart format
      final salesChartData = salesByDate.entries.map((entry) {
        return {'date': entry.key, 'sales': entry.value};
      }).toList();
      
      // Sort by date
      salesChartData.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
      
      // Get top products
      final topProducts = productSales.values.toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
      
      // Get seller view count
      int viewCount = 0;
      try {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .get();
        if (sellerDoc.exists) {
          viewCount = sellerDoc.data()?['viewCount'] ?? 0;
        }
      } catch (e) {
        print('⚠️ Could not fetch seller view count: $e');
      }
      
      // ✅ Final analytics summary
      print('📊 Final Analytics Results:');
      print('  - Processed ${ordersQuery.docs.length} total orders');
      print('  - Found ${processedOrderIds.length} orders with seller items');
      print('  - Total Orders: $totalOrders');
      print('  - Total Sales: ${CurrencyFormatter.format(totalSales)}');
      print('  - Average Order: ${totalOrders > 0 ? CurrencyFormatter.format(totalSales / totalOrders) : "₱0.00"}');
      print('  - Top Products: ${topProducts.length}');
      print('  - Orders by Status: $ordersByStatus');
      print('  - Sales by Date entries: ${salesByDate.length}');
      
      // Update UI
      setState(() {
        _salesData = salesChartData;
        _topProducts = topProducts.take(5).toList();
        _ordersByStatus = ordersByStatus;
        _metricsData = {
          'totalSales': totalSales,
          'totalOrders': totalOrders,
          'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0.0,
          'viewCount': viewCount,
        };
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Error loading analytics data: $e');
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load analytics: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadAnalyticsData,
          ),
        ),
      );
    }
  }

  // ✅ Helper method for date grouping
  String _getDateKey(DateTime date, DateTime startDate) {
    switch (_selectedTimeRange) {
      case 'daily':
        return DateFormat('MM/dd').format(date);
      case 'weekly':
        final weekNumber = (date.difference(startDate).inDays / 7).floor();
        return 'Week ${weekNumber + 1}';
      case 'monthly':
        return DateFormat('MMM').format(date);
      case 'yearly':
        return DateFormat('MMM yyyy').format(date);
      default:
        return DateFormat('MM/dd').format(date);
    }
  }

  // ✅ Add helper method for safe double conversion
  double _ensureDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ✅ Update _formatRevenue method
  String _formatRevenue(dynamic amount) {
    final doubleAmount = _ensureDouble(amount);
    if (doubleAmount >= 100000) {
      return CurrencyFormatter.formatWithCommas(doubleAmount);
    } else {
      return CurrencyFormatter.format(doubleAmount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Sales'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Time range selector
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'daily', label: Text('Daily')),
                      ButtonSegment(value: 'weekly', label: Text('Weekly')),
                      ButtonSegment(value: 'monthly', label: Text('Monthly')),
                      ButtonSegment(value: 'yearly', label: Text('Yearly')),
                    ],
                    selected: {_selectedTimeRange},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedTimeRange = newSelection.first;
                      });
                      _loadAnalyticsData();
                    },
                  ),
                ),
                
                // Main content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // OVERVIEW TAB
                      _buildOverviewTab(),
                      
                      // SALES TAB
                      _buildSalesTab(),
                      
                      // PRODUCTS TAB
                      _buildProductsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard(
                'Total Sales', 
                _formatRevenue(_metricsData['totalSales']), // ✅ Enhanced formatting
                Icons.attach_money,
                Colors.green
              ),
              _buildMetricCard(
                'Orders', 
                _metricsData['totalOrders'].toString(),
                Icons.shopping_bag_outlined,
                Colors.blue
              ),
              _buildMetricCard(
                'Avg. Order', 
                CurrencyFormatter.format(_metricsData['averageOrderValue']), // ✅ Changed from $ to ₱
                Icons.insights,
                Colors.purple
              ),
              _buildMetricCard(
                'Shop Views', 
                _metricsData['viewCount'].toString(),
                Icons.visibility_outlined,
                Colors.orange
              ),
            ],
          ),
          
          SizedBox(height: 24),
          Text(
            'Orders by Status',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Orders by status chart
          Container(
            height: 200,
            child: _buildOrderStatusChart(),
          ),
          
          SizedBox(height: 24),
          Text(
            'Sales Trend',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Mini sales chart
          Container(
            height: 200,
            child: _buildSalesChart(),
          ),
          
          SizedBox(height: 24),
          Text(
            'Top Products',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Top products list
          ..._topProducts.take(3).map((product) => _buildTopProductItem(product)).toList(),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales summary
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Sales',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatWithCommas(_ensureDouble(_metricsData['totalSales'])), // ✅ Safe conversion
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniMetric(
                          'Orders',
                          _metricsData['totalOrders'].toString(),
                          Icons.shopping_bag_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildMiniMetric(
                          'Avg. Order',
                          CurrencyFormatter.format(_ensureDouble(_metricsData['averageOrderValue'])), // ✅ Safe conversion
                          Icons.insert_chart_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          Text(
            'Sales Over Time',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Detailed sales chart
          Container(
            height: 300,
            child: _buildDetailedSalesChart(),
          ),
          
          SizedBox(height: 24),
          Text(
            'Orders by Status',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Status distribution
          Container(
            height: 200,
            child: _buildOrderStatusChart(),
          ),
          
          SizedBox(height: 24),
          Text(
            'Daily Revenue Breakdown',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Daily breakdown table
          _buildSalesTable(),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performing Products',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Products revenue chart
          Container(
            height: 250,
            child: _buildProductsRevenueChart(),
          ),
          
          SizedBox(height: 24),
          Text(
            'Product Performance',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // Detailed product list
          ..._topProducts.map((product) => _buildDetailedProductItem(product)).toList(),
          
          if (_topProducts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No product data available',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            Spacer(),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey[700]),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ✅ Update chart data conversion
  Widget _buildSalesChart() {
    if (_salesData.isEmpty) {
      return Center(child: Text('No sales data available'));
    }

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x: ${CurrencyFormatter.symbol}point.y',
      ),
      series: <LineSeries<Map<String, dynamic>, String>>[
        LineSeries<Map<String, dynamic>, String>(
          dataSource: _salesData,
          xValueMapper: (data, _) => data['date'].toString(),
          yValueMapper: (data, _) => _ensureDouble(data['sales']), // ✅ Safe conversion
          name: 'Sales',
          color: Theme.of(context).primaryColor,
          markerSettings: MarkerSettings(isVisible: false),
          enableTooltip: true,
        )
      ],
    );
  }

  Widget _buildDetailedSalesChart() {
    if (_salesData.isEmpty) {
      return Center(child: Text('No sales data available'));
    }

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(
        labelFormat: '${CurrencyFormatter.symbol}{value}',
        numberFormat: NumberFormat.compact(),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <LineSeries<Map<String, dynamic>, String>>[
        LineSeries<Map<String, dynamic>, String>(
          dataSource: _salesData,
          xValueMapper: (data, _) => data['date'].toString(),
          yValueMapper: (data, _) => _ensureDouble(data['sales']), // ✅ Safe conversion
          name: 'Sales (₱)',
          color: Theme.of(context).primaryColor,
          markerSettings: MarkerSettings(isVisible: true, width: 6, height: 6),
          enableTooltip: true,
        )
      ],
    );
  }

  Widget _buildOrderStatusChart() {
    if (_ordersByStatus.isEmpty) {
      return Center(child: Text('No order data available'));
    }
    
    final List<PieData> chartData = _ordersByStatus.entries.map((entry) {
      return PieData(entry.key, entry.value);
    }).toList();

    return SfCircularChart(
      legend: Legend(isVisible: true, position: LegendPosition.bottom),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <PieSeries<PieData, String>>[
        PieSeries<PieData, String>(
          dataSource: chartData,
          xValueMapper: (data, _) => data.status,
          yValueMapper: (data, _) => data.count,
          dataLabelSettings: DataLabelSettings(isVisible: true),
          enableTooltip: true,
        )
      ],
    );
  }

  Widget _buildProductsRevenueChart() {
    if (_topProducts.isEmpty) {
      return Center(child: Text('No product data available'));
    }

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x: ${CurrencyFormatter.symbol}point.y',
      ),
      series: <ColumnSeries<Map<String, dynamic>, String>>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: _topProducts,
          xValueMapper: (data, _) => data['name'].toString(),
          yValueMapper: (data, _) => _ensureDouble(data['revenue']), // ✅ Safe conversion
          name: 'Revenue',
          color: Theme.of(context).primaryColor,
          enableTooltip: true,
          width: 0.7,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        )
      ],
    );
  }

  // ✅ Update sales table data conversion
  Widget _buildSalesTable() {
    if (_salesData.isEmpty) {
      return Center(
        child: Text('No sales data available'),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: DataTable(
        columns: [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Sales')),
        ],
        rows: _salesData.map((data) {
          return DataRow(
            cells: [
              DataCell(Text(data['date'].toString())),
              DataCell(Text(CurrencyFormatter.format(_ensureDouble(data['sales'])))), // ✅ Safe conversion
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProductItem(Map<String, dynamic> product) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey[600],
                ),
        ),
        title: Text(
          product['name'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${product['units']} units sold',
        ),
        trailing: Text(
          CurrencyFormatter.format(_ensureDouble(product['revenue'])), // ✅ Safe conversion
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedProductItem(Map<String, dynamic> product) {
    final revenue = _ensureDouble(product['revenue']);
    final units = (product['units'] ?? 1).toInt();
    final avgPrice = units > 0 ? revenue / units : 0.0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey[600],
                        ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Product ID: ${product['productId']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildProductMetricTile(
                    'Units Sold',
                    '${units}',
                    Icons.inventory_2_outlined,
                  ),
                ),
                Expanded(
                  child: _buildProductMetricTile(
                    'Revenue',
                    CurrencyFormatter.format(revenue), // ✅ Already converted to double
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildProductMetricTile(
                    'Avg. Price',
                    CurrencyFormatter.format(avgPrice), // ✅ Already calculated as double
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductMetricTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class PieData {
  final String status;
  final int count;
  
  PieData(this.status, this.count);
}