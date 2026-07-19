// ignore_for_file: avoid_print
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import '../repositories/dashboard_repository.dart';

class DashboardData {
  final double todaysRevenue;
  final int todaysOrders;
  final double grossProfit;
  final int activeProducts;
  final List<double> salesTrend;
  final Map<String, double> branchPerformance;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> aiInsights;
  
  final double revenueChangePercentage;
  final double salesTrendChangePercentage;
  final List<FlSpot> sparklineSpots;
  final List<Map<String, String>> branchesList;

  DashboardData({
    required this.todaysRevenue,
    required this.todaysOrders,
    required this.grossProfit,
    required this.activeProducts,
    required this.salesTrend,
    required this.branchPerformance,
    required this.topProducts,
    required this.aiInsights,
    required this.revenueChangePercentage,
    required this.salesTrendChangePercentage,
    required this.sparklineSpots,
    required this.branchesList,
  });
}

// Loads dashboard statistics from Firestore.
class DashboardService {
  final DashboardRepository _repository = DashboardRepository();

  // Returns a stream of aggregated dashboard data filtered by branch, month, and day.
  Stream<DashboardData> getDashboardDataStream({String? filterBranchName, String? filterBranchId, int? month, int? day}) {
    return Rx.combineLatest4(
      _repository.getSalesStream(),
      _repository.getInventoryStream(),
      _repository.getBranchesStream(),
      _repository.getProductsStream(),
      (QuerySnapshot salesSnap, QuerySnapshot inventorySnap, QuerySnapshot branchesSnap, QuerySnapshot productsSnap) {
        
        final salesDocs = salesSnap.docs;
        final inventoryDocs = inventorySnap.docs;
        final branchesDocs = branchesSnap.docs;
        final productsDocs = productsSnap.docs;

        final now = DateTime.now();
        int targetMonth = month ?? now.month;
        int targetDay = day ?? now.day;
        final targetStart = DateTime(2026, targetMonth, targetDay);
        final targetEnd = targetStart.add(const Duration(days: 1));
        final yesterdayStart = targetStart.subtract(const Duration(days: 1));

        double todayRev = 0;
        int todayOrders = 0;
        double todayProfit = 0;
        double yesterdayRev = 0;

        Map<String, double> categoryMap = {};
        Map<String, Map<String, dynamic>> productStats = {};
        Map<String, double> dateTrendMap = {};
        Map<String, double> branchRevenueMap = {};

        List<String> allowedNames = [
          'Main Branch',
          'Lipa Branch',
          'Tagaytay Branch',
          'Evo Branch',
          'Vermosa Branch'
        ];

        // Ensure we always export exactly these branches, mapped to their Firestore IDs
        List<Map<String, String>> exportedBranches = [];
        for (String name in allowedNames) {
           exportedBranches.add({'id': name, 'name': name}); // UI expects 'id' field as the dropdown value, so we pass the Name as the 'id'
        }

        // Determine actual branchID to filter by
        String? actualBranchId = filterBranchId;
        bool applyBranchFilter = false;
        
        if (filterBranchName != null && filterBranchName != 'All Branches') {
           applyBranchFilter = true;
           var matchingBranch = branchesDocs.cast<QueryDocumentSnapshot?>().firstWhere(
               (d) => d != null && (d.data() as Map)['branchName'] == filterBranchName,
               orElse: () => null
           );
           if (matchingBranch != null) {
               actualBranchId = matchingBranch.id;
           }
        } else if (filterBranchId != null) {
           applyBranchFilter = true;
        }

        for (var doc in salesDocs) {
          final data = doc.data() as Map<String, dynamic>;
          
          var dateVal = data['timestamp'];
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
          
          double total = (data['totalAmount'] ?? 0.0).toDouble();

          bool passesBranch = true;
          String docBranch = data['branchID'] ?? '';
          
          if (applyBranchFilter) {
            bool match = (actualBranchId != null && docBranch == actualBranchId);
            if (!match) passesBranch = false;
          }
          if (!passesBranch) continue;

          todayOrders++; // Live count of sales documents for the branch

          // Branch tracking for AI Insights (all month)
          bool passesMonth = month == null || date.month == month;
          if (passesMonth) {
            String bName = data['branchID'] ?? '';
            branchRevenueMap[bName] = (branchRevenueMap[bName] ?? 0) + total;
          }

          // KPI Date Filtering
          bool passesToday = false;
          if ((date.isAfter(targetStart) || date.isAtSameMomentAs(targetStart)) && date.isBefore(targetEnd)) {
            passesToday = true;
          }

          if (passesToday) {
            todayRev += total;
            todayProfit += (data['grossProfit'] ?? 0.0).toDouble();
          } else if ((date.isAfter(yesterdayStart) || date.isAtSameMomentAs(yesterdayStart)) && date.isBefore(targetStart)) {
            yesterdayRev += total;
          }

          if (!passesMonth) continue;
          
          String trendKey = month != null ? '${date.day}' : '${date.month}';
          dateTrendMap[trendKey] = (dateTrendMap[trendKey] ?? 0) + total;

          // DAY FILTER for Category & Products
          if (day != null && date.day != day) continue;

          List items = data['items'] ?? [];
          for (var item in items) {
            String cat = item['category'] ?? 'Coffee';
            int qty = (item['quantity'] ?? 1).toInt();
            double lineTotal = (item['totalPrice'] ?? 0.0).toDouble();
            
            categoryMap[cat] = (categoryMap[cat] ?? 0) + lineTotal;

            String pName = item['productName'] ?? 'Unknown';
            if (!productStats.containsKey(pName)) {
              productStats[pName] = {'name': pName, 'sold': 0, 'revenue': 0.0, 'image': item['image'] ?? item['productImage'] ?? item['imageUrl'] ?? ''};
            }
            productStats[pName]!['sold'] = (productStats[pName]!['sold'] as int) + qty;
            productStats[pName]!['revenue'] = (productStats[pName]!['revenue'] as double) + lineTotal;
          }
        }
        
        double revChange = yesterdayRev == 0 ? (todayRev > 0 ? 100.0 : 0.0) : ((todayRev - yesterdayRev) / yesterdayRev) * 100;
        
        if (categoryMap.isEmpty) {
          categoryMap = {'Coffee': 0, 'Tea': 0, 'Pastry': 0, 'Meal': 0, 'Dessert': 0};
        }

        Map<String, double> branchPerformanceMap = {};
        branchRevenueMap.forEach((key, val) {
          String bName = exportedBranches.firstWhere((e) => e['id'] == key, orElse: () => {'name': key})['name']!;
          branchPerformanceMap[bName] = val;
        });

        var topList = productStats.values.toList();
        topList.sort((a, b) => (b['sold'] as int).compareTo(a['sold'] as int));
        final topProducts = topList.take(5).toList();

        int activeProductsCount = 0;
        for (var doc in productsDocs) {
          final data = doc.data() as Map<String, dynamic>;
          String status = (data['status'] ?? '').toString().toLowerCase();
          if (status == 'active') {
            activeProductsCount++;
          }
        }


        List<Map<String, dynamic>> lowInventoryAlerts = [];
        for (var doc in inventoryDocs) {
          final data = doc.data() as Map<String, dynamic>;
          String invBranch = data['branchID'] ?? '';
          bool passesBranch = true;
          if (applyBranchFilter) {
            bool match = (actualBranchId != null && invBranch == actualBranchId);
            if (!match) passesBranch = false;
          }
          if (!passesBranch) continue;

          int qty = (data['stock'] ?? data['quantity'] ?? 0).toInt();
          int threshold = (data['reorderLevel'] ?? data['minimumStock'] ?? 10).toInt();
          if (qty <= threshold) {

            lowInventoryAlerts.add({'name': data['ingredientName'] ?? 'Unknown', 'qty': qty, 'threshold': threshold});
          }
        }

        List<double> trendData = [];
        List<FlSpot> sparkline = [];
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

        // --- AI Insights Generation ---
        final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
        List<Map<String, dynamic>> dynamicInsights = [];

        // 1. Highest Selling Category
        if (categoryMap.isNotEmpty) {
          var sortedCats = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          double totalCatSales = sortedCats.map((e) => e.value).fold(0.0, (a, b) => a + b);
          if (totalCatSales > 0) {
            var topCat = sortedCats.first;
            int pct = ((topCat.value / totalCatSales) * 100).toInt();
            dynamicInsights.add({
              'title': 'Top Selling Category',
              'content': '${topCat.key} generated ${formatter.format(topCat.value)} in revenue, representing $pct% of total sales.',
              'description': '${topCat.key} generated ${formatter.format(topCat.value)} in revenue, representing $pct% of total sales.',
              'type': 'High',
              'priority': 'High',
              'generatedDate': Timestamp.now(),
              'createdAt': Timestamp.now()
            });
          }
        }

        // 2. Inventory Alert
        if (lowInventoryAlerts.isNotEmpty) {
          var item = lowInventoryAlerts.first;
          dynamicInsights.add({
            'title': 'Inventory Alert',
            'content': '${item['name']} currently have only ${item['qty']} stocks remaining, below the minimum stock level of ${item['threshold']}.',
            'description': '${item['name']} currently have only ${item['qty']} stocks remaining, below the minimum stock level of ${item['threshold']}.',
            'type': 'High',
            'priority': 'High',
            'generatedDate': Timestamp.now(),
            'createdAt': Timestamp.now()
          });
        }

        // 3. Revenue Trend
        if (sortedKeys.isNotEmpty && dateTrendMap.length > 3) {
          // Compare first half of array to second half roughly
          double avg = trendData.fold(0.0, (a, b) => a + b) / trendData.length;
          dynamicInsights.add({
            'title': 'Revenue Trend',
            'content': 'Sales are averaging ${formatter.format(avg)} per day for the selected period.',
            'description': 'Sales are averaging ${formatter.format(avg)} per day for the selected period.',
            'type': 'Medium',
            'priority': 'Medium',
            'generatedDate': Timestamp.now(),
            'createdAt': Timestamp.now()
          });
        }

        // 4. Branch Performance
        if (branchRevenueMap.length > 1 && actualBranchId == null) {
          var sortedB = branchRevenueMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          if (sortedB.isNotEmpty && sortedB.first.value > 0) {
             String topBranchName = exportedBranches.firstWhere((e) => e['id'] == sortedB.first.key, orElse: () => {'name': 'Unknown Branch'})['name']!;
             dynamicInsights.add({
                'title': 'Branch Performance',
                'content': '$topBranchName is leading in sales with ${formatter.format(sortedB.first.value)} this month.',
                'description': '$topBranchName is leading in sales with ${formatter.format(sortedB.first.value)} this month.',
                'type': 'Low',
                'priority': 'Low',
                'generatedDate': Timestamp.now(),
                'createdAt': Timestamp.now()
             });
          }
        }

        // 5. Top Product Insight
        if (topList.isNotEmpty) {
           var topProd = topList.first;
           if ((topProd['sold'] as int) > 0) {
             dynamicInsights.add({
                'title': 'Top Product Highlight',
                'content': '${topProd['name']} is highly popular with ${topProd['sold']} units sold.',
                'description': '${topProd['name']} is highly popular with ${topProd['sold']} units sold.',
                'type': 'Low',
                'priority': 'Low',
                'generatedDate': Timestamp.now(),
                'createdAt': Timestamp.now()
             });
           }
        }

        // Sort by priority (High, Medium, Low)
        int priorityValue(String p) {
           if (p == 'High') return 1;
           if (p == 'Medium') return 2;
           if (p == 'Low') return 3;
           return 4;
        }
        dynamicInsights.sort((a, b) => priorityValue(a['type'] as String).compareTo(priorityValue(b['type'] as String)));
        
        final finalInsights = dynamicInsights.take(5).toList();

        return DashboardData(
          todaysRevenue: todayRev,
          todaysOrders: todayOrders,
          grossProfit: todayProfit,
          activeProducts: activeProductsCount,
          salesTrend: trendData,
          branchPerformance: branchPerformanceMap,
          topProducts: topProducts,
          aiInsights: finalInsights,
          revenueChangePercentage: revChange,
          salesTrendChangePercentage: revChange,
          sparklineSpots: sparkline.isNotEmpty ? sparkline : [FlSpot(0,0)],
          branchesList: exportedBranches,
        );
      }
    );
  }
}
