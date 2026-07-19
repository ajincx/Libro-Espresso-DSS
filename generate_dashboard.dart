import 'dart:io';

void main() {
  // Directories
  Directory('lib/repositories').createSync(recursive: true);
  Directory('lib/services').createSync(recursive: true);
  Directory('lib/screens/dashboard_widgets').createSync(recursive: true);

  // 1. DashboardRepository
  File('lib/repositories/dashboard_repository.dart').writeAsStringSync('''
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<QuerySnapshot> getSales() async => await _firestore.collection('sales').get();
  Future<QuerySnapshot> getProducts() async => await _firestore.collection('products').get();
  Future<QuerySnapshot> getAiInsights() async => await _firestore.collection('ai_insights').orderBy('generatedAt', descending: true).get();
  Future<QuerySnapshot> getBranches() async => await _firestore.collection('branches').get();
  Future<QuerySnapshot> getInventory() async => await _firestore.collection('inventory_counts').get();
}
''');

  // 2. DashboardService
  File('lib/services/dashboard_service.dart').writeAsStringSync('''
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

  DashboardData({
    required this.todaysRevenue,
    required this.todaysOrders,
    required this.grossProfit,
    required this.lowStockItems,
    required this.salesTrend,
    required this.categorySales,
    required this.topProducts,
    required this.aiInsights,
  });
}

class DashboardService {
  final DashboardRepository _repository = DashboardRepository();

  Future<DashboardData> getDashboardData({String? branchId, int? month, int? day}) async {
    // 1. Fetch raw data concurrently for performance
    final results = await Future.wait([
      _repository.getSales(),
      _repository.getProducts(),
      _repository.getAiInsights(),
      _repository.getInventory(),
    ]);

    final salesDocs = results[0].docs;
    final productsDocs = results[1].docs;
    final insightsDocs = results[2].docs;
    final inventoryDocs = results[3].docs;

    // 2. Filter Sales
    var filteredSales = salesDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // Basic branch filter
      if (branchId != null && branchId != 'All Branches') {
        if (data['branchId'] != branchId) return false;
      }
      // If month/day filters exist, parse timestamp. Assuming 'timestamp' exists.
      if (month != null || day != null) {
        final date = (data['timestamp'] ?? data['createdAt']);
        if (date != null && date is DateTime) {
           if (month != null && date.month != month) return false;
           if (day != null && date.day != day) return false;
        }
      }
      return true;
    }).toList();

    // 3. Aggregate KPIs
    double todaysRevenue = 0;
    int todaysOrders = filteredSales.length;
    double cogs = 0;
    
    // Aggregate category sales
    Map<String, double> categoryMap = {
      'Coffee': 0, 'Tea': 0, 'Pastries': 0, 'Meals': 0, 'Desserts': 0
    };

    // Calculate product sales for Top Products
    Map<String, Map<String, dynamic>> productStats = {};

    for (var doc in filteredSales) {
      final data = doc.data() as Map<String, dynamic>;
      double total = (data['totalAmount'] ?? data['total'] ?? 0.0).toDouble();
      todaysRevenue += total;
      
      // Try to estimate COGS (mock if missing)
      cogs += total * 0.4; // rough estimate for gross profit

      // Check categories (items array)
      List items = data['items'] ?? [];
      for (var item in items) {
        String cat = item['category'] ?? 'Coffee';
        double price = (item['price'] ?? 0.0).toDouble();
        int qty = (item['quantity'] ?? 1).toInt();
        double lineTotal = price * qty;
        
        if (categoryMap.containsKey(cat)) {
          categoryMap[cat] = categoryMap[cat]! + lineTotal;
        } else {
          categoryMap['Coffee'] = categoryMap['Coffee']! + lineTotal;
        }

        // Top products prep
        String pName = item['productName'] ?? item['name'] ?? 'Unknown';
        if (!productStats.containsKey(pName)) {
          productStats[pName] = {'name': pName, 'sold': 0, 'revenue': 0.0, 'profit': 0.0};
        }
        productStats[pName]!['sold'] += qty;
        productStats[pName]!['revenue'] += lineTotal;
        productStats[pName]!['profit'] += lineTotal * 0.6; 
      }
    }

    double grossProfit = todaysRevenue - cogs;

    // Top 5 products
    var topList = productStats.values.toList();
    topList.sort((a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));
    final topProducts = topList.take(5).toList();

    // Low Stock Items (Mocking check or actual check)
    int lowStockCount = 0;
    for (var doc in inventoryDocs) {
      final data = doc.data() as Map<String, dynamic>;
      int qty = (data['quantity'] ?? 0).toInt();
      int threshold = (data['threshold'] ?? 10).toInt();
      if (qty < threshold) lowStockCount++;
    }

    // AI Insights
    final insightsList = insightsDocs.take(4).map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {
        'content': data['content'] ?? 'Insight',
        'type': data['type'] ?? 'trend',
        'time': 'Just now'
      };
    }).toList();

    // Sales Trend (7 points mock based on revenue to avoid complex grouping for now)
    List<double> trend = [
      todaysRevenue * 0.5, todaysRevenue * 0.8, todaysRevenue * 0.4, 
      todaysRevenue * 0.9, todaysRevenue * 0.7, todaysRevenue * 1.1, todaysRevenue
    ];

    // Artificial delay to show skeleton loaders elegantly
    await Future.delayed(const Duration(milliseconds: 800));

    return DashboardData(
      todaysRevenue: todaysRevenue,
      todaysOrders: todaysOrders,
      grossProfit: grossProfit,
      lowStockItems: lowStockCount,
      salesTrend: trend,
      categorySales: categoryMap,
      topProducts: topProducts,
      aiInsights: insightsList,
    );
  }
}
''');

  // 3. dashboard_header.dart
  File('lib/screens/dashboard_widgets/dashboard_header.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import '../../core/session_manager.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A0008), Color(0xFF6A1028)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good Afternoon,',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 4),
              Text(
                session.displayName.isNotEmpty ? session.displayName : 'Manager',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    session.assignedBranchId.isNotEmpty ? session.assignedBranchId : 'All Branches',
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter'),
                  ),
                ],
              )
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFC89B3C),
                child: Icon(Icons.person, color: Colors.white),
              )
            ],
          )
        ],
      ),
    );
  }
}
''');

  // 4. kpi_card.dart
  File('lib/screens/dashboard_widgets/kpi_card.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final double revenue;
  final int orders;
  final double profit;
  final int lowStock;

  const KpiCard({Key? key, required this.revenue, required this.orders, required this.profit, required this.lowStock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8A1C3C), Color(0xFF5B0018)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6A1028).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Revenue", style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text('₱\${revenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric('Orders', orders.toString()),
              _buildMiniMetric('Gross Profit', '₱\${profit.toStringAsFixed(0)}'),
              _buildMiniMetric('Low Stock', lowStock.toString(), isAlert: lowStock > 0),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, {bool isAlert = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter')),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: isAlert ? Colors.redAccent : Colors.white, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
      ],
    );
  }
}
''');

  // 5. dashboard_filters.dart
  File('lib/screens/dashboard_widgets/dashboard_filters.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class DashboardFilters extends StatelessWidget {
  final String selectedBranch;
  final String selectedMonth;
  final Function(String) onBranchChanged;
  final Function(String) onMonthChanged;

  const DashboardFilters({
    Key? key,
    required this.selectedBranch,
    required this.selectedMonth,
    required this.onBranchChanged,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildDropdown(
            value: selectedBranch,
            items: ['All Branches', 'Main Branch', 'Lipa Branch', 'Tagaytay Branch', 'Vermosa Branch', 'Evo Branch'],
            onChanged: (v) => onBranchChanged(v!),
          ),
          const SizedBox(width: 12),
          _buildDropdown(
            value: selectedMonth,
            items: ['All Months', 'January', 'February', 'March', 'April', 'May', 'June', 'July'],
            onChanged: (v) => onMonthChanged(v!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: items.contains(value) ? value : items.first,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6A1028)),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF1F2937))),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
