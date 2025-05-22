import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../../models/order_model.dart';

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
      
      // Get timeframe constraints based on selected range
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
      
      // Query orders within the timeframe
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerIds', arrayContains: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .orderBy('createdAt', descending: false)
          .get();
      
      // Process orders data
      double totalSales = 0;
      int totalOrders = ordersQuery.docs.length;
      Map<String, double> salesByDate = {};
      Map<String, int> ordersByStatus = {'pending': 0, 'processing': 0, 'shipped': 0, 'delivered': 0, 'cancelled': 0};
      Map<String, Map<String, dynamic>> productSales = {};
      
      for (var doc in ordersQuery.docs) {
        final orderData = doc.data();
        
        // Process order status
        final status = (orderData['status'] ?? 'pending').toLowerCase();
        ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;
        
        // Process items in this order
        final items = orderData['items'] as List<dynamic>?;
        if (items != null) {
          for (var item in items) {
            // Only count this seller's items
            if (item['sellerId'] == user.uid) {
              final price = (item['price'] ?? 0).toDouble();
              final quantity = (item['quantity'] ?? 1).toInt();
              final productId = item['productId'];
              final productTotal = price * quantity;
              
              // Add to total sales
              totalSales += productTotal;
              
              // Track product performance
              if (productId != null) {
                if (!productSales.containsKey(productId)) {
                  productSales[productId] = {
                    'productId': productId,
                    'name': item['name'] ?? 'Unknown Product',
                    'units': 0,
                    'revenue': 0.0,
                    'imageUrl': item['imageURL'] ?? '',
                  };
                }
                
                productSales[productId]!['units'] += quantity;
                productSales[productId]!['revenue'] += productTotal;
              }
            }
          }
        }
        
        // Process sales by date for the chart
        final createdAt = orderData['createdAt'] as Timestamp?;
        if (createdAt != null) {
          final date = createdAt.toDate();
          String dateKey;
          
          switch (_selectedTimeRange) {
            case 'daily':
              dateKey = DateFormat('MM/dd').format(date);
              break;
            case 'weekly':
              // Group by week number
              final weekNumber = (date.difference(startDate).inDays / 7).floor();
              dateKey = 'Week ${weekNumber + 1}';
              break;
            case 'monthly':
              dateKey = DateFormat('MMM').format(date);
              break;
            case 'yearly':
              dateKey = DateFormat('MMM').format(date);
              break;
            default:
              dateKey = DateFormat('MM/dd').format(date);
          }
          
          salesByDate[dateKey] = (salesByDate[dateKey] ?? 0) + (orderData['total'] ?? 0).toDouble();
        }
      }
      
      // Convert to list for the chart
      final salesChartData = salesByDate.entries.map((entry) {
        return {'date': entry.key, 'sales': entry.value};
      }).toList();
      
      // Sort by date
      salesChartData.sort((a, b) => a['date'].toString().compareTo(b['date'].toString()));
      
      // Get top products
      final topProducts = productSales.values.toList()
        ..sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
      
      // Get seller profile for view count
      final sellerDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(user.uid)
          .get();
          
      int viewCount = 0;
      if (sellerDoc.exists) {
        viewCount = sellerDoc.data()?['viewCount'] ?? 0;
      }
      
      // Update state with all the data
      setState(() {
        _salesData = salesChartData;
        _topProducts = topProducts.take(5).toList(); // Top 5 products
        _ordersByStatus = ordersByStatus;
        _metricsData = {
          'totalSales': totalSales,
          'totalOrders': totalOrders,
          'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0,
          'viewCount': viewCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics data'), backgroundColor: Colors.red),
      );
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
                '\$${_metricsData['totalSales'].toStringAsFixed(2)}',
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
                '\$${_metricsData['averageOrderValue'].toStringAsFixed(2)}',
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
                        '\$${_metricsData['totalSales'].toStringAsFixed(2)}',
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
                          '\$${_metricsData['averageOrderValue'].toStringAsFixed(2)}',
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

  Widget _buildSalesChart() {
    if (_salesData.isEmpty) {
      return Center(child: Text('No sales data available'));
    }

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <LineSeries<Map<String, dynamic>, String>>[
        LineSeries<Map<String, dynamic>, String>(
          dataSource: _salesData,
          xValueMapper: (data, _) => data['date'].toString(),
          yValueMapper: (data, _) => data['sales'],
          name: 'Sales',
          color: Theme.of(context).primaryColor,
          markerSettings: MarkerSettings(isVisible: false),
          enableTooltip: true,
        )
      ],
    );
  }

  Widget _buildDetailedSalesChart() {
    // Similar to _buildSalesChart but with more detailed options
    return _buildSalesChart();
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
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <ColumnSeries<Map<String, dynamic>, String>>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: _topProducts,
          xValueMapper: (data, _) => data['name'].toString(),
          yValueMapper: (data, _) => data['revenue'],
          name: 'Revenue',
          color: Theme.of(context).primaryColor,
          enableTooltip: true,
          width: 0.7,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        )
      ],
    );
  }

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
              DataCell(Text('\$${(data['sales'] as double).toStringAsFixed(2)}')),
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
          '\$${(product['revenue'] as double).toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedProductItem(Map<String, dynamic> product) {
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
                    '${product['units']}',
                    Icons.inventory_2_outlined,
                  ),
                ),
                Expanded(
                  child: _buildProductMetricTile(
                    'Revenue',
                    '\$${(product['revenue'] as double).toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildProductMetricTile(
                    'Avg. Price',
                    '\$${(product['revenue'] / product['units']).toStringAsFixed(2)}',
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