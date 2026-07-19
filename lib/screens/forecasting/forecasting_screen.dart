import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/session_manager.dart';
import '../../widgets/custom_page_header.dart';

class ForecastingScreen extends StatefulWidget {
  const ForecastingScreen({super.key});

  @override
  State<ForecastingScreen> createState() => _ForecastingScreenState();
}

class _ForecastingScreenState extends State<ForecastingScreen> {
  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _maroon = Color(0xFF6A1028);
  static const _burgundy = Color(0xFF9B1C3F);
  static const _gold = Color(0xFFD4A853);
  static const _cream = Color(0xFFFDF8F5);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);
  static const _cardShadow = [
    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
  ];
  final SessionManager _session = SessionManager();
  bool _isLoading = true;
  String _selectedBranch = 'All Branches';
  int _daysToForecast = 7;
  Map<String, dynamic>? _currentForecast;
  List<String> _branches = ['All Branches'];

  @override
  void initState() {
    super.initState();
    if (!_session.isOwner) {
      _selectedBranch = _session.branchID ?? 'All Branches';
    }
    _initData();
  }

  Future<void> _initData() async {
    if (_session.isOwner) {
      final bQuery = await FirebaseFirestore.instance.collection('branches').get();
      setState(() {
        _branches = ['All Branches', ...bQuery.docs.map((d) => d.id).toList()];
      });
    }
    await _generateAndLoadForecast();
  }

  Future<void> _generateAndLoadForecast() async {
    setState(() => _isLoading = true);
    try {
      final db = FirebaseFirestore.instance;
      
      Query salesQuery = db.collection('sales');
          
      if (_selectedBranch != 'All Branches') {
          String expectedBranchId = '';
          switch (_selectedBranch) {
            case 'Main Branch': expectedBranchId = 'branch_1'; break;
            case 'Lipa Branch': expectedBranchId = 'branch_2'; break;
            case 'Tagaytay Branch': expectedBranchId = 'branch_3'; break;
            case 'Evo Branch': expectedBranchId = 'branch_4'; break;
            case 'Vermosa Branch': expectedBranchId = 'branch_5'; break;
            default: expectedBranchId = _selectedBranch; break;
          }
          salesQuery = salesQuery.where('branchID', isEqualTo: expectedBranchId);
      }
      
      final salesSnapshot = await salesQuery.get();
      
      print('Total sales loaded: ${salesSnapshot.docs.length}');
      print('Sales after branch filter: ${salesSnapshot.docs.length}');
      
      if (salesSnapshot.docs.length < 7) {
        print('Reason if forecast failed: Less than 7 sales records found.');
        setState(() {
          _currentForecast = null;
          _isLoading = false;
        });
        return;
      }

      double totalRevenue = 0;
      int totalOrders = salesSnapshot.docs.length;
      double totalCost = 0;
      Map<String, int> productCounts = {};
      Map<String, double> productRevenues = {};
      Map<String, double> categoryRevenues = {};
      Set<String> uniqueDates = {};
      
      int totalItemsLoaded = 0;
      for (var doc in salesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        totalCost += (data['cost'] as num?)?.toDouble() ?? 0.0;
        
        if (data['timestamp'] != null) {
          DateTime dt;
          var dateVal = data['timestamp'];
          if (dateVal is Timestamp) dt = dateVal.toDate();
          else if (dateVal is DateTime) dt = dateVal;
          else dt = DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
          uniqueDates.add(DateFormat('yyyy-MM-dd').format(dt));
        }

        final items = data['items'] as List<dynamic>? ?? [];
        totalItemsLoaded += items.length;
        for (var item in items) {
          if (item is! Map) {
            developer.log('[Forecast] Skipping non-map item in sale doc ${doc.id}', name: 'ForecastingScreen');
            continue;
          }
          final pName = (item['productName'] as String?) ?? 'Unknown';
          final pQty = (item['quantity'] as num?)?.toInt() ?? 1;
          
          double itemTotal = 0.0;
          if (item['totalPrice'] != null) {
            itemTotal = (item['totalPrice'] as num?)?.toDouble() ?? 0.0;
          } else if (item['price'] != null) {
            itemTotal = ((item['price'] as num?)?.toDouble() ?? 0.0) * pQty;
          }
          
          String pCategory = (item['category'] as String?) ?? 'Others';
          if (pCategory == 'Desserts') pCategory = 'Dessert';
          if (pCategory == 'Pastries') pCategory = 'Pastry';
          if (pCategory == 'Meal') pCategory = 'Meals';
          
          productCounts[pName] = (productCounts[pName] ?? 0) + pQty;
          productRevenues[pName] = (productRevenues[pName] ?? 0.0) + itemTotal;
          categoryRevenues[pCategory] = (categoryRevenues[pCategory] ?? 0.0) + itemTotal;
        }
      }
      
      print('Total sale items loaded: $totalItemsLoaded');
      print('Categories found: ${categoryRevenues.keys.join(", ")}');
      print('Coffee Revenue: \$${(categoryRevenues['Coffee'] ?? 0.0).toStringAsFixed(2)}');
      print('Pastry Revenue: \$${(categoryRevenues['Pastry'] ?? 0.0).toStringAsFixed(2)}');
      print('Meals Revenue: \$${(categoryRevenues['Meals'] ?? 0.0).toStringAsFixed(2)}');
      print('Dessert Revenue: \$${(categoryRevenues['Dessert'] ?? 0.0).toStringAsFixed(2)}');
      print('Others Revenue: \$${(categoryRevenues['Others'] ?? 0.0).toStringAsFixed(2)}');
      print('Forecast by Category generated successfully.');
      
      print('Unique sales dates: ${uniqueDates.length}');
      
      int daysDivisor = uniqueDates.length > 0 ? uniqueDates.length : 1;
      
      double dailyRev = totalRevenue / daysDivisor;
      double dailyOrders = totalOrders / daysDivisor;
      double dailyProfit = (totalRevenue - totalCost) / daysDivisor;
      
      double forecastRevenue = dailyRev * _daysToForecast;
      double forecastOrders = dailyOrders * _daysToForecast;
      double forecastGrossProfit = dailyProfit * _daysToForecast;
      
      var sortedProducts = productCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      List<Map<String, dynamic>> topProducts = [];
      for (int i = 0; i < sortedProducts.length && i < 5; i++) {
        double dailyUnits = sortedProducts[i].value / daysDivisor;
        int forecastedUnits = (dailyUnits * _daysToForecast).ceil();
        double pRev = productRevenues[sortedProducts[i].key] ?? 0.0;
        double forecastedRev = (pRev / daysDivisor) * _daysToForecast;
        topProducts.add({
          'productName': sortedProducts[i].key,
          'predictedUnits': forecastedUnits,
          'forecastedRevenue': forecastedRev,
        });
      }

      Map<String, double> categoryForecast = {};
      categoryRevenues.forEach((key, val) {
        categoryForecast[key] = (val / daysDivisor) * _daysToForecast;
      });
      
      double confidence = 70.0 + (uniqueDates.length > 20 ? 20.0 : (uniqueDates.length > 10 ? 10.0 : 0.0));
      if (confidence > 95.0) confidence = 95.0;

      Map<String, double> ingredientDemand = {};
      final prodsSnapshot = await db.collection('products').get();
      Map<String, List<dynamic>> productRecipes = {};
      for (var p in prodsSnapshot.docs) {
        final pData = p.data() as Map<String, dynamic>;
        final prodName = (pData['productName'] as String?) ?? '';
        if (prodName.isEmpty) {
          developer.log('[Forecast] Product doc ${p.id} has null/empty productName', name: 'ForecastingScreen');
          continue;
        }
        productRecipes[prodName] = pData['recipe'] as List<dynamic>? ?? [];
      }
      
      for (var entry in sortedProducts) {
        double forecastedUnits = (entry.value / daysDivisor) * _daysToForecast;
        var recipe = productRecipes[entry.key] ?? [];
        for (var ing in recipe) {
          if (ing is! Map) continue;
          final ingName = (ing['ingredientName'] as String?) ?? '';
          final qty = (ing['quantity'] as num?)?.toDouble() ?? 0.0;
          if (ingName.isNotEmpty) {
            ingredientDemand[ingName] = (ingredientDemand[ingName] ?? 0.0) + (qty * forecastedUnits);
          } else {
            developer.log('[Forecast] Recipe ingredient missing name in product ${entry.key}', name: 'ForecastingScreen');
          }
        }
      }
      
      final invSnapshot = await db.collection('inventory').get();
      Map<String, double> currentStocks = {};
      for (var inv in invSnapshot.docs) {
        final invData = inv.data() as Map<String, dynamic>;
        final invIngName = (invData['ingredientName'] as String?) ?? '';
        if (invIngName.isEmpty) {
          developer.log('[Forecast] Inventory doc ${inv.id} has null/empty ingredientName', name: 'ForecastingScreen');
          continue;
        }
        currentStocks[invIngName] = (invData['stock'] as num?)?.toDouble() ?? 0.0;
      }
      
      List<Map<String, dynamic>> finalIngForecast = [];
      ingredientDemand.forEach((name, demand) {
        double stock = currentStocks[name] ?? 0.0;
        String status = "Sufficient";
        if (stock < demand) {
          status = "Critical";
        } else if (stock < demand * 1.5) {
          status = "Restock Soon";
        }
        finalIngForecast.add({
          'ingredientName': name,
          'estimatedConsumption': demand,
          'currentStock': stock,
          'status': status,
        });
      });

      String forecastId = 'fcst_${DateTime.now().millisecondsSinceEpoch}';
      final forecastPayload = {
        'forecastID': forecastId,
        'branchID': _selectedBranch,
        'forecastDays': _daysToForecast,
        'forecastDate': FieldValue.serverTimestamp(),
        'forecastRevenue': forecastRevenue,
        'forecastOrders': forecastOrders.ceil(),
        'forecastGrossProfit': forecastGrossProfit,
        'confidence': confidence,
        'topProducts': topProducts,
        'categoryForecast': categoryForecast,
        'ingredientForecast': finalIngForecast,
        'generatedAt': FieldValue.serverTimestamp(),
      };
      
      await db.collection('forecasts').doc(forecastId).set(forecastPayload);
      
      setState(() {
        _currentForecast = forecastPayload;
        _isLoading = false;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating forecast: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _maroon))
                : (_currentForecast == null
                    ? _buildEmptyState()
                    : _buildDashboard()),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return CustomPageHeader(
      title: 'Forecasting',
      onBack: () => Navigator.pop(context),
      bottomChild: Text(
        'Predict future sales and inventory demand.',
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _maroon.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.insert_chart_outlined,
                size: 64, color: _maroon.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            'Not enough sales data',
            style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Please record at least 7 sales to generate\na forecast.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final currencyFmt = NumberFormat.currency(
        symbol: '₱', decimalDigits: 2, customPattern: '₱#,##0.00');
    final numFmt = NumberFormat('#,##0');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDropdown(
                    'Date Range',
                    ['Next 7 Days', 'Next 14 Days', 'Next 30 Days'],
                    'Next $_daysToForecast Days', (v) {
                  int d = 7;
                  if (v == 'Next 14 Days') d = 14;
                  if (v == 'Next 30 Days') d = 30;
                  if (d != _daysToForecast) {
                    setState(() => _daysToForecast = d);
                    _generateAndLoadForecast();
                  }
                }),
                if (_session.isOwner) ...[
                  const SizedBox(width: 10),
                  _buildDropdown('Branch', _branches, _selectedBranch, (v) {
                    if (v != null && v != _selectedBranch) {
                      setState(() => _selectedBranch = v);
                      _generateAndLoadForecast();
                    }
                  }),
                ]
              ],
            ),
          ),
          const SizedBox(height: 24),

          // KPI cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildKpiCard(
                  'Forecasted Revenue',
                  currencyFmt.format((_currentForecast!['forecastRevenue'] as num?)?.toDouble() ?? 0.0),
                  Icons.trending_up_rounded,
                  const LinearGradient(colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)]),
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  'Forecasted Orders',
                  numFmt.format((_currentForecast!['forecastOrders'] as num?)?.toInt() ?? 0),
                  Icons.receipt_long_rounded,
                  const LinearGradient(colors: [Color(0xFF7B1A35), Color(0xFFAB2550)]),
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  'Gross Profit',
                  currencyFmt.format((_currentForecast!['forecastGrossProfit'] as num?)?.toDouble() ?? 0.0),
                  Icons.monetization_on_rounded,
                  const LinearGradient(colors: [Color(0xFF8B2040), Color(0xFFBB3060)]),
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  'Confidence',
                  '${((_currentForecast!['confidence'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)}%',
                  Icons.verified_rounded,
                  const LinearGradient(colors: [Color(0xFFD4A853), Color(0xFFE8C070)]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Chart
          _buildSectionHeader('Forecast Revenue Chart'),
          const SizedBox(height: 12),
          Container(
            height: 250,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: _cardShadow),
            child: Column(
              children: [
                Expanded(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 1),
                            FlSpot(1, 1.5),
                            FlSpot(2, 1.4),
                            FlSpot(3, 2)
                          ],
                          isCurved: true,
                          color: _maroon,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _maroon.withValues(alpha: 0.06),
                          ),
                        ),
                        LineChartBarData(
                          spots: const [
                            FlSpot(3, 2),
                            FlSpot(4, 2.3),
                            FlSpot(5, 2.5),
                            FlSpot(6, 2.9)
                          ],
                          isCurved: true,
                          color: _gold,
                          barWidth: 3,
                          dashArray: [5, 5],
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(_maroon),
                    const SizedBox(width: 6),
                    Text('Historical',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: _textSecondary)),
                    const SizedBox(width: 20),
                    _legendDot(_gold),
                    const SizedBox(width: 6),
                    Text('Forecast',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: _textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Categories
          _buildSectionHeader('Forecast by Category'),
          const SizedBox(height: 12),
          ...((_currentForecast!['categoryForecast'] as Map<String, dynamic>?) ?? <String, dynamic>{})
              .entries
              .map((e) => _buildCategoryCard(e.key, (e.value as num?)?.toDouble() ?? 0.0, currencyFmt)),

          const SizedBox(height: 28),

          // Top Products
          _buildSectionHeader('Predicted Top Selling Products'),
          const SizedBox(height: 12),
          ...((_currentForecast!['topProducts'] as List<dynamic>?) ?? [])
              .asMap()
              .entries
              .map((entry) =>
                  _buildTopProductCard(entry.key, entry.value, currencyFmt, numFmt)),

          const SizedBox(height: 28),

          // Inventory Demand
          _buildSectionHeader('Inventory Demand Forecast'),
          const SizedBox(height: 12),
          ...((_currentForecast!['ingredientForecast'] as List<dynamic>?) ?? [])
              .map((e) => _buildIngredientCard(e, numFmt)),

          const SizedBox(height: 28),

          // Insights
          _buildSectionHeader('Forecast Insights'),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            try {
              final fRevenue = (_currentForecast!['forecastRevenue'] as num?)?.toDouble() ?? 0.0;
              final fOrders = (_currentForecast!['forecastOrders'] as num?)?.toInt() ?? 0;
              final conf = (_currentForecast!['confidence'] as num?)?.toDouble() ?? 0.0;
              final tProducts = _currentForecast!['topProducts'] as List? ?? [];
              final ingForecast = _currentForecast!['ingredientForecast'] as List? ?? [];

              // BUG FIX: field is 'productName', not 'name'
              String topProduct = 'N/A';
              if (tProducts.isNotEmpty) {
                final firstProduct = tProducts.first;
                topProduct = (firstProduct is Map
                    ? (firstProduct['productName'] as String?) ?? (firstProduct['name'] as String?) ?? 'N/A'
                    : 'N/A');
                developer.log('[Forecast Insights] topProduct resolved to: $topProduct', name: 'ForecastingScreen');
              } else {
                developer.log('[Forecast Insights] topProducts list is empty', name: 'ForecastingScreen');
              }

              int criticalCount = 0;
              int restockCount = 0;
              for (final e in ingForecast) {
                if (e is Map) {
                  final status = (e['status'] as String?) ?? '';
                  if (status == 'Critical') criticalCount++;
                  if (status == 'Restock Soon') restockCount++;
                } else {
                  developer.log('[Forecast Insights] ingredientForecast entry is not a Map: $e', name: 'ForecastingScreen');
                }
              }
              
              return Column(
                children: [
                  _buildInsightCard(
                    Icons.attach_money_rounded,
                    'Sales Forecast',
                    'Expected sales for the next $_daysToForecast days is ${currencyFmt.format(fRevenue)}.',
                    _maroon,
                  ),
                  const SizedBox(height: 10),
                  _buildInsightCard(
                    Icons.show_chart_rounded,
                    'Revenue Trend',
                    'Revenue is expected to remain stable with a ${conf.toInt()}% confidence based on historical data.',
                    const Color(0xFF059669),
                  ),
                  const SizedBox(height: 10),
                  _buildInsightCard(
                    Icons.shopping_cart_rounded,
                    'Demand Forecast',
                    'Predicted demand is approximately ${numFmt.format(fOrders)} total orders.',
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 10),
                  _buildInsightCard(
                    Icons.star_rounded,
                    'Top Predicted Product',
                    'The product expected to have the highest sales is $topProduct.',
                    _gold,
                  ),
                  const SizedBox(height: 10),
                  _buildInsightCard(
                    Icons.inventory_rounded,
                    'Inventory Demand',
                    criticalCount > 0 
                        ? 'You have $criticalCount ingredients critically low based on predicted demand.'
                        : 'Inventory levels are sufficient to meet upcoming demand.',
                    criticalCount > 0 ? Colors.red.shade700 : const Color(0xFF059669),
                  ),
                  const SizedBox(height: 10),
                  if (criticalCount > 0 || restockCount > 0)
                    _buildInsightCard(
                      Icons.warning_amber_rounded,
                      'Forecast Warning',
                      'High risk of stockouts! Check "Critical" or "Restock Soon" items.',
                      Colors.orange.shade700,
                    ),
                  if (criticalCount > 0 || restockCount > 0)
                    const SizedBox(height: 10),
                  _buildInsightCard(
                    Icons.lightbulb_outline_rounded,
                    'Business Recommendation',
                    criticalCount > 0
                        ? 'Restock critical ingredients immediately to prevent lost sales.'
                        : 'Prepare promotions to boost sales, as your inventory is well-stocked for the forecasted period.',
                    const Color(0xFF7C3AED),
                  ),
                ],
              );
            } catch (e, stackTrace) {
              developer.log(
                '[Forecast Insights] Error building insights: $e',
                name: 'ForecastingScreen',
                error: e,
                stackTrace: stackTrace,
              );
              return _buildForecastInsightsEmptyState();
            }
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Component helpers ────────────────────────────────────────────────────────

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
              color: _maroon, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String current,
      void Function(String?) onChanged) {
    String _formatBranchName(String id) {
      if (label != 'Branch') return id;
      switch (id) {
        case 'branch_1': return 'Main Branch';
        case 'branch_2': return 'Lipa Branch';
        case 'branch_3': return 'Tagaytay Branch';
        case 'branch_4': return 'Evo Branch';
        case 'branch_5': return 'Vermosa Branch';
        default: return id;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _maroon.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500)),
          DropdownButton<String>(
            value: current,
            items: items
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(_formatBranchName(e),
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _maroon))))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: _maroon, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
      String title, String value, IconData icon, Gradient gradient) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
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
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
      String category, dynamic value, NumberFormat fmt) {
    final Map<String, IconData> categoryIcons = {
      'Coffee': Icons.local_cafe_rounded,
      'Pastry': Icons.bakery_dining_rounded,
      'Pastries': Icons.bakery_dining_rounded,
      'Meals': Icons.restaurant_rounded,
      'Dessert': Icons.icecream_rounded,
      'Desserts': Icons.icecream_rounded,
      'Others': Icons.category_rounded,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
        border: Border(
            left: BorderSide(
                color: _maroon.withValues(alpha: 0.5), width: 4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _maroon.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
                categoryIcons[category] ?? Icons.category_rounded,
                color: _maroon,
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(category,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textPrimary)),
          ),
          Text(fmt.format(value),
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _maroon)),
        ],
      ),
    );
  }

  Widget _buildTopProductCard(
      int index, dynamic e, NumberFormat currencyFmt, NumberFormat numFmt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_maroon, _burgundy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${index + 1}',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text((e is Map ? (e['productName'] as String?) : null) ?? 'Unknown Product',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _textPrimary)),
                const SizedBox(height: 2),
                Text(
                    '${numFmt.format((e is Map ? (e['predictedUnits'] as num?) : null) ?? 0)} Units predicted',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _textSecondary)),
              ],
            ),
          ),
          Text(currencyFmt.format((e is Map ? (e['forecastedRevenue'] as num?) : null)?.toDouble() ?? 0.0),
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _maroon)),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(dynamic e, NumberFormat numFmt) {
    if (e is! Map) {
      developer.log('[Forecast] ingredientForecast entry is not a Map: $e', name: 'ForecastingScreen');
      return const SizedBox.shrink();
    }
    String status = (e['status'] as String?) ?? 'Sufficient';
    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Critical':
        statusColor = const Color(0xFFDC2626);
        statusIcon = Icons.error_rounded;
        break;
      case 'Restock Soon':
        statusColor = const Color(0xFFD97706);
        statusIcon = Icons.warning_amber_rounded;
        break;
      default:
        statusColor = const Color(0xFF059669);
        statusIcon = Icons.check_circle_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text((e['ingredientName'] as String?) ?? 'Unknown Ingredient',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _textPrimary)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(status,
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _buildMicroKpi(
                      'Need', numFmt.format((e['estimatedConsumption'] as num?)?.toDouble() ?? 0.0))),
              Expanded(
                  child: _buildMicroKpi(
                      'Stock', numFmt.format((e['currentStock'] as num?)?.toDouble() ?? 0.0))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroKpi(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _textPrimary)),
      ],
    );
  }

  Widget _buildInsightCard(
      IconData icon, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _textPrimary)),
                const SizedBox(height: 4),
                Text(desc,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: _textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Friendly empty state shown when forecast insights fail to render.
  Widget _buildForecastInsightsEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _cardShadow,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.insights_rounded,
                size: 48, color: _maroon.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text(
              'No forecast insights available yet.',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Insights will appear once enough data\nhas been processed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
