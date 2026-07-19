import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import '../../core/session_manager.dart';
import '../dashboard_widgets/bottom_nav.dart';
import '../dashboard/dashboard_screen.dart';
import '../../widgets/custom_page_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // ── Design tokens ────────────────────────────────────────────────────────
  static const _maroon = Color(0xFF6A1028);
  static const _burgundy = Color(0xFF9B1C3F);

  static const _cream = Color(0xFFFDF8F5);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);
  static const _cardShadow = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
  final SessionManager _session = SessionManager();
  bool _isLoading = true;
  String _selectedBranch = 'All Branches';
  String _selectedDateRange = 'This Month';
  DateTime? _customStart;
  DateTime? _customEnd;
  List<String> _branches = ['All Branches'];

  // Data
  double _totalRevenue = 0.0;
  int _totalOrders = 0;
  double _grossProfit = 0.0;
  double _totalCogs = 0.0;
  
  Map<String, double> _categoryRevenue = {};
  Map<String, int> _categoryUnits = {};
  Map<String, double> _branchRevenue = {};
  List<Map<String, dynamic>> _topProducts = [];
  
  int _totalInventoryItems = 0;
  double _totalCurrentStock = 0.0;
  double _totalInventoryValue = 0.0;
  int _lowStockItems = 0;
  
  int _totalShrinkageRecords = 0;
  double _totalShrinkageQuantity = 0.0;
  double _totalEstimatedLoss = 0.0;
  int _shrinkageSpoilage = 0;
  int _shrinkageWastage = 0;
  int _shrinkagePilferage = 0;
  int _shrinkageCountError = 0;
  int _shrinkagePending = 0;
  int _shrinkageChecked = 0;
  
  double _forecastRev = 0.0;
  int _forecastOrd = 0;
  double _forecastProfit = 0.0;
  
  Map<String, double> _monthlyRev = {};
  
  final currencyFmt = NumberFormat.currency(symbol: '₱', decimalDigits: 2, customPattern: '₱#,##0.00');
  final numFmt = NumberFormat('#,##0');

  String formatCurrency(double value, {bool forPdf = false}) {
    final numFormat = NumberFormat('#,##0.00', 'en_US');
    final formatted = numFormat.format(value);
    return forPdf ? 'PHP $formatted' : '₱$formatted';
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
        _branches = ['All Branches', ...bQuery.docs.map((d) => d.id)];
      });
    }
    await _loadReportData();
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF6A1028))),
          child: child!,
        );
      }
    );
    if (range != null) {
      setState(() {
        _selectedDateRange = 'Custom';
        _customStart = range.start;
        _customEnd = range.end.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      });
      _loadReportData();
    }
  }

  List<DateTime> _getDateRange() {
    DateTime now = DateTime.now();
    DateTime start = DateTime(2000);
    DateTime end = now;
    
    if (_selectedDateRange == 'Today') {
      start = DateTime(now.year, now.month, now.day);
    } else if (_selectedDateRange == 'This Week') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else if (_selectedDateRange == 'This Month') {
      start = DateTime(now.year, now.month, 1);
    } else if (_selectedDateRange == 'Custom' && _customStart != null && _customEnd != null) {
      start = _customStart!;
      end = _customEnd!;
    }
    
    end = DateTime(end.year, end.month, end.day, 23, 59, 59);
    
    return [start, end];
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final db = FirebaseFirestore.instance;
      final dates = _getDateRange();
      
      Query salesQ = db.collection('sales');
          
      if (_selectedBranch != 'All Branches') {
        // Query will need to be filtered locally since we have fallback names
      }
      
      final salesSnap = await salesQ.get();
      debugPrint('=== REPORTS DEBUG ===');
      debugPrint('Selected Branch: $_selectedBranch');
      debugPrint('Selected Date Range: $_selectedDateRange (${dates[0]} to ${dates[1]})');
      debugPrint('Total Documents retrieved: ${salesSnap.docs.length}');
      
      double tRev = 0;
      int tOrd = salesSnap.docs.length;
      double tCogs = 0;
      double tProf = 0;
      
      Map<String, double> cRev = {'Coffee': 0, 'Pastries': 0, 'Meals': 0, 'Desserts': 0, 'Others': 0};
      Map<String, int> cUnit = {'Coffee': 0, 'Pastries': 0, 'Meals': 0, 'Desserts': 0, 'Others': 0};
      Map<String, Map<String, dynamic>> pStats = {};
      Map<String, double> mRev = {};
      Map<String, double> bRev = {};
      
      int sCount = 0;
      for (var doc in salesSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        
        var dateVal = d['timestamp'];
        DateTime? dt;
        if (dateVal is Timestamp) {
          dt = dateVal.toDate();
        } else if (dateVal is DateTime) { dt = dateVal; }
        else if (dateVal is String) { dt = DateTime.tryParse(dateVal); }
        if (dt == null) continue;
        
        String docBranch = d['branchID'] ?? 'Unknown';
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
          if (docBranch != expectedBranchId) continue;
        }
        
        if (dt.isBefore(dates[0]) || dt.isAfter(dates[1])) continue;
        
        sCount++;
        tRev += (d['totalAmount'] as num?)?.toDouble() ?? 0.0;
        tCogs += (d['cost'] as num?)?.toDouble() ?? 0.0;
        tProf += (d['grossProfit'] as num?)?.toDouble() ?? 0.0;
      debugPrint('Included Doc: $dt | Rev: ${(d['totalAmount'] as num?)?.toDouble() ?? 0.0} | COGS: ${(d['cost'] as num?)?.toDouble() ?? 0.0} | Profit: ${(d['grossProfit'] as num?)?.toDouble() ?? 0.0}');
        
        String mKey = DateFormat('MMM').format(dt);
        mRev[mKey] = (mRev[mKey] ?? 0.0) + ((d['totalAmount'] as num?)?.toDouble() ?? 0.0);
        
        String bId = d['branchID'] ?? 'Unknown';
        bRev[bId] = (bRev[bId] ?? 0.0) + ((d['totalAmount'] as num?)?.toDouble() ?? 0.0);
        
        final items = d['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final pName = item['productName'] ?? 'Unknown';
          final qty = (item['quantity'] as num?)?.toInt() ?? 1;

          
          double iTotal = 0.0;
          if (item['totalPrice'] != null) {
            iTotal = (item['totalPrice'] as num).toDouble();
          } else if (item['price'] != null) { iTotal = (item['price'] as num).toDouble() * qty; }
          
          String cat = item['category'] ?? 'Others';
          if (cat == 'Dessert') cat = 'Desserts';
          if (cat == 'Pastry') cat = 'Pastries';
          if (cat == 'Meal') cat = 'Meals';
          if (!cRev.containsKey(cat)) cat = 'Others';
          
          cRev[cat] = (cRev[cat] ?? 0.0) + iTotal;
          cUnit[cat] = (cUnit[cat] ?? 0) + qty;
          
          if (!pStats.containsKey(pName)) pStats[pName] = {'units': 0, 'rev': 0.0};
          pStats[pName]!['units'] += qty;
          pStats[pName]!['rev'] += iTotal;
        }
      }
      
      tOrd = sCount;
      
      final prodsSnap = await db.collection('products').get();
      Map<String, String> pImages = {};
      for (var p in prodsSnap.docs) {
        pImages[p['productName'] ?? ''] = p['imageUrl'] ?? '';
      }
      debugPrint('=== REPORTS TOTALS ===');
      debugPrint('Total Revenue: $tRev');
      debugPrint('Total COGS: $tCogs');
      debugPrint('Total Gross Profit: $tProf');
      debugPrint('Filtered Doc Count: $sCount');
      
      var sortedP = pStats.entries.toList()..sort((a, b) => b.value['units'].compareTo(a.value['units']));
      List<Map<String, dynamic>> tProd = sortedP.take(10).map((e) => {
        'name': e.key, 
        'units': e.value['units'], 
        'rev': e.value['rev'],
        'image': pImages[e.key] ?? '',
      }).toList();
      
      // Inventory
      Query invQ = db.collection('inventory');
      if (_selectedBranch != 'All Branches') invQ = invQ.where('branchID', isEqualTo: _selectedBranch);
      final invSnap = await invQ.get();
      
      int tInvItems = invSnap.docs.length;
      double tCurrStock = 0;
      double tInvValue = 0;
      int tLowStock = 0;
      
      for (var doc in invSnap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        double cStock = (d['stock'] as num?)?.toDouble() ?? 0.0;
        double minStock = (d['minimumStock'] as num?)?.toDouble() ?? (d['reorderLevel'] as num?)?.toDouble() ?? 0.0;
        double cost = (d['unitCost'] as num?)?.toDouble() ?? (d['costPerUnit'] as num?)?.toDouble() ?? 0.0;
        
        tCurrStock += cStock;
        tInvValue += (cStock * cost);
        if (cStock <= minStock) tLowStock++;
      }
      
      // Shrinkages
      Query shQ = db.collection('shrinkage');
      if (_selectedBranch != 'All Branches') shQ = shQ.where('branchID', isEqualTo: _selectedBranch);
      final shSnap = await shQ.get();
      
      int shRecords = 0;
      double shQty = 0;
      double shLoss = 0;
      int shSp = 0, shWa = 0, shPi = 0, shCe = 0;
      int shPen = 0, shChk = 0;
      
      for (var doc in shSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['timestamp'] != null || data['reportedAt'] != null || data['recordedAt'] != null) {
          final tVal = data['timestamp'] ?? data['reportedAt'] ?? data['recordedAt'];
          DateTime dt = (tVal as Timestamp).toDate();
          if (dt.isBefore(dates[0]) || dt.isAfter(dates[1])) continue;
        }
        
        shRecords++;
        double qty = (data['variance'] as num?)?.toDouble().abs() ?? (data['quantity'] as num?)?.toDouble().abs() ?? 0.0;
        shQty += qty;
        shLoss += (data['lossValue'] as num?)?.toDouble() ?? (data['estimatedLoss'] as num?)?.toDouble() ?? 0.0;
        
        final r = data['reason'] ?? '';
        if (r.toString().toLowerCase().contains('spoil')) {
          shSp++;
        } else if (r.toString().toLowerCase().contains('wast')) { shWa++; }
        else if (r.toString().toLowerCase().contains('pilf')) { shPi++; }
        else if (r.toString().toLowerCase().contains('count') || r.toString().toLowerCase().contains('error')) { shCe++; }
        
        final status = data['status'] ?? 'Pending';
        if (status == 'Pending') {
          shPen++;
        } else if (status == 'Reviewed' || status == 'Checked') { shChk++; }
      }
      
      // Forecasts
      Query fQ = db.collection('forecasts');
      if (_selectedBranch != 'All Branches') {
        fQ = fQ.where('branchID', isEqualTo: _selectedBranch);
      }
      final fSnap = await fQ.get();
      
      double fRev = 0;
      int fOrd = 0;
      double fProf = 0;
      
      if (fSnap.docs.isNotEmpty) {
        final docs = fSnap.docs.toList();
        docs.sort((a, b) {
          final t1 = (a.data() as Map<String, dynamic>)['generatedAt'] as Timestamp?;
          final t2 = (b.data() as Map<String, dynamic>)['generatedAt'] as Timestamp?;
          if (t1 == null || t2 == null) return 0;
          return t2.compareTo(t1); // Descending order
        });
        
        final f = docs.first.data() as Map<String, dynamic>;
        fRev = (f['forecastRevenue'] as num?)?.toDouble() ?? 0.0;
        fOrd = (f['forecastOrders'] as num?)?.toInt() ?? 0;
        fProf = (f['forecastGrossProfit'] as num?)?.toDouble() ?? 0.0;
      }
      
      setState(() {
        _totalRevenue = tRev;
        _totalOrders = tOrd;
        _totalCogs = tCogs;
        _grossProfit = tProf;
        _categoryRevenue = cRev;
        _categoryUnits = cUnit;
        _topProducts = tProd;
        
        _monthlyRev = mRev;
        _branchRevenue = bRev;
        
        _totalInventoryItems = tInvItems;
        _totalCurrentStock = tCurrStock;
        _totalInventoryValue = tInvValue;
        _lowStockItems = tLowStock;
        
        _totalShrinkageRecords = shRecords;
        _totalShrinkageQuantity = shQty;
        _totalEstimatedLoss = shLoss;
        _shrinkageSpoilage = shSp;
        _shrinkageWastage = shWa;
        _shrinkagePilferage = shPi;
        _shrinkageCountError = shCe;
        _shrinkagePending = shPen;
        _shrinkageChecked = shChk;
        
        _forecastRev = fRev;
        _forecastOrd = fOrd;
        _forecastProfit = fProf;
        _monthlyRev = mRev;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();
      final String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String periodStr = '$_selectedDateRange (${DateFormat('MMM d, y').format(_getDateRange()[0])} - ${DateFormat('MMM d, y').format(_getDateRange()[1])})';
      
      final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
      final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
      final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text('Business Performance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.Text('Libro Espresso - ${_selectedBranch == 'All Branches' ? 'All Branches' : _formatBranchName(_selectedBranch)}', style: const pw.TextStyle(fontSize: 16)),
            pw.Text('Generated: $dateStr', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.Text('Period: $periodStr', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 24),
            
            pw.Header(level: 1, text: 'Executive Summary'),
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                ['Total Revenue', 'Total Orders', 'Total COGS', 'Gross Profit'],
                [formatCurrency(_totalRevenue, forPdf: true), numFmt.format(_totalOrders), formatCurrency(_totalCogs, forPdf: true), formatCurrency(_grossProfit, forPdf: true)]
              ],
            ),
            pw.SizedBox(height: 24),
            
            pw.Header(level: 1, text: 'Sales by Category'),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                ['Category', 'Units Sold', 'Revenue'],
                ..._categoryRevenue.entries.map((e) => [e.key, numFmt.format(_categoryUnits[e.key] ?? 0), formatCurrency(e.value, forPdf: true)])
              ],
            ),
            pw.SizedBox(height: 24),
            
            pw.Header(level: 1, text: 'Top 10 Selling Products'),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                ['Product Name', 'Units Sold', 'Revenue'],
                ..._topProducts.map((e) => [e['name'].toString(), numFmt.format(e['units']), formatCurrency(e['rev'], forPdf: true)])
              ],
            ),
            pw.SizedBox(height: 24),
            
            pw.Header(level: 1, text: 'Inventory Summary'),
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                ['Metric', 'Value'],
                ['Total Inventory Items', numFmt.format(_totalInventoryItems)],
                ['Total Current Stock', numFmt.format(_totalCurrentStock)],
                ['Total Inventory Value', formatCurrency(_totalInventoryValue, forPdf: true)],
                ['Low Stock Items', numFmt.format(_lowStockItems)],
              ],
            ),
            pw.SizedBox(height: 24),
            
            pw.Header(level: 1, text: 'Shrinkage Summary'),
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                ['Metric', 'Value'],
                ['Total Shrinkage Records', numFmt.format(_totalShrinkageRecords)],
                ['Total Shrinkage Quantity', numFmt.format(_totalShrinkageQuantity)],
                ['Total Estimated Loss', formatCurrency(_totalEstimatedLoss, forPdf: true)],
                ['Spoilage', numFmt.format(_shrinkageSpoilage)],
                ['Wastage', numFmt.format(_shrinkageWastage)],
                ['Pilferage', numFmt.format(_shrinkagePilferage)],
                ['Count Error', numFmt.format(_shrinkageCountError)],
                ['Pending Records', numFmt.format(_shrinkagePending)],
                ['Checked Records', numFmt.format(_shrinkageChecked)],
              ],
            ),
            pw.SizedBox(height: 24),
            
            pw.Header(level: 1, text: 'Forecast Summary (Active)'),
            pw.TableHelper.fromTextArray(
              context: context,
              data: [
                ['Forecast Revenue', 'Forecast Orders', 'Expected Gross Profit'],
                [formatCurrency(_forecastRev, forPdf: true), numFmt.format(_forecastOrd), formatCurrency(_forecastProfit, forPdf: true)]
              ],
            ),
          ];
        },
      ),
    );

      final bytes = await pdf.save();
      final filename = 'LibroEspresso_Report_$dateStr.pdf';

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report exported successfully.'), backgroundColor: Colors.green));
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report exported successfully to Documents/$filename'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      bottomNavigationBar: DashboardBottomNav(selectedIndex: SessionManager().isOwner ? 2 : 3),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _maroon))
                : _buildDashboard(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return CustomPageHeader(
      title: 'Reports',
      onBack: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (route) => false),
      bottomChild: Text(
        'Business performance summary.',
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildDashboard() {
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
                _buildDropdown('Date',
                    ['Today', 'This Week', 'This Month', 'Custom'],
                    _selectedDateRange, (v) {
                  if (v == 'Custom') {
                    _pickDateRange();
                  } else {
                    setState(() => _selectedDateRange = v!);
                    _loadReportData();
                  }
                }),
                if (_session.isOwner) ...[
                  const SizedBox(width: 10),
                  _buildDropdown('Branch', _branches, _selectedBranch, (v) {
                    if (v != null && v != _selectedBranch) {
                      setState(() => _selectedBranch = v);
                      _loadReportData();
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
                  'Total Revenue',
                  formatCurrency(_totalRevenue),
                  Icons.payments_rounded,
                  const LinearGradient(
                      colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)]),
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  'Total Orders',
                  numFmt.format(_totalOrders),
                  Icons.receipt_long_rounded,
                  const LinearGradient(
                      colors: [Color(0xFF7B1A35), Color(0xFFAB2550)]),
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  'Total COGS',
                  formatCurrency(_totalCogs),
                  Icons.inventory_2_rounded,
                  const LinearGradient(
                      colors: [Color(0xFF8B2040), Color(0xFFBB3060)]),
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  'Gross Profit',
                  formatCurrency(_grossProfit),
                  Icons.trending_up_rounded,
                  const LinearGradient(
                      colors: [Color(0xFFD4A853), Color(0xFFE8C070)]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sales Summary
          _buildSectionHeader('Sales Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _cardShadow),
            child: Column(
              children: [
                _buildRow('Revenue', formatCurrency(_totalRevenue),
                    _maroon),
                const Divider(height: 1),
                _buildRow(
                    'Orders', numFmt.format(_totalOrders), _textPrimary),
                const Divider(height: 1),
                _buildRow(
                    'Average Order Value',
                    formatCurrency(_totalOrders > 0
                        ? _totalRevenue / _totalOrders
                        : 0),
                    _textPrimary),
                const Divider(height: 1),
                _buildRow('Gross Profit', formatCurrency(_grossProfit),
                    const Color(0xFF059669)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Branch Performance
          if (_session.isOwner) ...[
            _buildSectionHeader('Branch Performance'),
            const SizedBox(height: 12),
            ..._branchRevenue.entries.map((e) {
              return _buildCategoryRow(_formatBranchName(e.key), '', formatCurrency(e.value));
            }),
            const SizedBox(height: 28),
          ],

          // Analytics
          _buildSectionHeader('Analytics'),
          const SizedBox(height: 12),
          _buildChartContainer('Sales by Category', _buildPieChart()),
          const SizedBox(height: 16),
          _buildChartContainer('Monthly Revenue', _buildBarChart()),
          const SizedBox(height: 28),

          // Top Selling Products
          _buildSectionHeader('Top 10 Selling Products'),
          const SizedBox(height: 12),
          ..._topProducts.asMap().entries.map((entry) {
            final idx = entry.key;
            final e = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _cardShadow),
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
                    child: Text('${idx + 1}',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  if (e['image'] != null &&
                      e['image'].toString().isNotEmpty) ...[  
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: _cream,
                          borderRadius: BorderRadius.circular(8)),
                      clipBehavior: Clip.hardEdge,
                      child: Image.network(e['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.coffee_rounded,
                              color: _maroon)),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['name'],
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _textPrimary)),
                        Text('${numFmt.format(e['units'])} Units',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _textSecondary)),
                      ],
                    ),
                  ),
                  Text(formatCurrency(e['rev']),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _maroon)),
                ],
              ),
            );
          }),
          const SizedBox(height: 28),

          // Inventory Summary
          _buildSectionHeader('Inventory Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _cardShadow),
            child: Column(
              children: [
                _buildRow('Total Inventory Items',
                    numFmt.format(_totalInventoryItems), _textPrimary),
                const Divider(height: 1),
                _buildRow('Total Current Stock',
                    numFmt.format(_totalCurrentStock), _maroon),
                const Divider(height: 1),
                _buildRow('Total Inventory Value',
                    formatCurrency(_totalInventoryValue),
                    const Color(0xFF059669)),
                const Divider(height: 1),
                _buildRow('Low Stock Items',
                    numFmt.format(_lowStockItems),
                    const Color(0xFFD97706)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Shrinkage Summary
          _buildSectionHeader('Shrinkage Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _cardShadow),
            child: Column(
              children: [
                _buildRow('Total Shrinkage Records',
                    numFmt.format(_totalShrinkageRecords), _textPrimary),
                const Divider(height: 1),
                _buildRow('Total Shrinkage Quantity',
                    numFmt.format(_totalShrinkageQuantity),
                    const Color(0xFFDC2626)),
                const Divider(height: 1),
                _buildRow('Total Estimated Loss',
                    formatCurrency(_totalEstimatedLoss),
                    const Color(0xFFDC2626)),
                const Divider(height: 1),
                _buildRow('Spoilage',
                    numFmt.format(_shrinkageSpoilage),
                    const Color(0xFFD97706)),
                const Divider(height: 1),
                _buildRow('Wastage',
                    numFmt.format(_shrinkageWastage),
                    const Color(0xFFEF4444)),
                const Divider(height: 1),
                _buildRow('Pilferage',
                    numFmt.format(_shrinkagePilferage),
                    const Color(0xFF7C3AED)),
                const Divider(height: 1),
                _buildRow('Count Error',
                    numFmt.format(_shrinkageCountError), _textSecondary),
                const Divider(height: 1),
                _buildRow('Pending Records',
                    numFmt.format(_shrinkagePending), _textSecondary),
                const Divider(height: 1),
                _buildRow('Checked Records',
                    numFmt.format(_shrinkageChecked),
                    const Color(0xFF059669)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Forecast Summary
          _buildSectionHeader('Active Forecast Summary'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _cardShadow),
            child: Column(
              children: [
                _buildRow('Forecast Revenue', formatCurrency(_forecastRev),
                    _maroon),
                const Divider(height: 1),
                _buildRow('Forecast Orders', numFmt.format(_forecastOrd),
                    const Color(0xFF7C3AED)),
                const Divider(height: 1),
                _buildRow('Forecast Gross Profit',
                    formatCurrency(_forecastProfit),
                    const Color(0xFF059669)),
              ],
            ),
          ),

          // Export button (bottom of scroll)
          if (_session.isOwner) ...[
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _exportPdf,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_maroon, _burgundy],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _cardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Export Full Report (PDF)',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: _textSecondary, fontSize: 13)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
      String category, String units, String revenue) {
    final Map<String, IconData> categoryIcons = {
      'Coffee': Icons.local_cafe_rounded,
      'Pastries': Icons.bakery_dining_rounded,
      'Meals': Icons.restaurant_rounded,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _textPrimary)),
                Text('$units Units',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: _textSecondary)),
              ],
            ),
          ),
          Text(revenue,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _maroon)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String current,
      void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _maroon.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
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
                    child: Text(e == 'All Branches' ? e : _formatBranchName(e),
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

  Widget _buildKpiCard(String title, String value, IconData icon,
      Gradient gradient) {
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                    color: _maroon,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          chart,
        ],
      ),
    );
  }

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

  Widget _buildPieChart() {
    if (_categoryRevenue.isEmpty || _categoryRevenue.values.every((v) => v == 0)) {
      return Center(child: Text('No data', style: GoogleFonts.poppins(color: Colors.grey)));
    }
    
    final colors = [
      const Color(0xFF6A1028),
      const Color(0xFF4B0017),
      const Color(0xFF8A1C3C),
      const Color(0xFFF57C00),
      const Color(0xFF2E7D32),
    ];

    int colorIndex = 0;
    List<PieChartSectionData> sections = [];
    double totalSum = _categoryRevenue.values.fold(0.0, (a, b) => a + b);
    List<Widget> legends = [];

    _categoryRevenue.forEach((key, val) {
      if (val > 0) {
        Color c = colors[colorIndex % colors.length];
        double pct = (val / totalSum) * 100;
        
        sections.add(
          PieChartSectionData(
            color: c,
            value: val,
            title: '${pct.toStringAsFixed(0)}%',
            radius: 35,
            titleStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 8),
                Expanded(child: Text(key, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF1F2937), fontWeight: FontWeight.w500))),
                Flexible(child: Text(formatCurrency(val), style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
              ],
            ),
          )
        );
        colorIndex++;
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 380) {
          return Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: sections,
                  ),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: legends)),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
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
    );
  }

  Widget _buildBarChart() {
    if (_monthlyRev.isEmpty) {
      return Center(child: Text('No data', style: GoogleFonts.poppins(color: Colors.grey)));
    }
    List<BarChartGroupData> groups = [];
    int x = 0;
    _monthlyRev.forEach((key, val) {
      groups.add(BarChartGroupData(
        x: x,
        barRods: [BarChartRodData(toY: val, color: const Color(0xFF6A1028), width: 16, borderRadius: BorderRadius.circular(4))],
      ));
      x++;
    });
    
    return SizedBox(height: 200, child: BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      barGroups: groups,
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              if (val.toInt() >= 0 && val.toInt() < _monthlyRev.keys.length) {
                return Text(_monthlyRev.keys.elementAt(val.toInt()), style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700));
              }
              return const SizedBox();
            },
          )
        )
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
    )));
  }
}
