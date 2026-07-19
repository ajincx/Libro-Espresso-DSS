import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'calendar_picker.dart';

class SalesTrendCard extends StatelessWidget {
  final List<double> dataPoints;
  final double salesTrendChangePercentage;
  final bool isOwner;
  final String selectedBranch;
  final String selectedMonth;
  final String selectedDay;
  final List<Map<String, String>> branchesList;
  final Function(String) onBranchChanged;
  final Function(String) onMonthChanged;
  final Function(String) onDaySelected;

  const SalesTrendCard({
    super.key,
    required this.dataPoints,
    required this.salesTrendChangePercentage,
    required this.isOwner,
    required this.selectedBranch,
    required this.selectedMonth,
    required this.selectedDay,
    required this.branchesList,
    required this.onBranchChanged,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    List<double> points = dataPoints;
    double maxVal = points.isNotEmpty ? points.reduce((a, b) => a > b ? a : b) : 100;
    if (maxVal == 0) maxVal = 100;
    List<FlSpot> spots = List.generate(points.length, (i) => FlSpot(i.toDouble(), points[i]));

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmall = constraints.maxWidth <= 375;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: EdgeInsets.all(isSmall ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter row at top
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (isOwner)
                      _buildBranchDropdown(selectedBranch, branchesList, onBranchChanged),
                    if (isOwner) const SizedBox(width: 8),
                    _buildDropdown(selectedMonth, ['January', 'February', 'March', 'April', 'May', 'June', 'July'], onMonthChanged),
                    const SizedBox(width: 8),
                    _buildCalendarButton(context),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Subtitle
              Text(
                'Shows daily revenue movement throughout the selected period.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: isSmall ? 16 : 24),
              // Chart
              SizedBox(
                height: isSmall ? 200 : 220,
                child: points.isEmpty || points.every((e) => e == 0)
                    ? const Center(
                        child: Text(
                          "No data available",
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: (maxVal / 4) == 0 ? 1 : (maxVal / 4),
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.withValues(alpha: 0.2),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: (points.length / (isSmall ? 3 : 4)).ceilToDouble().clamp(1, 100),
                                getTitlesWidget: (value, meta) {
                                  int index = value.toInt();
                                  if (index < 0 || index >= points.length) return const SizedBox();
                                  // Show day number only to avoid overlap
                                  String label = '${index + 1}';
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 4,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: isSmall ? 36 : 40,
                                getTitlesWidget: (value, meta) {
                                  // Skip rendering if value would overlap with min/max
                                  if (value == meta.max || value == meta.min) return const SizedBox();
                                  String label;
                                  if (value == 0) {
                                    label = '₱0';
                                  } else if (value >= 1000) {
                                    label = '₱${(value / 1000).toStringAsFixed(0)}k';
                                  } else {
                                    label = '₱${value.toStringAsFixed(0)}';
                                  }
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 4,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 10,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          minX: 0,
                          maxX: (points.length - 1).toDouble(),
                          minY: 0,
                          maxY: maxVal * 1.2,
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (spot) => const Color(0xFF6A1028),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    '₱${NumberFormat('#,##0').format(spot.y)}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: const Color(0xFF6A1028),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              shadow: Shadow(
                                color: const Color(0xFF6A1028).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF6A1028).withValues(alpha: 0.15),
                                    const Color(0xFF6A1028).withValues(alpha: 0.0),
                                  ],
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
        );
      },
    );
  }

  Widget _buildBranchDropdown(String value, List<Map<String, String>> branches, Function(String) onChanged) {
    bool hasValue = branches.any((b) => b['id'] == value) || value == 'All Branches';
    String safeValue = hasValue ? value : 'All Branches';
    
    List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem<String>(
        value: 'All Branches',
        child: Text('All Branches', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF4B5563))),
      )
    ];
    
    items.addAll(branches.map((b) {
      return DropdownMenuItem<String>(
        value: b['id'],
        child: Text(b['name']!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF4B5563))),
      );
    }));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6A1028)),
          items: items,
          onChanged: (v) => onChanged(v!),
        ),
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
              child: Text(item, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF4B5563))),
            );
          }).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Widget _buildCalendarButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6A1028),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showCalendarPopup(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Icon(Icons.calendar_month, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }

  void _showCalendarPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.transparent, 
      pageBuilder: (context, animation, secondaryAnimation) {
        return CalendarPicker(
          selectedMonth: selectedMonth,
          selectedDay: selectedDay,
          onDaySelected: onDaySelected,
          onClear: () => onDaySelected('All Days'),
        );
      },
    );
  }
}
