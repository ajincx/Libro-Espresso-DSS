import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/cogs_service.dart';
import '../../core/session_manager.dart';
import '../../widgets/custom_page_header.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard_widgets/calendar_picker.dart';


class CogsScreen extends StatefulWidget {
  const CogsScreen({super.key});

  @override
  State<CogsScreen> createState() => _CogsScreenState();
}

class _CogsScreenState extends State<CogsScreen> with SingleTickerProviderStateMixin {
  final CogsService _service = CogsService();
  final SessionManager _session = SessionManager();
  late Stream<CogsData> _cogsStream;

  String _selectedBranch = 'All Branches';
  String _selectedMonth = 'January';
  String _selectedDay = 'All Days';

  final List<String> _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    if (!_session.isOwner) {
      _selectedBranch = _session.branchID ?? 'branch_1';
    }
    
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic);
    
    _refreshData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      int? m = _months.indexOf(_selectedMonth) + 1;
      if (m == 0) m = null;
      int? d = int.tryParse(_selectedDay);
      
      _cogsStream = _service.getCogsDataStream(
        filterBranchName: _session.isOwner ? (_selectedBranch == 'All Branches' ? null : _selectedBranch) : null,
        filterBranchId: !_session.isOwner ? _session.branchID : null,
        month: m,
        day: d,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      body: StreamBuilder<CogsData>(
        stream: _cogsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return _buildSkeleton();
          }
          if (snapshot.hasError) {
             return _buildError(snapshot.error.toString());
          }
          
          final data = snapshot.data;
          if (data == null || (data.totalRevenue == 0 && data.dailyCostHistory.isEmpty)) {
             return _buildEmpty();
          }

          _animationController.forward(from: 0.0);
          bool isSmall = MediaQuery.of(context).size.width <= 400;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(data.branchesList, isSmall),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: isSmall ? 16 : 24)),
                      SliverToBoxAdapter(child: _buildKPIs(data, isSmall)),
                      SliverToBoxAdapter(child: SizedBox(height: isSmall ? 12 : 16)),
                      SliverToBoxAdapter(child: _buildDailyCostTrend(data, isSmall)),
                      SliverToBoxAdapter(child: SizedBox(height: isSmall ? 20 : 32)),
                      SliverToBoxAdapter(child: _buildResponsiveGrid(data, isSmall)),
                      SliverToBoxAdapter(child: SizedBox(height: isSmall ? 20 : 32)),
                      SliverToBoxAdapter(child: _buildProductCostTable(data, isSmall)),
                      SliverToBoxAdapter(child: SizedBox(height: isSmall ? 20 : 32)),
                      SliverToBoxAdapter(child: _buildDailyHistoryTable(data, isSmall)),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<Map<String, String>> branches, bool isSmall) {
    return CustomPageHeader(
      title: 'Cost of Goods Sold',
      onBack: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (route) => false),
      bottomChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Monitor product costs, profitability, and operational efficiency.', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isSmall ? 11 : 12, color: Colors.white70, fontFamily: 'Poppins')),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilters(branches, isSmall),
        ],
      ),
    );
  }

  Widget _buildFilters(List<Map<String, String>> branches, bool isSmall) {
    return Row(
      children: [
        if (_session.isOwner) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBranch,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF8B1534),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                  items: branches.map((b) => DropdownMenuItem(value: b['id'], child: Text(b['name']!, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: isSmall ? 11 : 12, color: Colors.white)))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedBranch = v;
                        _refreshData();
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMonth,
                isExpanded: true,
                dropdownColor: const Color(0xFF8B1534),
                icon: const Icon(Icons.calendar_month, color: Colors.white, size: 18),
                items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: isSmall ? 11 : 12, color: Colors.white)))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedMonth = v;
                      _selectedDay = 'All Days';
                      _refreshData();
                    });
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
          child: IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => CalendarPicker(
                  selectedMonth: _selectedMonth,
                  selectedDay: _selectedDay,
                  onDaySelected: (v) {
                    setState(() {
                      _selectedDay = v;
                      _refreshData();
                    });
                  },
                  onClear: () {
                    setState(() {
                      _selectedDay = 'All Days';
                      _refreshData();
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKPIs(CogsData data, bool isSmall) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16.0 : 24.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildReportsKpiCard('Revenue', formatter.format(data.totalRevenue), Icons.attach_money, const LinearGradient(colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)])),
            const SizedBox(width: 12),
            _buildReportsKpiCard('COGS', formatter.format(data.totalCogs), Icons.inventory_2_rounded, const LinearGradient(colors: [Color(0xFF7B1A35), Color(0xFFAB2550)])),
            const SizedBox(width: 12),
            _buildReportsKpiCard('Profit', formatter.format(data.grossProfit), Icons.trending_up, const LinearGradient(colors: [Color(0xFF8B2040), Color(0xFFBB3060)])),
            const SizedBox(width: 12),
            _buildReportsKpiCard('Margin', '${data.grossProfitMargin.toStringAsFixed(1)}%', Icons.pie_chart, const LinearGradient(colors: [Color(0xFFD4A853), Color(0xFFE8C070)])),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsKpiCard(String title, String value, IconData icon, Gradient gradient) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDailyCostTrend(CogsData data, bool isSmall) {
    if (data.dailyCostTrend.isEmpty) return const SizedBox();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16.0 : 24.0),
      child: Container(
        height: isSmall ? 280 : 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        padding: EdgeInsets.all(isSmall ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: Color(0xFF6A1028), size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Daily Cost Trend', overflow: TextOverflow.ellipsis, style: TextStyle(color: const Color(0xFF1F2937), fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
              ],
            ),
            const SizedBox(height: 2),
            Text('Shows daily cost movement throughout the month.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'Poppins')),
            SizedBox(height: isSmall ? 16 : 24),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (_getMaxY(data.dailyCostTrend) / 4) == 0 ? 1 : (_getMaxY(data.dailyCostTrend) / 4),
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.2), strokeWidth: 1, dashArray: [5, 5]),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: (data.dailyCostTrend.length / (isSmall ? 3 : 5)).ceilToDouble().clamp(1, 100),
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < data.dailyCostLabels.length) {
                             return Padding(
                               padding: const EdgeInsets.only(top: 6.0),
                               child: Text(data.dailyCostLabels[index], style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontFamily: 'Poppins')),
                             );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isSmall ? 35 : 40,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox();
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('₱${(value/1000).toStringAsFixed(0)}k', style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontFamily: 'Poppins')),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: data.dailyCostTrend.length.toDouble() - 1,
                  minY: 0,
                  maxY: _getMaxY(data.dailyCostTrend) * 1.2,
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => const Color(0xFF6A1028),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '₱${NumberFormat('#,##0').format(spot.y)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 11),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.dailyCostTrend,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFF6A1028),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      shadow: Shadow(color: const Color(0xFF6A1028).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [const Color(0xFF6A1028).withValues(alpha: 0.15), const Color(0xFF6A1028).withValues(alpha: 0.0)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(CogsData data, bool isSmall) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16.0 : 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildCostByCategory(data, isSmall)),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildHighestLowest(data, isSmall)),
              ],
            );
          } else {
            return Column(
              children: [
                _buildCostByCategory(data, isSmall),
                SizedBox(height: isSmall ? 20 : 32),
                _buildHighestLowest(data, isSmall),
              ],
            );
          }
        }
      ),
    );
  }

  Widget _buildCostByCategory(CogsData data, bool isSmall) {
    if (data.costByCategory.isEmpty) return const SizedBox();

    final colors = [
      const Color(0xFF6A1028),
      const Color(0xFF4B0017),
      const Color(0xFF8A1C3C),
      const Color(0xFFF57C00),
      const Color(0xFF2E7D32),
    ];

    int colorIndex = 0;
    List<PieChartSectionData> sections = [];
    double totalSum = data.costByCategory.values.fold(0, (a, b) => a + b);

    List<Widget> legends = [];

    data.costByCategory.forEach((key, value) {
      if (value > 0) {
        Color c = colors[colorIndex % colors.length];
        double pct = (value / totalSum) * 100;
        sections.add(
          PieChartSectionData(
            color: c,
            value: value,
            title: '${pct.toStringAsFixed(0)}%',
            radius: isSmall ? 40 : 50,
            titleStyle: TextStyle(fontSize: isSmall ? 10 : 11, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins'),
            badgeWidget: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
              child: Icon(Icons.circle, color: c, size: 8),
            ),
            badgePositionPercentageOffset: 1.1,
          )
        );
        legends.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: isSmall ? 4.0 : 6.0),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 8),
                Expanded(child: Text(key, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Poppins', fontSize: isSmall ? 11 : 12, color: const Color(0xFF1F2937), fontWeight: FontWeight.w500))),
                Text('₱${NumberFormat('#,##0').format(value)}', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: isSmall ? 11 : 12)),
              ],
            ),
          )
        );
        colorIndex++;
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      padding: EdgeInsets.all(isSmall ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: Color(0xFF8A1C3C), size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Cost by Category', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: const Color(0xFF1F2937)))),
            ],
          ),
          const SizedBox(height: 2),
          Text('Proportional split of cost allocation.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'Poppins')),
          SizedBox(height: isSmall ? 20 : 32),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 350) {
                return Row(
                  children: [
                    SizedBox(
                      height: isSmall ? 140 : 160,
                      width: isSmall ? 140 : 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: isSmall ? 35 : 45,
                          sections: sections,
                        ),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: legends)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    SizedBox(
                      height: 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections: sections,
                        ),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(children: legends),
                  ],
                );
              }
            }
          )
        ],
      ),
    );
  }

  Widget _buildHighestLowest(CogsData data, bool isSmall) {
    if (data.highestCostProduct == null || data.lowestCostProduct == null) return const SizedBox();
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildHighlightCard(
              title: 'Highest Cost',
              prod: data.highestCostProduct!,
              gradient: const LinearGradient(colors: [Color(0xFF6A1028), Color(0xFF4B0017)]),
              icon: Icons.keyboard_double_arrow_up,
              textColor: Colors.white,
              isSmall: isSmall,
            ),
          ),
          SizedBox(width: isSmall ? 12 : 16),
          Expanded(
            child: _buildHighlightCard(
              title: 'Lowest Cost',
              prod: data.lowestCostProduct!,
              gradient: const LinearGradient(colors: [Color(0xFFFDF8F5), Color(0xFFFFF3E0)]),
              icon: Icons.keyboard_double_arrow_down,
              textColor: const Color(0xFF1F2937),
              borderColor: const Color(0xFFD4A853).withValues(alpha: 0.4),
              isSmall: isSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard({required String title, required Map<String, dynamic> prod, required Gradient gradient, required IconData icon, required Color textColor, Color? borderColor, required bool isSmall}) {
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
    bool isDark = textColor == Colors.white;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: isDark ? [BoxShadow(color: const Color(0xFF6A1028).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      padding: EdgeInsets.all(isSmall ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD4A853).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: isDark ? Colors.white : const Color(0xFFD4A853), size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
            ],
          ),
          const SizedBox(height: 16),
          Text(prod['productName'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isSmall ? 18 : 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: textColor)),
          const SizedBox(height: 16),
          _buildHighlightRow('COGS', formatter.format(prod['cost']), textColor, isDark, isSmall),
          const SizedBox(height: 6),
          _buildHighlightRow('Revenue', formatter.format(prod['revenue']), textColor, isDark, isSmall),
          const SizedBox(height: 6),
          _buildHighlightRow('Profit', formatter.format(prod['profit']), textColor, isDark, isSmall, isProfit: true),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(String label, String val, Color baseColor, bool isDark, bool isSmall, {bool isProfit = false}) {
    Color valColor = baseColor;
    if (isProfit && !isDark) {
      valColor = const Color(0xFF2E7D32);
    } else if (isProfit && isDark) {
      valColor = Colors.greenAccent;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.grey.shade600, fontFamily: 'Poppins')),
        Text(val, style: TextStyle(fontSize: isSmall ? 11 : 12, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: valColor)),
      ],
    );
  }

  Widget _buildProductCostTable(CogsData data, bool isSmall) {
    if (data.productCostBreakdown.isEmpty) return const SizedBox();
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16.0 : 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart_rounded, color: Color(0xFF8A1C3C), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Product Breakdown', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: const Color(0xFF1F2937)))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Detailed margin analysis per product.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'Poppins')),
                ],
              ),
            ),
            Container(height: 1, color: Colors.grey.shade100),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                dataRowMinHeight: isSmall ? 60 : 70,
                dataRowMaxHeight: isSmall ? 60 : 70,
                horizontalMargin: isSmall ? 16 : 24,
                columnSpacing: isSmall ? 20 : 32,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                  DataColumn(label: Text('Units', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                  DataColumn(label: Text('Revenue', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                  DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                  DataColumn(label: Text('Profit', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                ],
                rows: data.productCostBreakdown.map((prod) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmall ? 6 : 8),
                              decoration: BoxDecoration(color: const Color(0xFF6A1028).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.local_cafe, color: const Color(0xFF6A1028), size: isSmall ? 14 : 16),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(width: 100, child: Text(prod['productName'], overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: const Color(0xFF1F2937), fontSize: isSmall ? 12 : 13))),
                          ],
                        )
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF6A1028).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                          child: Text('${prod['unitsSold']}', style: TextStyle(fontFamily: 'Poppins', color: const Color(0xFF6A1028), fontWeight: FontWeight.bold, fontSize: 11)),
                        )
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text(formatter.format(prod['revenue']), style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: isSmall ? 11 : 12)),
                        )
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF6A1028).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text(formatter.format(prod['cost']), style: TextStyle(fontFamily: 'Poppins', color: const Color(0xFF6A1028), fontWeight: FontWeight.bold, fontSize: isSmall ? 11 : 12)),
                        )
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: prod['profit'] >= 0 ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(formatter.format(prod['profit']), style: TextStyle(fontFamily: 'Poppins', color: prod['profit'] >= 0 ? const Color(0xFF2E7D32) : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: isSmall ? 11 : 12)),
                        )
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyHistoryTable(CogsData data, bool isSmall) {
    if (data.dailyCostHistory.isEmpty) return const SizedBox();
    final formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16.0 : 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF4B0017), size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Daily Cost History', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: const Color(0xFF1F2937)))),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Comprehensive record of operational costs.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontFamily: 'Poppins')),
                ],
              ),
            ),
            Container(height: 1, color: Colors.grey.shade100),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                dataRowMinHeight: isSmall ? 60 : 70,
                dataRowMaxHeight: isSmall ? 60 : 70,
                horizontalMargin: isSmall ? 16 : 24,
                columnSpacing: isSmall ? 20 : 32,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                  DataColumn(label: Text('Revenue', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                  DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                  DataColumn(label: Text('Profit', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Colors.grey, fontSize: 11))),
                ],
                rows: data.dailyCostHistory.map((dayData) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmall ? 6 : 8),
                              decoration: BoxDecoration(color: const Color(0xFF6A1028).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.today, color: const Color(0xFF6A1028), size: isSmall ? 14 : 16),
                            ),
                            const SizedBox(width: 12),
                            Text(dayData['shortDate'], style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: const Color(0xFF1F2937), fontSize: isSmall ? 12 : 13)),
                          ],
                        )
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Text(formatter.format(dayData['revenue']), style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: isSmall ? 11 : 12)),
                        )
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF6A1028).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text(formatter.format(dayData['cost']), style: TextStyle(fontFamily: 'Poppins', color: const Color(0xFF6A1028), fontWeight: FontWeight.bold, fontSize: isSmall ? 11 : 12)),
                        )
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: dayData['profit'] >= 0 ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(formatter.format(dayData['profit']), style: TextStyle(fontFamily: 'Poppins', color: dayData['profit'] >= 0 ? const Color(0xFF2E7D32) : Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: isSmall ? 11 : 12)),
                        )
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 1000;
    double max = 0;
    for (var spot in spots) {
      if (spot.y > max) max = spot.y;
    }
    return max == 0 ? 1000 : max;
  }

  Widget _buildSkeleton() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6A1028), strokeWidth: 3),
          SizedBox(height: 16),
          Text('Loading COGS data...', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load COGS Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(color: Color(0xFF6B7280), fontFamily: 'Poppins', fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1028),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text('Retry', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1028).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.analytics_outlined, size: 60, color: const Color(0xFF6A1028).withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 24),
            const Text('No COGS data available', style: TextStyle(fontSize: 20, color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
            const SizedBox(height: 8),
            const Text('Import sales to begin generating cost analytics.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontFamily: 'Poppins'), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedMonth = _months[DateTime.now().month - 1];
                  _selectedDay = 'All Days';
                  _refreshData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1028),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.filter_alt_off, color: Colors.white, size: 18),
              label: const Text('Reset Filters', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            )
          ],
        ),
      ),
    );
  }
}

