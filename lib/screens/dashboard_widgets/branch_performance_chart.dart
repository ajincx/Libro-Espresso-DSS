import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BranchPerformanceChart extends StatelessWidget {
  final Map<String, double> branchPerformance;
  const BranchPerformanceChart({super.key, required this.branchPerformance});

  @override
  Widget build(BuildContext context) {
    String formatBranchName(String id) {
      switch (id) {
        case 'branch_1': return 'Main Branch';
        case 'branch_2': return 'Lipa Branch';
        case 'branch_3': return 'Tagaytay Branch';
        case 'branch_4': return 'Evo Branch';
        case 'branch_5': return 'Vermosa Branch';
        default: return id;
      }
    }

    List<Color> colors = [
      const Color(0xFF6A1028),
      const Color(0xFF4B0017),
      const Color(0xFF8A1C3C),
      const Color(0xFFF57C00),
      const Color(0xFF2E7D32),
    ];

    double totalSum = branchPerformance.values.fold(0, (a, b) => a + b);
    if (totalSum == 0) totalSum = 1;

    List<PieChartSectionData> sections = [];
    int colorIndex = 0;
    List<Widget> legends = [];

    // Sort by sales descending
    var sortedEntries = branchPerformance.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < sortedEntries.length; i++) {
      var entry = sortedEntries[i];
      Color c = colors[colorIndex % colors.length];
      double pct = (entry.value / totalSum) * 100;

      sections.add(
          PieChartSectionData(
            color: c,
            value: entry.value,
            title: '${pct.toStringAsFixed(0)}%',
            radius: 40,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
            badgeWidget: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.circle, color: c, size: 8),
            ),
            badgePositionPercentageOffset: 1.1,
          ),
        );

        legends.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          formatBranchName(entry.key),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (i == 0 && sortedEntries.length > 1) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Highest', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                        ),
                      ] else if (i == sortedEntries.length - 1 && sortedEntries.length > 1) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Lowest', style: TextStyle(fontSize: 8, color: Colors.orange, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '₱${NumberFormat('#,##0').format(entry.value)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
        colorIndex++;
    }

    if (sections.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "No data available",
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
            ),
          ),
        ),
      );
    }

    String highestBranch =
        sortedEntries.isNotEmpty && sortedEntries.first.value > 0
        ? formatBranchName(sortedEntries.first.key)
        : 'N/A';
    String lowestBranch =
        sortedEntries.isNotEmpty && sortedEntries.last.value > 0
        ? formatBranchName(sortedEntries.last.key)
        : 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 350) {
                return Row(
                  children: [
                    SizedBox(
                      height: 160,
                      width: 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 35,
                          sections: sections,
                        ),
                        duration: const Duration(
                          milliseconds: 1200,
                        ),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: legends,
                      ),
                    ),
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
                        duration: const Duration(
                          milliseconds: 1200,
                        ),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(children: legends),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Highest-performing',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    highestBranch,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Lowest-performing',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    lowestBranch,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE11D48),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