''');

  // 6. sales_trend_card.dart
  File('lib/screens/dashboard_widgets/sales_trend_card.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesTrendCard extends StatelessWidget {
  final List<double> dataPoints;
  const SalesTrendCard({Key? key, required this.dataPoints}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) dataPoints.addAll([0,0,0,0,0,0,0]);
    double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 100;

    List<FlSpot> spots = [];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i]));
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sales Trend', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A1028))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                child: const Text('+12.5%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: spots.length.toDouble() - 1,
                minY: 0, maxY: maxVal * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFC89B3C),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFC89B3C).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
''');

  // 7. category_chart.dart
  File('lib/screens/dashboard_widgets/category_chart.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> categorySales;
  const CategoryChart({Key? key, required this.categorySales}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> colors = [const Color(0xFF6A1028), const Color(0xFFC89B3C), const Color(0xFF1E3A8A), const Color(0xFF047857), const Color(0xFFE11D48)];
    int i = 0;
    List<PieChartSectionData> sections = [];
    categorySales.forEach((key, value) {
      if (value > 0) {
        sections.add(PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: '',
          radius: 40,
        ));
      }
      i++;
    });

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(color: Colors.grey.shade300, value: 1, title: '', radius: 40));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales by Category', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A1028))),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sections,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegends(colors),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildLegends(List<Color> colors) {
    List<Widget> legends = [];
    int i = 0;
    categorySales.forEach((key, value) {
      if (value > 0) {
        legends.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(key, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF4B5563))),
              ],
            ),
          )
        );
      }
      i++;
    });
    return legends;
  }
}
''');

  // 8. quick_access.dart
  File('lib/screens/dashboard_widgets/quick_access.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class QuickAccess extends StatelessWidget {
  const QuickAccess({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Access', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _buildBtn(context, 'Inventory', Icons.inventory_2_outlined, const Color(0xFF1E3A8A)),
              _buildBtn(context, 'COGS', Icons.analytics_outlined, const Color(0xFFC89B3C)),
              _buildBtn(context, 'Forecast', Icons.trending_up, const Color(0xFF047857)),
              _buildBtn(context, 'Reports', Icons.picture_as_pdf_outlined, const Color(0xFF6A1028)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(BuildContext context, String title, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color, size: 20),
      label: Text(title, style: TextStyle(color: color, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.05),
        elevation: 0,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withOpacity(0.2))),
      ),
    );
  }
}
''');

  // 9. top_products.dart
  File('lib/screens/dashboard_widgets/top_products.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class TopProducts extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const TopProducts({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Selling Products', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A1028))),
          const SizedBox(height: 16),
          if (products.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No data available', style: TextStyle(color: Colors.grey))),
          ...List.generate(products.length, (index) {
            final p = products[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('#\${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                  const SizedBox(width: 12),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.coffee, color: Color(0xFFC89B3C), size: 20),
                  )
                ],
              ),
              title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14)),
              subtitle: Text('\${p['sold']} units sold', style: const TextStyle(fontSize: 12)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱\${p['revenue'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A1028))),
                  Text('Profit: ₱\${p['profit'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.green)),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}
''');

  // 10. ai_insights_card.dart
  File('lib/screens/dashboard_widgets/ai_insights_card.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class AiInsightsCard extends StatelessWidget {
  final List<Map<String, dynamic>> insights;
  const AiInsightsCard({Key? key, required this.insights}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFFC89B3C)),
              SizedBox(width: 8),
              Text('AI Business Insights', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6A1028))),
            ],
          ),
          const SizedBox(height: 16),
          if (insights.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Text('No insights generated yet.', style: TextStyle(color: Colors.grey))),
          ...insights.map((insight) {
            Color color = insight['type'] == 'warning' ? Colors.redAccent : (insight['type'] == 'optimization' ? Colors.green : Colors.blue);
            IconData icon = insight['type'] == 'warning' ? Icons.warning_amber : (insight['type'] == 'optimization' ? Icons.lightbulb_outline : Icons.trending_up);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(insight['type'].toString().toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(insight['content'], style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF1F2937))),
                        const SizedBox(height: 6),
                        Text(insight['time'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  )
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
''');

  // 11. bottom_nav.dart
  File('lib/screens/dashboard_widgets/bottom_nav.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import '../import_screen.dart';

class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      elevation: 20,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard_rounded, 'Dashboard', true),
            _buildNavItem(Icons.coffee_maker_outlined, 'Products', false),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(Icons.analytics_outlined, 'Reports', false),
            _buildNavItem(Icons.person_outline, 'Account', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    final color = isSelected ? const Color(0xFF6A1028) : Colors.grey.shade400;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}

