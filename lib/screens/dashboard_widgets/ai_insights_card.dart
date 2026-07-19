import 'package:flutter/material.dart';

class AiInsightsCard extends StatelessWidget {
  final List<Map<String, dynamic>> insights;
  
  const AiInsightsCard({super.key, required this.insights});

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'recommendation':
      case 'trend': return Colors.greenAccent;
      case 'inventory':
      case 'reorder': return Colors.yellowAccent;
      case 'production':
      case 'demand': return Colors.orangeAccent;
      case 'warning':
      case 'shrinkage': return Colors.redAccent;
      default: return Colors.blueAccent;
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'recommendation':
      case 'trend': return Icons.trending_up;
      case 'inventory':
      case 'reorder': return Icons.inventory_2_outlined;
      case 'production':
      case 'demand': return Icons.bakery_dining_outlined;
      case 'warning':
      case 'shrinkage': return Icons.warning_amber_rounded;
      default: return Icons.insights;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B0918),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFC89B3C).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.smart_toy_outlined, color: Color(0xFFC89B3C), size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Business Insights', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Predictive analytics • Updated just now', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white70)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (insights.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Text('No insights generated yet. AI models are analyzing your recent data.', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: insights.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final insight = insights[index];
                String type = insight['type'] ?? 'info';
                return _buildInsightRow(
                  color: _getColorForType(type),
                  icon: _getIconForType(type),
                  title: insight['title'] ?? 'Insight',
                  content: insight['content'] ?? '',
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({required Color color, required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4, fontFamily: 'Poppins')),
              ],
            ),
          )
        ],
      ),
    );
  }
}