class _HoverKpiCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<FlSpot> sparkline;
  final bool isSmall;

  const _HoverKpiCard({required this.title, required this.value, required this.icon, required this.color, required this.sparkline, required this.isSmall});

  @override
  State<_HoverKpiCard> createState() => _HoverKpiCardState();
}

class _HoverKpiCardState extends State<_HoverKpiCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: widget.color.withValues(alpha: _isHovered ? 0.12 : 0.03), blurRadius: _isHovered ? 24 : 16, offset: Offset(0, _isHovered ? 12 : 8)),
          ],
        ),
        padding: EdgeInsets.all(widget.isSmall ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(widget.isSmall ? 8 : 10),
                  decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(widget.icon, color: widget.color, size: widget.isSmall ? 18 : 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Color(0xFF2E7D32), size: 10),
                      SizedBox(width: 2),
                      Text('+8.5%', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(widget.title, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 5,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(widget.value, style: TextStyle(fontSize: widget.isSmall ? 22 : 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins', color: const Color(0xFF1F2937))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 24,
                    child: widget.sparkline.length > 1 ? LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: widget.sparkline.take(7).toList(),
                            isCurved: true,
                            curveSmoothness: 0.4,
                            color: widget.color,
                            barWidth: 1.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [widget.color.withValues(alpha: 0.2), widget.color.withValues(alpha: 0.0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ) : const SizedBox(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
