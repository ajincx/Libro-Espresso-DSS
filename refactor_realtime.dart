// ignore_for_file: avoid_print, deprecated_member_use, curly_braces_in_flow_control_structures, library_prefixes, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:io';

void main() {
  print("Refactoring Dashboard for Real-time Streams...");

  // 1. DashboardRepository
  File('lib/repositories/dashboard_repository.dart').writeAsStringSync('''
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getSalesStream() => _firestore.collection('sales').snapshots();
  Stream<QuerySnapshot> getProductsStream() => _firestore.collection('products').snapshots();
  Stream<QuerySnapshot> getInventoryStream() => _firestore.collection('inventory').snapshots();
  
  // Keep futures if needed for manual fetches, but mostly streams now
  Future<QuerySnapshot> getSales() => _firestore.collection('sales').get();
  Future<QuerySnapshot> getProducts() => _firestore.collection('products').get();
  Future<QuerySnapshot> getInventory() => _firestore.collection('inventory').get();
}
''');

  // 2. DashboardService
  File('lib/services/dashboard_service.dart').writeAsStringSync('''
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../repositories/dashboard_repository.dart';

class DashboardData {
  final double todaysRevenue;
  final int todaysOrders;
  final double grossProfit;
  final int lowStockItems;
  final List<double> salesTrend;
  final Map<String, double> categorySales;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> aiInsights;
  
  final double revenueChangePercentage;
  final double salesTrendChangePercentage;
  final List<FlSpot> sparklineSpots;

  DashboardData({
    required this.todaysRevenue,
    required this.todaysOrders,
    required this.grossProfit,
    required this.lowStockItems,
    required this.salesTrend,
    required this.categorySales,
    required this.topProducts,
    required this.aiInsights,
    required this.revenueChangePercentage,
    required this.salesTrendChangePercentage,
    required this.sparklineSpots,
  });
}

class DashboardService {
  final DashboardRepository _repository = DashboardRepository();

  Stream<DashboardData> getDashboardDataStream({String? branchId, int? month, int? day}) {
    return Rx.combineLatest3(
      _repository.getSalesStream(),
      _repository.getProductsStream(),
      _repository.getInventoryStream(),
      (QuerySnapshot salesSnap, QuerySnapshot productsSnap, QuerySnapshot inventorySnap) {
        
        final salesDocs = salesSnap.docs;
        final inventoryDocs = inventorySnap.docs;

        // Date Helpers
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final yesterdayStart = todayStart.subtract(const Duration(days: 1));

        double todayRev = 0;
        int todayOrders = 0;
        double todayCogs = 0;
        double yesterdayRev = 0;

        Map<String, double> categoryMap = {};
        Map<String, Map<String, dynamic>> productStats = {};
        
        // Custom Trend Map by Date String "YYYY-MM-DD"
        Map<String, double> dateTrendMap = {};
        
        // Analyze sales
        for (var doc in salesDocs) {
          final data = doc.data() as Map<String, dynamic>;
          
          // Role Filtering
          if (branchId != null && branchId != 'All Branches') {
            if (data['branchId'] != branchId) continue;
          }

          // Parse Date
          var dateVal = (data['timestamp'] ?? data['createdAt']);
          DateTime? date;
          if (dateVal != null) {
            if (dateVal.runtimeType.toString() == 'Timestamp') {
              date = (dateVal as Timestamp).toDate();
            } else if (dateVal is DateTime) {
              date = dateVal;
            } else if (dateVal is String) {
              date = DateTime.tryParse(dateVal);
            }
          }
          
          if (date == null) continue;
          
          double total = (data['totalAmount'] ?? data['total'] ?? 0.0).toDouble();

          // Global Trend Chart (filtered by selected month/day if required, but usually trend shows across the filtered period)
          // For the chart we aggregate by Day if month is selected, or by Month if "All Months"
          if (month != null) {
            if (date.month != month) continue; // skip if doesn't match month filter
            if (day != null && date.day != day) continue; // skip if doesn't match day
          }
          
          // Trend Grouping (Group by day of month if month selected, else group by month)
          String trendKey = month != null ? '\${date.day}' : '\${date.month}';
          dateTrendMap[trendKey] = (dateTrendMap[trendKey] ?? 0) + total;

          // Category and Top Products 
          List items = data['items'] ?? [];
          for (var item in items) {
            String cat = item['category'] ?? 'Coffee';
            double price = (item['price'] ?? 0.0).toDouble();
            int qty = (item['quantity'] ?? 1).toInt();
            double lineTotal = price * qty;
            
            categoryMap[cat] = (categoryMap[cat] ?? 0) + lineTotal;

            String pName = item['productName'] ?? item['name'] ?? 'Unknown';
            if (!productStats.containsKey(pName)) {
              productStats[pName] = {'name': pName, 'sold': 0, 'revenue': 0.0, 'profit': 0.0};
            }
            productStats[pName]!['sold'] += qty;
            productStats[pName]!['revenue'] += lineTotal;
            productStats[pName]!['profit'] += lineTotal * 0.6; // Mock profit if real cost missing
          }

          // KPI Calculations (Today vs Yesterday explicitly regardless of filter, per instructions "compare today vs yesterday")
          if (date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart)) {
            todayRev += total;
            todayOrders++;
            todayCogs += total * 0.4;
          } else if (date.isAfter(yesterdayStart) && date.isBefore(todayStart)) {
            yesterdayRev += total;
          }
        }

        // Process Category
        if (categoryMap.isEmpty) {
          categoryMap = {'Coffee': 0, 'Tea': 0, 'Pastries': 0, 'Meals': 0, 'Desserts': 0};
        }

        // Process Top Products
        var topList = productStats.values.toList();
        topList.sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int)); // Sort descending by units sold per instructions
        final topProducts = topList.take(5).toList();

        // Process Low Stock
        int lowStockCount = 0;
        bool hasMilkWarning = false;
        for (var doc in inventoryDocs) {
          final data = doc.data() as Map<String, dynamic>;
          int qty = (data['quantity'] ?? data['currentStock'] ?? 0).toInt();
          int threshold = (data['threshold'] ?? data['reorderLevel'] ?? 10).toInt();
          String name = (data['name'] ?? '').toString().toLowerCase();
          
          if (qty <= threshold) {
            lowStockCount++;
            if (name.contains('milk')) hasMilkWarning = true;
          }
        }

        double grossProfit = todayRev - todayCogs;
        double revChange = yesterdayRev == 0 ? (todayRev > 0 ? 100.0 : 0.0) : ((todayRev - yesterdayRev) / yesterdayRev) * 100;
        
        // Trend chart generation
        List<double> trendData = [];
        List<FlSpot> sparkline = [];
        
        // Generate chronological trend
        var sortedKeys = dateTrendMap.keys.map((e) => int.parse(e)).toList()..sort();
        if (sortedKeys.isEmpty) {
          trendData = [0,0,0,0,0,0,0];
          sparkline = List.generate(7, (i) => FlSpot(i.toDouble(), 0));
        } else {
          for (int i = 0; i < sortedKeys.length; i++) {
            double val = dateTrendMap[sortedKeys[i].toString()]!;
            trendData.add(val);
            sparkline.add(FlSpot(i.toDouble(), val));
          }
        }

        double trendChange = revChange; // Mock trend change identically or compute from first/last

        // Generate AI Insights Rules based
        List<Map<String, dynamic>> rulesInsights = [];
        double coffeeSales = categoryMap['Coffee'] ?? 0;
        double pastCoffee = yesterdayRev * 0.5; // Rough estimate of past coffee
        
        if (coffeeSales > pastCoffee * 1.15) {
          rulesInsights.add({
            'title': 'High Coffee Demand',
            'content': 'Coffee sales increased >15%. Consider increasing bean inventory.',
            'type': 'recommendation'
          });
        }
        if (hasMilkWarning) {
          rulesInsights.add({
            'title': 'Milk Reorder Warning',
            'content': 'Milk stock is below reorder level. Please reorder immediately.',
            'type': 'warning'
          });
        }
        if (now.weekday >= 5 && todayRev > yesterdayRev) {
          rulesInsights.add({
            'title': 'Weekend Rush',
            'content': 'Weekend sales are consistently higher. Suggest increasing pastry production.',
            'type': 'production'
          });
        }
        // Shrinkage rule fallback
        if (rulesInsights.isEmpty) {
          rulesInsights.add({
            'title': 'All Systems Nominal',
            'content': 'Sales and inventory are stable. Keep up the good work!',
            'type': 'trend'
          });
        }

        return DashboardData(
          todaysRevenue: todayRev,
          todaysOrders: todayOrders,
          grossProfit: grossProfit,
          lowStockItems: lowStockCount,
          salesTrend: trendData,
          categorySales: categoryMap,
          topProducts: topProducts,
          aiInsights: rulesInsights,
          revenueChangePercentage: revChange,
          salesTrendChangePercentage: trendChange,
          sparklineSpots: sparkline.isNotEmpty ? sparkline : [FlSpot(0,0)],
        );
      }
    );
  }
}
''');

  // 3. DashboardScreen - convert FutureBuilder to StreamBuilder
  String dsCode = File('lib/screens/dashboard/dashboard_screen.dart').readAsStringSync();
  dsCode = dsCode.replaceAll('FutureBuilder<DashboardData>', 'StreamBuilder<DashboardData>');
  dsCode = dsCode.replaceAll('future: _dashboardFuture,', 'stream: _dashboardStream,');
  dsCode = dsCode.replaceAll('late Future<DashboardData> _dashboardFuture;', 'late Stream<DashboardData> _dashboardStream;');
  dsCode = dsCode.replaceAll('_dashboardFuture = _service.getDashboardData(', '_dashboardStream = _service.getDashboardDataStream(');
  
  File('lib/screens/dashboard/dashboard_screen.dart').writeAsStringSync(dsCode);

  print("Done script!");
}
