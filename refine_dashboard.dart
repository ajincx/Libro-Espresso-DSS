import 'dart:io';

void main() {
  // 1. Update dashboard_screen.dart to handle Day, Owner/Manager logic, and reorganize layout.
  File('lib/screens/dashboard/dashboard_screen.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../core/session_manager.dart';
import '../dashboard_widgets/dashboard_header.dart';
import '../dashboard_widgets/kpi_card.dart';
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
  final SessionManager _session = SessionManager();
  late Future<DashboardData> _dashboardFuture;

  String _selectedBranch = 'All Branches';
  String _selectedMonth = 'All Months';
  String _selectedDay = 'All Days';

  @override
  void initState() {
    super.initState();
    if (!_session.isOwner) {
      _selectedBranch = _session.assignedBranchId ?? 'Main Branch';
    }
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      int? m = _selectedMonth == 'All Months' ? null : ['All Months', 'January', 'February', 'March', 'April', 'May', 'June', 'July'].indexOf(_selectedMonth);
      int? d = _selectedDay == 'All Days' ? null : int.tryParse(_selectedDay);
      
      _dashboardFuture = _service.getDashboardData(
        branchId: _selectedBranch == 'All Branches' ? null : _selectedBranch,
        month: m,
        day: d,
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
              const SliverToBoxAdapter(child: DashboardHeader()),
              SliverToBoxAdapter(
                child: KpiCard(
                  revenue: data.todaysRevenue,
                  orders: data.todaysOrders,
                  profit: data.grossProfit,
                  lowStock: data.lowStockItems,
                ),
              ),
              SliverToBoxAdapter(
                child: SalesTrendCard(
                  dataPoints: data.salesTrend,
                  isOwner: _session.isOwner,
                  selectedBranch: _selectedBranch,
                  selectedMonth: _selectedMonth,
                  selectedDay: _selectedDay,
                  onBranchChanged: (v) { _selectedBranch = v; _refreshData(); },
                  onMonthChanged: (v) { 
                    _selectedMonth = v; 
                    _selectedDay = 'All Days'; // reset day when month changes
                    _refreshData(); 
                  },
                  onDayChanged: (v) { _selectedDay = v; _refreshData(); },
                ),
              ),
              SliverToBoxAdapter(child: CategoryChart(categorySales: data.categorySales)),
              const SliverToBoxAdapter(child: QuickAccess()),
              SliverToBoxAdapter(child: TopProducts(products: data.topProducts)),
              SliverToBoxAdapter(child: AiInsightsCard(insights: data.aiInsights)),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: const ImportFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const DashboardBottomNav(selectedIndex: 0),
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

  // 2. KpiCard with exact reference styling (Trend, vs yesterday, Right side Sparkline, 3 equal bottom sections)
  File('lib/screens/dashboard_widgets/kpi_card.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class KpiCard extends StatelessWidget {
  final double revenue;
  final int orders;
  final double profit;
  final int lowStock;

  const KpiCard({Key? key, required this.revenue, required this.orders, required this.profit, required this.lowStock}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8A1C3C), Color(0xFF5B0018)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6A1028).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Revenue", style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  Text('₱\${revenue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_drop_up, color: Colors.greenAccent, size: 16),
                            Text('12.4%', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('vs yesterday', style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Inter')),
                    ],
                  ),
                ],
              ),
              // Small white sparkline
              SizedBox(
                width: 80,
                height: 40,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), FlSpot(4, 4.5), FlSpot(5, 7)],
                        isCurved: true,
                        color: Colors.white,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildBottomMetric('Orders', orders.toString(), Colors.blueAccent)),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
              Expanded(child: _buildBottomMetric('Gross Profit', '₱\${profit.toStringAsFixed(0)}', Colors.greenAccent)),
              Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
              Expanded(child: _buildBottomMetric('Low Stock', lowStock.toString(), lowStock > 0 ? Colors.redAccent : Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomMetric(String title, String value, Color indicatorColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Inter')),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
      ],
    );
  }
}
''');

  // 3. Sales Trend Card (Contains Filters above chart, top right stats)
  File('lib/screens/dashboard_widgets/sales_trend_card.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesTrendCard extends StatelessWidget {
  final List<double> dataPoints;
  final bool isOwner;
  final String selectedBranch;
  final String selectedMonth;
  final String selectedDay;
  final Function(String) onBranchChanged;
  final Function(String) onMonthChanged;
  final Function(String) onDayChanged;

  const SalesTrendCard({
    Key? key,
    required this.dataPoints,
    required this.isOwner,
    required this.selectedBranch,
    required this.selectedMonth,
    required this.selectedDay,
    required this.onBranchChanged,
    required this.onMonthChanged,
    required this.onDayChanged,
  }) : super(key: key);

  List<String> _getDaysForMonth(String month) {
    if (month == 'All Months') return ['All Days'];
    int days = 31;
    if (month == 'February') days = 28;
    else if (['April', 'June', 'September', 'November'].contains(month)) days = 30;
    
    return ['All Days', ...List.generate(days, (i) => (i + 1).toString())];
  }

  @override
  Widget build(BuildContext context) {
    List<double> points = dataPoints.isEmpty ? [0,0,0,0,0,0,0] : dataPoints;
    double maxVal = points.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 100;
    List<FlSpot> spots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i]));
    
    double totalPeriodRevenue = points.fold(0, (a, b) => a + b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sales Trend', style: TextStyle(fontFamily: 'Georgia', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₱\${(totalPeriodRevenue / 1000).toStringAsFixed(1)}K', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6A1028))),
                  const Text('▲ 14.2%', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (isOwner)
                  _buildDropdown(selectedBranch, ['All Branches', 'Main Branch', 'Lipa Branch', 'Tagaytay Branch', 'Vermosa Branch', 'Evo Branch'], onBranchChanged),
                if (isOwner) const SizedBox(width: 8),
                _buildDropdown(selectedMonth, ['All Months', 'January', 'February', 'March', 'April', 'May', 'June', 'July'], onMonthChanged),
                const SizedBox(width: 8),
                _buildDropdown(selectedDay, _getDaysForMonth(selectedMonth), onDayChanged),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false, 
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Could add dynamic labels here
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: spots.length.toDouble() - 1,
                minY: 0, maxY: maxVal * 1.2,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: const Color(0xFF6A1028),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) => LineTooltipItem('₱\${spot.y.toStringAsFixed(0)}', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))).toList();
                    }
                  )
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF6A1028),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [const Color(0xFF6A1028).withOpacity(0.3), const Color(0xFF6A1028).withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildDropdown(String value, List<String> items, Function(String) onChanged) {
    if (!items.contains(value)) value = items.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6A1028)),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF4B5563))),
            );
          }).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}
''');

  // 4. Category Chart (Left donut, Right legend with percentages)
  File('lib/screens/dashboard_widgets/category_chart.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryChart extends StatelessWidget {
  final Map<String, double> categorySales;
  const CategoryChart({Key? key, required this.categorySales}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> colors = [const Color(0xFF6A1028), const Color(0xFFC89B3C), const Color(0xFF1E3A8A), const Color(0xFF047857), const Color(0xFFE11D48)];
    
    double total = categorySales.values.fold(0, (a, b) => a + b);
    if (total == 0) total = 1;

    List<PieChartSectionData> sections = [];
    int i = 0;
    categorySales.forEach((key, value) {
      if (value > 0) {
        sections.add(PieChartSectionData(
          color: colors[i % colors.length],
          value: value,
          title: '', // Text handled in legend
          radius: 30,
        ));
      }
      i++;
    });

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(color: Colors.grey.shade300, value: 1, title: '', radius: 30));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales by Category', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: sections,
                        ),
                      ),
                      const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegends(colors, total),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildLegends(List<Color> colors, double total) {
    List<Widget> legends = [];
    int i = 0;
    // Map default layout: Coffee, Pastries, Tea, Meals, Desserts
    List<String> orderedKeys = ['Coffee', 'Pastries', 'Tea', 'Meals', 'Desserts'];
    
    for (String key in orderedKeys) {
      double value = categorySales[key] ?? 0;
      if (value > 0) {
        double percentage = (value / total) * 100;
        legends.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(key, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF4B5563)))),
                Text('\${percentage.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
              ],
            ),
          )
        );
      }
      i++;
    }
    return legends;
  }
}
''');

  // 5. Quick Access (Inventory, COGS, Shrinkage, Forecast with Hover/Scale/Ripple)
  File('lib/screens/dashboard_widgets/quick_access.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class QuickAccess extends StatelessWidget {
  const QuickAccess({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
            childAspectRatio: 1.6,
            children: [
              _HoverCard(title: 'Inventory', subtitle: 'Manage stock', icon: Icons.inventory_2_rounded, color: const Color(0xFF1E3A8A)),
              _HoverCard(title: 'COGS', subtitle: 'Cost analysis', icon: Icons.analytics_rounded, color: const Color(0xFFC89B3C)),
              _HoverCard(title: 'Shrinkage', subtitle: 'Loss reports', icon: Icons.trending_down_rounded, color: const Color(0xFFE11D48)),
              _HoverCard(title: 'Forecast', subtitle: 'AI Predictions', icon: Icons.auto_awesome, color: const Color(0xFF047857)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _HoverCard({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isHovered ? 0.2 : 0.05), 
              blurRadius: _isHovered ? 20 : 10, 
              offset: const Offset(0, 5)
            )
          ],
          border: Border.all(color: widget.color.withOpacity(0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            splashColor: widget.color.withOpacity(0.1),
            highlightColor: widget.color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const Spacer(),
                  Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter')),
                  Text(widget.subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''');

}
