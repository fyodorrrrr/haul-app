import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/analytics_model.dart';

class AnalyticsProvider with ChangeNotifier {
  SalesAnalytics _analytics = SalesAnalytics.empty();
  bool _isLoading = false;
  String? _error;
  String _selectedTimeRange = 'weekly';

  SalesAnalytics get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedTimeRange => _selectedTimeRange;

  Future<void> fetchAnalytics({String timeRange = 'weekly'}) async {
    print('Starting fetchAnalytics...');
    _isLoading = true;
    _error = null;
    _selectedTimeRange = timeRange;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      print('Fetching analytics for user: ${user.uid}');
      
      // Get timeframe constraints
      final DateTime now = DateTime.now();
      DateTime startDate = now.subtract(Duration(days: 30)); // Default to 30 days
      
      print('Querying orders from ${startDate.toIso8601String()} to ${now.toIso8601String()}');
      
      // Query orders with better error handling
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerIds', arrayContains: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();
      
      print('Found ${ordersQuery.docs.length} orders');
      
      // Initialize data structures
      double totalSales = 0;
      int totalOrders = ordersQuery.docs.length;
      Map<String, int> ordersByStatus = {
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0
      };
      Map<String, double> salesByDateMap = {};
      Map<String, Map<String, dynamic>> productSales = {};
      
      // Process each order
      for (var doc in ordersQuery.docs) {
        try {
          final orderData = doc.data();
          print('Processing order: ${doc.id}');
          
          // Process order status
          final status = (orderData['status'] ?? 'pending').toString().toLowerCase();
          if (ordersByStatus.containsKey(status)) {
            ordersByStatus[status] = ordersByStatus[status]! + 1;
          }
          
          // Process order total for this seller
          final items = orderData['items'] as List<dynamic>?;
          double orderTotal = 0;
          
          if (items != null) {
            for (var item in items) {
              if (item['sellerId'] == user.uid) {
                final price = (item['price'] ?? 0).toDouble();
                final quantity = (item['quantity'] ?? 1).toInt();
                final itemTotal = price * quantity;
                
                totalSales += itemTotal;
                orderTotal += itemTotal;
                
                // Track product performance
                final productId = item['productId'];
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
                  productSales[productId]!['revenue'] += itemTotal;
                }
              }
            }
          }
          
          // Process sales by date
          final createdAt = orderData['createdAt'] as Timestamp?;
          if (createdAt != null && orderTotal > 0) {
            final date = createdAt.toDate();
            final dateKey = DateFormat('MM/dd').format(date);
            salesByDateMap[dateKey] = (salesByDateMap[dateKey] ?? 0) + orderTotal;
          }
        } catch (e) {
          print('Error processing order ${doc.id}: $e');
          // Continue processing other orders
        }
      }
      
      // Convert sales data to list
      List<SalesDataPoint> salesDataPoints = salesByDateMap.entries.map((entry) {
        return SalesDataPoint(date: entry.key, sales: entry.value);
      }).toList();
      
      // Sort by date
      salesDataPoints.sort((a, b) => a.date.compareTo(b.date));
      
      // Get top products
      List<ProductPerformance> topProducts = productSales.values.map((product) {
        return ProductPerformance(
          productId: product['productId'],
          name: product['name'],
          unitsSold: product['units'],
          revenue: product['revenue'],
          imageUrl: product['imageUrl'],
        );
      }).toList()..sort((a, b) => b.revenue.compareTo(a.revenue));
      
      // Get seller view count
      int totalViews = 0;
      try {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .doc(user.uid)
            .get();
        
        if (sellerDoc.exists) {
          totalViews = sellerDoc.data()?['viewCount'] ?? 0;
        }
      } catch (e) {
        print('Error fetching seller view count: $e');
      }
      
      // Create analytics object
      _analytics = SalesAnalytics(
        totalSales: totalSales,
        ordersCount: totalOrders,
        averageOrderValue: totalOrders > 0 ? totalSales / totalOrders : 0,
        ordersByStatus: ordersByStatus,
        salesByDate: salesDataPoints,
        topProducts: topProducts.take(5).toList(),
        totalViews: totalViews,
      );
      
      print('Analytics loaded successfully: ${salesDataPoints.length} data points, \$${totalSales} total sales');
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      print('Error fetching analytics: $e');
      _error = e.toString();
      _isLoading = false;
      
      // Provide fallback empty data
      _analytics = SalesAnalytics.empty();
      notifyListeners();
    }
  }
}