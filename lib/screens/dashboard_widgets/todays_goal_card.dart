import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/session_manager.dart';

class TodaysGoalCard extends StatefulWidget {
  final double revenueTarget;

  const TodaysGoalCard({
    super.key,
    this.revenueTarget = 20000.0,
  });

  @override
  State<TodaysGoalCard> createState() => _TodaysGoalCardState();
}

class _TodaysGoalCardState extends State<TodaysGoalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;
  double _currentRevenue = 0;
  double _prevProgress = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateProgress(double newProgress) {
    _progressAnim = Tween<double>(begin: _prevProgress, end: newProgress)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward(from: 0);
    _prevProgress = newProgress;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final branchId = session.branchID ?? '';

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sales')
          .where('branchID', isEqualTo: branchId)
          .snapshots(),
      builder: (context, snapshot) {
        double currentRevenue = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            var dateVal = data['timestamp'];
            DateTime? date;
            if (dateVal != null) {
              if (dateVal.runtimeType.toString() == 'Timestamp') {
                date = (dateVal as Timestamp).toDate();
              } else if (dateVal is DateTime) {
                date = dateVal;
              } else if (dateVal is String) {
                date = DateTime.tryParse(dateVal);
              }
            }
            if (date == null) continue;

            if ((date.isAfter(todayStart) ||
                    date.isAtSameMomentAs(todayStart)) &&
                date.isBefore(todayEnd)) {
              currentRevenue +=
                  (data['totalAmount'] ?? 0.0).toDouble();
            }
          }
        }

        if (currentRevenue != _currentRevenue) {
          _currentRevenue = currentRevenue;
          final newProgress =
              (currentRevenue / widget.revenueTarget).clamp(0.0, 1.0);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _animateProgress(newProgress);
          });
        }

        final progressPct =
            ((currentRevenue / widget.revenueTarget) * 100).clamp(0.0, 999.9);
        final bool targetAchieved = currentRevenue >= widget.revenueTarget;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1028).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: Color(0xFF6A1028),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Goal",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Revenue Progress',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8A8A8A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Revenue target and current
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revenue Target',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₱${_formatAmount(widget.revenueTarget)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Current Revenue',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₱${_formatAmount(currentRevenue)}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1028),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress bar
              AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EDE8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Fill
                        FractionallySizedBox(
                          widthFactor: _progressAnim.value.clamp(0.0, 1.0),
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF8A1C3C),
                                  Color(0xFF6A1028),
                                  Color(0xFF4B0017),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6A1028)
                                      .withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Percentage and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progressPct.toStringAsFixed(0)}% Complete',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  if (targetAchieved)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.shade200, width: 1),
                      ),
                      child: const Text(
                        '✅ Target Achieved',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1028).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF6A1028).withOpacity(0.15),
                            width: 1),
                      ),
                      child: const Text(
                        '🎯 Keep Going!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A1028),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
