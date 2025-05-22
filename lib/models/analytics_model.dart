class SalesAnalytics {
  final double totalSales;
  final int ordersCount;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;
  final List<SalesDataPoint> salesByDate;
  final List<ProductPerformance> topProducts;
  final int totalViews;

  SalesAnalytics({
    required this.totalSales,
    required this.ordersCount,
    required this.averageOrderValue,
    required this.ordersByStatus,
    required this.salesByDate,
    required this.topProducts,
    required this.totalViews,
  });

  factory SalesAnalytics.empty() {
    return SalesAnalytics(
      totalSales: 0,
      ordersCount: 0,
      averageOrderValue: 0,
      ordersByStatus: {
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0
      },
      salesByDate: [],
      topProducts: [],
      totalViews: 0,
    );
  }
}

class SalesDataPoint {
  final String date;
  final double sales;

  SalesDataPoint({required this.date, required this.sales});
}

class ProductPerformance {
  final String productId;
  final String name;
  final int unitsSold;
  final double revenue;
  final String imageUrl;

  ProductPerformance({
    required this.productId,
    required this.name,
    required this.unitsSold,
    required this.revenue,
    required this.imageUrl,
  });
}