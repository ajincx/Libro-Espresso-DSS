import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../core/session_manager.dart';
import '../dashboard_widgets/dashboard_header.dart';
import '../dashboard_widgets/kpi_card.dart';
import '../dashboard_widgets/sales_trend_card.dart';

import '../dashboard_widgets/branch_performance_chart.dart';
import '../dashboard_widgets/todays_goal_card.dart';
import '../dashboard_widgets/quick_access.dart';
import '../dashboard_widgets/top_products.dart';
import '../dashboard_widgets/ai_insights_card.dart';
import '../dashboard_widgets/bottom_nav.dart';
import '../dashboard_widgets/low_stock_alerts.dart';
import '../../widgets/section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();
  final SessionManager _session = SessionManager();
  late Stream<DashboardData> _dashboardStream;

  String _selectedBranch = 'All Branches';
  String _selectedMonth = 'January';
  String _selectedDay = 'All Days';

  @override
  void initState() {
    super.initState();
    if (!_session.isOwner) {
      _selectedBranch = _session.branchID ?? 'branch_1';
    }
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      int? m = ['January', 'February', 'March', 'April', 'May', 'June', 'July'].indexOf(_selectedMonth) + 1;
      int? d = int.tryParse(_selectedDay);
      
      _dashboardStream = _service.getDashboardDataStream(
        filterBranchName: _session.isOwner ? (_selectedBranch == 'All Branches' ? null : _selectedBranch) : null,
        filterBranchId: !_session.isOwner ? _session.branchID : null,
        month: m,
        day: d,
      );
    });
  }

  String _formatBranchName(String id) {
    switch (id) {
      case 'branch_1': return 'Main Branch';
      case 'branch_2': return 'Lipa Branch';
      case 'branch_3': return 'Tagaytay Branch';
      case 'branch_4': return 'Evo Branch';
      case 'branch_5': return 'Vermosa Branch';
      default: return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      body: StreamBuilder<DashboardData>(
        stream: _dashboardStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeleton();
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          final data = snapshot.data;
          if (data == null) return _buildEmpty();

          return Column(
            children: [
              const DashboardHeader(),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Today\'s Revenue'))),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: KpiCard(
                  revenue: data.todaysRevenue, revenueChangePercentage: data.revenueChangePercentage, sparklineSpots: data.sparklineSpots,
                  orders: data.todaysOrders,
                  profit: data.grossProfit,
                  activeProducts: data.activeProducts,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Sales Trend'))),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: SalesTrendCard(
                  dataPoints: data.salesTrend,
                  salesTrendChangePercentage: data.salesTrendChangePercentage,
                  isOwner: _session.isOwner,
                  selectedBranch: _selectedBranch,
                  selectedMonth: _selectedMonth,
                  selectedDay: _selectedDay,
                  branchesList: data.branchesList.map((b) => {
                    'id': b['id']!,
                    'name': b['id'] == 'All Branches' ? 'All Branches' : _formatBranchName(b['id']!)
                  }).toList(),
                  onBranchChanged: (v) {
                    setState(() {
                      _selectedBranch = v;
                      _refreshData();
                    });
                  },
                  onMonthChanged: (v) {
                    setState(() {
                      _selectedMonth = v;
                      _selectedDay = 'All Days'; // reset day when month changes
                      _refreshData();
                    });
                  },
                  onDaySelected: (v) {
                    setState(() {
                      _selectedDay = v;
                      _refreshData();
                    });
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_session.isOwner) ...[
                const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Branch Performance'))),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(child: BranchPerformanceChart(branchPerformance: data.branchPerformance)),
              ] else ...[
                const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(title: "Today's Goal"))),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const SliverToBoxAdapter(child: TodaysGoalCard()),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Quick Access'))),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: QuickAccess()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: LowStockAlertsCard()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'Top Selling Products'))),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: TopProducts(products: data.topProducts)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverPadding(padding: EdgeInsets.symmetric(horizontal: 20), sliver: SliverToBoxAdapter(child: SectionHeader(title: 'AI Insights'))),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: AiInsightsCard(insights: data.aiInsights)),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      extendBody: true,
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
                Text('Aggregating Live Data...', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
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
          const Text('Failed to load dashboard data', style: TextStyle(fontFamily: 'Poppins')),
          Text(err, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey)),
          ElevatedButton(onPressed: _refreshData, child: const Text('Retry', style: TextStyle(fontFamily: 'Poppins')))
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Text('No data found for selected filters', style: TextStyle(fontFamily: 'Poppins')));
  }
}
