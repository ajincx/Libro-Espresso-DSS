import 'package:flutter/material.dart';
import '../products/products_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../reports/reports_screen.dart';
import '../account/account_screen.dart';
import '../import_screen.dart';
import '../../core/session_manager.dart';

class DashboardBottomNav extends StatelessWidget {
  final int selectedIndex;
  const DashboardBottomNav({super.key, this.selectedIndex = 0});

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24), // Floating spacing
      decoration: BoxDecoration(
        color: Colors.white, // White background
        borderRadius: BorderRadius.circular(40), // Pill-shaped rounded rectangle
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B1C3F).withValues(alpha: 0.1), // Soft maroon shadow
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 65,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: session.isOwner
                    ? [
                        _buildNavItem(context, 0, Icons.home_outlined, 'Home'),
                        _buildNavItem(context, 1, Icons.local_cafe_outlined, 'Products'),
                        _buildNavItem(context, 2, Icons.bar_chart_rounded, 'Reports'),
                        _buildNavItem(context, 3, Icons.person_outline, 'Account'),
                      ]
                    : [
                        _buildNavItem(context, 0, Icons.home_outlined, 'Home'),
                        _buildNavItem(context, 1, Icons.local_cafe_outlined, 'Products'),
                        _buildNavItem(context, 2, Icons.upload_file_rounded, 'Import'),
                        _buildNavItem(context, 3, Icons.bar_chart_rounded, 'Reports'),
                        _buildNavItem(context, 4, Icons.person_outline, 'Account'),
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    final color = isSelected ? const Color(0xFF9B1C3F) : Colors.grey; // Maroon active, Gray inactive
    
    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            final session = SessionManager();
            if (session.isOwner) {
              if (index == 0) {
                 Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (r) => false);
              } else if (index == 1) {
                 Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const ProductsScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
              } else if (index == 2) {
                 Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const ReportsScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
              } else if (index == 3) {
                 Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const AccountScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
              }
            } else {
              if (index == 0) {
                 Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (r) => false);
              } else if (index == 1) {
                 Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const ProductsScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
              } else if (index == 2) {
                 Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const ImportScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
              } else if (index == 3) {
                 Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const ReportsScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
              } else if (index == 4) {
                 Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (context, a1, a2) => const AccountScreen(), transitionDuration: Duration.zero, reverseTransitionDuration: Duration.zero));
              }
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24), // Minimal outline icons
          ],
        ),
      ),
    );
  }
}

// Since the FAB is now integrated directly inside the DashboardBottomNav stack to allow it to overflow upward easily while remaining floating,
// the separate ImportFab class can be left empty or removed.
class ImportFab extends StatelessWidget {
  const ImportFab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); 
  }
}
