import 'dart:io';

void main() {
  // 1. Top Selling Products
  File('lib/screens/dashboard_widgets/top_products.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class TopProducts extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  
  const TopProducts({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Selling Products', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
              Text('This Period', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 24),
          if (products.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No products sold in this period.")))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: Colors.grey.shade100, height: 1),
              ),
              itemBuilder: (context, index) {
                final prod = products[index];
                return _buildProductRow(
                  rank: index + 1,
                  name: prod['name'],
                  sold: prod['sold'],
                  revenue: prod['revenue'],
                  profit: prod['profit'],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildProductRow({required int rank, required String name, required int sold, required double revenue, required double profit}) {
    Color badgeColor;
    if (rank == 1) badgeColor = const Color(0xFFC89B3C); // Gold
    else if (rank == 2) badgeColor = Colors.grey.shade400; // Silver
    else if (rank == 3) badgeColor = const Color(0xFFCD7F32); // Bronze
    else badgeColor = Colors.grey.shade200;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          child: Center(
            child: Text('\$rank', style: TextStyle(color: rank <= 3 ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFF6A1028).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.coffee, color: Color(0xFF6A1028), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter', color: Color(0xFF1F2937)), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('\$sold Units', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₱\${revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
              const SizedBox(height: 4),
              Text('Profit: ₱\${profit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.green)),
            ],
          ),
        ),
      ],
    );
  }
}
''');

  // 2. AI Insights
  File('lib/screens/dashboard_widgets/ai_insights_card.dart').writeAsStringSync('''
import 'package:flutter/material.dart';

class AiInsightsCard extends StatelessWidget {
  final List<Map<String, dynamic>> insights;
  
  const AiInsightsCard({Key? key, required this.insights}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We map Firestore/Gemini insights to the visual colors defined in spec.
    // If not enough insights are provided by DB, we fall back to defaults.
    
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF3B0918), // Dark burgundy
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6A1028).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFC89B3C).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.smart_toy_outlined, color: Color(0xFFC89B3C), size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Business Insights', style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Predictive analytics • Updated just now', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Map to visually distinct cards (Green, Yellow, Orange, Red)
          _buildInsightRow(
            color: Colors.greenAccent,
            icon: Icons.trending_up,
            title: 'Coffee Recommendation',
            content: insights.isNotEmpty ? insights[0]['content'] : 'Stock up on Arabica beans before the weekend rush.',
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            color: Colors.yellowAccent,
            icon: Icons.inventory_2_outlined,
            title: 'Milk Reorder',
            content: insights.length > 1 ? insights[1]['content'] : 'Whole milk is depleting 15% faster than usual.',
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            color: Colors.orangeAccent,
            icon: Icons.bakery_dining_outlined,
            title: 'Croissant Production',
            content: insights.length > 2 ? insights[2]['content'] : 'Increase croissant baking by 20% tomorrow morning.',
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            color: Colors.redAccent,
            icon: Icons.warning_amber_rounded,
            title: 'Shrinkage Warning',
            content: insights.length > 3 ? insights[3]['content'] : 'Unusual discrepancy in espresso cup inventory detected.',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({required Color color, required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter')),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
''');
}
