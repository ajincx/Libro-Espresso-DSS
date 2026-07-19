import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class KpiCard extends StatelessWidget {
  final double revenue;
  final int orders;
  final double profit;
  final int activeProducts;
  final double revenueChangePercentage;
  final List<FlSpot> sparklineSpots;

  const KpiCard({
    super.key, 
    required this.revenue, 
    required this.orders, 
    required this.profit, 
    required this.activeProducts,
    required this.revenueChangePercentage,
    required this.sparklineSpots,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 0,
    );
    String fmt(double v) => formatter.format(v);

    bool isPositive = revenueChangePercentage >= 0;
    Color changeColor = isPositive ? Colors.greenAccent : Colors.redAccent;
    IconData changeIcon = isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down;
    
    // Sparkline scaling bounds
    double maxSpotY = 0;
    for (var spot in sparklineSpots) {
      if (spot.y > maxSpotY) maxSpotY = spot.y;
    }
    if (maxSpotY == 0) maxSpotY = 100;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(fmt(revenue), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 4,
                child: ClipRect(
                  child: SizedBox(
                    height: 34,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: maxSpotY * 1.1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: sparklineSpots,
                            isCurved: true,
                            preventCurveOverShooting: true,
                            color: Colors.white,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: changeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(changeIcon, color: changeColor, size: 16),
                    Text('${revenueChangePercentage.abs().toStringAsFixed(1)}%', style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Poppins')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('vs previous', style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Poppins')),
            ],
          ),
          const SizedBox(height: 24),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildBottomMetric('Orders', orders.toString(), Colors.white)),
              Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(child: _buildBottomMetric('Gross Profit', fmt(profit), Colors.greenAccent)),
              Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(child: _buildBottomMetric('Products', activeProducts.toString(), Colors.white, icon: Icons.inventory_2_outlined)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomMetric(String label, String val, Color valColor, {IconData? icon}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white70, size: 12),
              const SizedBox(width: 4),
            ] else ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(color: valColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'Poppins'))),
          ]
        ),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valColor, fontFamily: 'Poppins'))),
      ],
    );
  }
}
