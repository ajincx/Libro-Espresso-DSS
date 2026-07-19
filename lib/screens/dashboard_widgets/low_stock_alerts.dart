import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LowStockAlertsCard extends StatelessWidget {
  const LowStockAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
              const SizedBox(width: 12),
              Text('Low Stock Alerts', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6A1028))),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('inventory')
                .where('status', whereIn: ['Low Stock', 'Out of Stock'])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Text('Error loading alerts', style: TextStyle(fontFamily: 'Poppins', color: Colors.red));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade600),
                      const SizedBox(width: 12),
                      Expanded(child: Text('All inventory levels are healthy.', style: TextStyle(fontFamily: 'Poppins', color: Colors.green.shade800, fontWeight: FontWeight.w500))),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final name = data['ingredientName'] ?? 'Unknown';
                  final stock = data['expectedStock'] ?? data['stock'] ?? 0.0;
                  final unit = data['unit'] ?? '';
                  final status = data['status'] ?? 'Low Stock';
                  
                  Color statusColor = status == 'Out of Stock' ? Colors.red : Colors.orange;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.black87), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('Current: $stock $unit', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(status, style: TextStyle(fontFamily: 'Poppins', color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
