// ignore_for_file: avoid_print, deprecated_member_use, curly_braces_in_flow_control_structures, library_prefixes, use_build_context_synchronously, library_private_types_in_public_api
import 'package:flutter/material.dart';
import '../cogs/cogs_screen.dart';
import '../inventory/inventory_screen.dart';
import '../shrinkages/shrinkages_screen.dart';
import '../forecasting/forecasting_screen.dart';

class QuickAccess extends StatelessWidget {
  const QuickAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmall = constraints.maxWidth <= 375;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: isSmall ? 12 : 16,
                crossAxisSpacing: isSmall ? 12 : 16,
                childAspectRatio: isSmall ? 1.4 : 1.6,
                children: [
                  _HoverCard(
                    title: 'Inventory', 
                    subtitle: 'Manage stock', 
                    icon: Icons.inventory_2_rounded, 
                    color: const Color(0xFF1E3A8A),
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
                    },
                  ),
                  _HoverCard(
                    title: 'COGS', 
                    subtitle: 'Cost analysis', 
                    icon: Icons.analytics_rounded, 
                    color: const Color(0xFFC89B3C),
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const CogsScreen()));
                    },
                  ),
                  _HoverCard(
                    title: 'Shrinkage', 
                    subtitle: 'Loss reports', 
                    icon: Icons.trending_down_rounded, 
                    color: const Color(0xFFE11D48),
                    onTap: () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => const ShrinkagesScreen()));
                    },
                  ),
                  _HoverCard(
                    title: 'Forecast', 
                    subtitle: 'AI Predictions', 
                    icon: Icons.auto_awesome, 
                    color: const Color(0xFF047857),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ForecastingScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }
}

class _HoverCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HoverCard({required this.title, required this.subtitle, required this.icon, required this.color, this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
          border: Border.all(color: widget.color.withValues(alpha: 0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap ?? () {},
            splashColor: widget.color.withValues(alpha: 0.1),
            highlightColor: widget.color.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Poppins')),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(widget.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'Poppins')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
