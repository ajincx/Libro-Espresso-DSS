import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:intl/intl.dart';
import '../repositories/dashboard_repository.dart';

class CogsData {
  final double totalRevenue;
  final double totalCogs;
  final double grossProfit;
  final double grossProfitMargin;
  final List<FlSpot> dailyCostTrend;
  final List<String> dailyCostLabels;
  final Map<String, double> costByCategory;
  final List<Map<String, dynamic>> productCostBreakdown;
  final Map<String, dynamic>? highestCostProduct;
  final Map<String, dynamic>? lowestCostProduct;
  final List<Map<String, dynamic>> dailyCostHistory;
  final List<Map<String, String>> branchesList;

  CogsData({
    required this.totalRevenue,
    required this.totalCogs,
    required this.grossProfit,
    required this.grossProfitMargin,
    required this.dailyCostTrend,
    required this.dailyCostLabels,
    required this.costByCategory,
    required this.productCostBreakdown,
    this.highestCostProduct,
    this.lowestCostProduct,
    required this.dailyCostHistory,
    required this.branchesList,
  });
}

class CogsService {
  final DashboardRepository _repository = DashboardRepository();

  Stream<CogsData> getCogsDataStream({String? filterBranchName, String? filterBranchId, int? month, int? day}) {
    return Rx.combineLatest2(
      _repository.getSalesStream(),
      _repository.getBranchesStream(),
      (QuerySnapshot salesSnap, QuerySnapshot branchesSnap) {
        
        final salesDocs = salesSnap.docs;
        final branchesDocs = branchesSnap.docs;

        double totalRevenue = 0;
        double totalCogs = 0;
        double grossProfit = 0;

        Map<String, double> categoryCostMap = {};
        Map<String, Map<String, dynamic>> productStats = {};
        Map<String, Map<String, dynamic>> dailyHistoryMap = {};

        List<String> allowedNames = [
          'All Branches',
          'Main Branch',
          'Lipa Branch',
          'Tagaytay Branch',
          'Evo Branch',
          'Vermosa Branch'
        ];

        List<Map<String, String>> exportedBranches = [];
        for (String name in allowedNames) {
           exportedBranches.add({'id': name, 'name': name}); 
        }

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

        print('=== COGS DEBUG ===');
        print('Selected Branch: $filterBranchName (ID: $filterBranchId)');
        print('Selected Month: $month');
        print('Selected Day: $day');
        print('Total Documents retrieved: ${salesDocs.length}');

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

          bool passesBranch = true;
          String docBranch = data['branchID'] ?? '';
          if (applyBranchFilter) {
            bool match = (actualBranchId != null && docBranch == actualBranchId);
            if (!match) passesBranch = false;
          }
          if (!passesBranch) continue;

          // Month filter
          if (month != null && date.month != month) continue;
          
          // Day filter
          if (day != null && date.day != day) continue;

          double sRev = (data['totalAmount'] ?? 0.0).toDouble();
          double sCost = (data['cost'] ?? 0.0).toDouble();
          double sProfit = (data['grossProfit'] ?? 0.0).toDouble();
          
          print('Included Doc: $date | Rev: $sRev | Cost: $sCost | Profit: $sProfit');

          totalRevenue += sRev;
          totalCogs += sCost;
          grossProfit += sProfit;

          // Daily History
          String dayKey = DateFormat('MMM dd, yyyy').format(date);
          String shortDayKey = DateFormat('MMM dd').format(date);
          if (!dailyHistoryMap.containsKey(dayKey)) {
            dailyHistoryMap[dayKey] = {
              'date': dayKey,
              'shortDate': shortDayKey,
              'dateObj': date,
              'revenue': 0.0,
              'cost': 0.0,
              'profit': 0.0
            };
          }
          dailyHistoryMap[dayKey]!['revenue'] = (dailyHistoryMap[dayKey]!['revenue'] as double) + sRev;
          dailyHistoryMap[dayKey]!['cost'] = (dailyHistoryMap[dayKey]!['cost'] as double) + sCost;
          dailyHistoryMap[dayKey]!['profit'] = (dailyHistoryMap[dayKey]!['profit'] as double) + sProfit;

          // Items Allocation
          List items = data['items'] ?? [];
          for (var item in items) {
            String cat = item['category'] ?? 'Other';
            String pName = item['productName'] ?? 'Unknown';
            int qty = (item['quantity'] ?? 1).toInt();
            double iRev = (item['totalPrice'] ?? 0.0).toDouble();
            
            double allocatedCost = sRev > 0 ? (iRev / sRev) * sCost : 0.0;
            
            categoryCostMap[cat] = (categoryCostMap[cat] ?? 0.0) + allocatedCost;

            if (!productStats.containsKey(pName)) {
              productStats[pName] = {
                'productName': pName,
                'unitsSold': 0,
                'revenue': 0.0,
                'cost': 0.0,
                'profit': 0.0
              };
            }
            productStats[pName]!['unitsSold'] = (productStats[pName]!['unitsSold'] as int) + qty;
            productStats[pName]!['revenue'] = (productStats[pName]!['revenue'] as double) + iRev;
            productStats[pName]!['cost'] = (productStats[pName]!['cost'] as double) + allocatedCost;
          }
        }

        // Finalize productStats profit
        for (var pName in productStats.keys) {
          productStats[pName]!['profit'] = (productStats[pName]!['revenue'] as double) - (productStats[pName]!['cost'] as double);
        }

        double margin = totalRevenue > 0 ? (grossProfit / totalRevenue) * 100 : 0.0;

        // Daily Cost Trend (FlSpot)
        List<FlSpot> dailyCostTrend = [];
        List<String> dailyCostLabels = [];
        
        print('=== COGS TOTALS ===');
        print('Total Revenue: $totalRevenue');
        print('Total COGS: $totalCogs');
        print('Total Gross Profit: $grossProfit');

        var historyValues = dailyHistoryMap.values.toList();
        historyValues.sort((a, b) => (a['dateObj'] as DateTime).compareTo(b['dateObj'] as DateTime));
        
        for (int i = 0; i < historyValues.length; i++) {
          dailyCostTrend.add(FlSpot(i.toDouble(), historyValues[i]['cost'] as double));
          dailyCostLabels.add(historyValues[i]['shortDate'] as String);
        }

        // Product Breakdown
        var productCostBreakdown = productStats.values.toList();
        productCostBreakdown.sort((a, b) => (b['cost'] as double).compareTo(a['cost'] as double));

        Map<String, dynamic>? highest;
        Map<String, dynamic>? lowest;
        if (productCostBreakdown.isNotEmpty) {
           highest = productCostBreakdown.first;
           lowest = productCostBreakdown.last;
        }

        return CogsData(
          totalRevenue: totalRevenue,
          totalCogs: totalCogs,
          grossProfit: grossProfit,
          grossProfitMargin: margin,
          dailyCostTrend: dailyCostTrend,
          dailyCostLabels: dailyCostLabels,
          costByCategory: categoryCostMap,
          productCostBreakdown: productCostBreakdown,
          highestCostProduct: highest,
          lowestCostProduct: lowest,
          dailyCostHistory: historyValues,
          branchesList: exportedBranches,
        );
      }
    );
  }
}