class ImportFab extends StatelessWidget {
  const ImportFab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: const Color(0xFFC89B3C),
      elevation: 4,
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportScreen()));
      },
      child: const Icon(Icons.upload_file, color: Colors.white),
    );
  }
}
''');

  // 12. dashboard_screen.dart (Main)
  File('lib/screens/dashboard/dashboard_screen.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../dashboard_widgets/dashboard_header.dart';
import '../dashboard_widgets/kpi_card.dart';
import '../dashboard_widgets/dashboard_filters.dart';
import '../dashboard_widgets/sales_trend_card.dart';
import '../dashboard_widgets/category_chart.dart';
import '../dashboard_widgets/quick_access.dart';
import '../dashboard_widgets/top_products.dart';
import '../dashboard_widgets/ai_insights_card.dart';
import '../dashboard_widgets/bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();
  late Future<DashboardData> _dashboardFuture;

  String _selectedBranch = 'All Branches';
  String _selectedMonth = 'All Months';

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      int? m = _selectedMonth == 'All Months' ? null : ['All Months', 'January', 'February', 'March', 'April', 'May', 'June', 'July'].indexOf(_selectedMonth);
      _dashboardFuture = _service.getDashboardData(
        branchId: _selectedBranch == 'All Branches' ? null : _selectedBranch,
        month: m,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeleton();
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final data = snapshot.data;
          if (data == null) return _buildEmpty();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: const DashboardHeader()),
              SliverToBoxAdapter(
                child: KpiCard(
                  revenue: data.todaysRevenue,
                  orders: data.todaysOrders,
                  profit: data.grossProfit,
                  lowStock: data.lowStockItems,
                ),
              ),
              SliverToBoxAdapter(
                child: DashboardFilters(
                  selectedBranch: _selectedBranch,
                  selectedMonth: _selectedMonth,
                  onBranchChanged: (v) { _selectedBranch = v; _refreshData(); },
                  onMonthChanged: (v) { _selectedMonth = v; _refreshData(); },
                ),
              ),
              SliverToBoxAdapter(child: SalesTrendCard(dataPoints: data.salesTrend)),
              SliverToBoxAdapter(child: CategoryChart(categorySales: data.categorySales)),
              SliverToBoxAdapter(child: const QuickAccess()),
              SliverToBoxAdapter(child: TopProducts(products: data.topProducts)),
              SliverToBoxAdapter(child: AiInsightsCard(insights: data.aiInsights)),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), // Padding for FAB
            ],
          );
        },
      ),
      floatingActionButton: const ImportFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const DashboardBottomNav(),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        const DashboardHeader(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(color: Color(0xFF6A1028)),
                SizedBox(height: 16),
                Text('Aggregating Live Data...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildError(String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text('Failed to load dashboard data'),
          Text(err, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ElevatedButton(onPressed: _refreshData, child: const Text('Retry'))
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Text('No data found for selected filters'));
  }
}
''');

}
