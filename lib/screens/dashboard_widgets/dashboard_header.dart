import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/session_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning,';
    if (hour >= 12 && hour < 18) return 'Good Afternoon,';
    return 'Good Evening,';
  }



  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final String displayName = (session.displayName?.isNotEmpty ?? false) ? session.displayName! : 'John';
    
    return FutureBuilder<DocumentSnapshot?>(
      future: (!session.isOwner && session.branchID?.isNotEmpty == true)
          ? FirebaseFirestore.instance.collection('branches').doc(session.branchID).get()
          : Future.value(null),
      builder: (context, snapshot) {
        String branchText = 'All Branches';
        if (!session.isOwner) {
          if (snapshot.hasData && snapshot.data!.exists) {
            branchText = (snapshot.data!.data() as Map<String, dynamic>)['branchName'] ?? session.branchID!;
          } else {
            branchText = session.branchID ?? 'Main Branch';
          }
        }
        
        return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2A0008), Color(0xFF6A1028)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            // Abstract static background decorations
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 120,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 60,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.isOwner ? "Owner" : "Manager"} $displayName',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                branchText,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () => _showNotifications(context, session),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }



  void _showNotifications(BuildContext context, SessionManager session) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: _NotificationList(session: session),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationList extends StatelessWidget {
  final SessionManager session;
  const _NotificationList({required this.session});

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    List<Map<String, dynamic>> notifications = [];
    final firestore = FirebaseFirestore.instance;
    try {
      if (!session.isOwner) {
        final branchID = session.branchID;
        final invSnap = await firestore.collection('inventory').get();
        for (var doc in invSnap.docs) {
          final data = doc.data();
          String docBranch = data['branchID'] ?? data['branchId'] ?? '';
          if (docBranch == branchID || docBranch.isEmpty) {
            double qty = (data['expectedStock'] ?? data['stock'] ?? data['quantity'] ?? 0).toDouble();
            double minStock = (data['reorderLevel'] ?? data['minimumStock'] ?? 20).toDouble();
            if (qty <= minStock) {
              notifications.add({
                'title': 'Low Stock Detected',
                'message': 'Low stock detected for ${data['ingredientName'] ?? 'Unknown Item'} (${qty.toStringAsFixed(1)} left).',
                'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
                'icon': Icons.warning_amber_rounded,
                'color': Colors.orange,
                'unread': true,
              });
            }
          }
        }
        final shrinkSnap = await firestore.collection('shrinkage').get();
        for (var doc in shrinkSnap.docs) {
          final data = doc.data();
          String docBranch = data['branchID'] ?? data['branchId'] ?? '';
          if (docBranch == branchID) {
            DateTime? ts;
            if (data['timestamp'] != null) {
              ts = (data['timestamp'] as Timestamp).toDate();
            }
            notifications.add({
              'title': 'Shrinkage Report',
              'message': 'Shrinkage report status: ${data['status'] ?? 'Pending'}',
              'timestamp': ts ?? DateTime.now().subtract(const Duration(hours: 1)),
              'icon': Icons.report_problem_outlined,
              'color': const Color(0xFF6A1028),
              'unread': true,
            });
          }
        }
        final salesSnap = await firestore.collection('sales').orderBy('timestamp', descending: true).limit(1).get();
        for (var doc in salesSnap.docs) {
          final data = doc.data();
          String docBranch = data['branchID'] ?? data['branchId'] ?? '';
          if (docBranch == branchID) {
             DateTime? ts;
             if (data['timestamp'] != null) {
               ts = (data['timestamp'] as Timestamp).toDate();
             }
             notifications.add({
               'title': 'Sale Imported',
               'message': 'Latest sale file imported.',
               'timestamp': ts ?? DateTime.now(),
               'icon': Icons.check_circle_outline,
               'color': Colors.green,
               'unread': true,
             });
          }
        }
      } else {
        final salesSnap = await firestore.collection('sales').orderBy('timestamp', descending: true).limit(5).get();
        for (var doc in salesSnap.docs) {
          final data = doc.data();
          DateTime? ts;
          if (data['timestamp'] != null) {
            ts = (data['timestamp'] as Timestamp).toDate();
          }
          notifications.add({
            'title': 'New Sales File',
            'message': 'New sales file imported from a branch.',
            'timestamp': ts ?? DateTime.now(),
            'icon': Icons.upload_file,
            'color': Colors.blue,
            'unread': true,
          });
        }
        final shrinkSnap = await firestore.collection('shrinkage').orderBy('timestamp', descending: true).limit(5).get();
        for (var doc in shrinkSnap.docs) {
          final data = doc.data();
          DateTime? ts;
          if (data['timestamp'] != null) {
            ts = (data['timestamp'] as Timestamp).toDate();
          }
          notifications.add({
            'title': 'New Shrinkage Report',
            'message': 'New shrinkage report submitted.',
            'timestamp': ts ?? DateTime.now(),
            'icon': Icons.assignment_late_outlined,
            'color': const Color(0xFF6A1028),
            'unread': true,
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    notifications.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return notifications;
  }

  String _timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF6A1028), // Maroon accent header
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notifications', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        Flexible(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF6A1028))),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text('No notifications right now.', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey))),
                );
              }
              final items = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: (item['color'] as Color).withValues(alpha: 0.1),
                          child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title'],
                                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (item['unread'] == true)
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(color: Color(0xFF6A1028), shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['message'],
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _timeAgo(item['timestamp'] as DateTime),
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
