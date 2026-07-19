import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/session_manager.dart';
import '../../widgets/custom_page_header.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kPrimary       = Color(0xFF6A1028);
const _kSecondary     = Color(0xFF9B1C3F);
const _kBg            = Color(0xFFFDF8F5);
const _kTextPrimary   = Color(0xFF1F2937);
const _kTextSecondary = Color(0xFF6B7280);

// ─── Shared helpers ───────────────────────────────────────────────────────────
InputDecoration _filledInput({
  required String label,
  bool enabled = true,
}) =>
    InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: _kTextSecondary, fontSize: 13),
      filled: true,
      fillColor: enabled ? Colors.white : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPrimary, width: 1.8)),
    );

BoxDecoration _dialogCardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 10))
      ],
    );

Widget _dialogHeader(String title, BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration:
                  const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All', 'Coffee', 'Dairy', 'Syrups', 'Powders', 'Tea', 'Pastry', 'Food', 'Others'
  ];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animController.forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _openDetailsModal(Map<String, dynamic> item, String docId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secAnim) =>
          _InventoryDetailsModal(item: item, docId: docId),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inventory').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kPrimary));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading inventory', style: GoogleFonts.poppins()));
          }

          final docs = snapshot.data?.docs ?? [];
          List<Map<String, dynamic>> allItems = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            data['docId'] = d.id;
            return data;
          }).toList();

          int totalItems = allItems.length;
          int lowStock = allItems.where((i) => i['status'] == 'Low Stock').length;
          int outOfStock = allItems.where((i) => i['status'] == 'Out of Stock').length;

          // Apply filters
          List<Map<String, dynamic>> filteredItems = allItems.where((item) {
            final name = (item['ingredientName'] ?? '').toString().toLowerCase();
            final matchesSearch = name.contains(_searchQuery.toLowerCase());
            final matchesCategory =
                _selectedCategory == 'All' || item['category'] == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              _buildHeader(totalItems, lowStock, outOfStock),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: GoogleFonts.poppins(fontSize: 14, color: _kTextPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search ingredients...',
                            hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: _kPrimary, width: 1.8)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: _kTextSecondary, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 42,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _kPrimary : Colors.white,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                        color: isSelected
                                            ? _kPrimary
                                            : Colors.grey.shade200),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: _kPrimary.withValues(alpha: 0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3))
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    cat,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected ? Colors.white : _kTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    if (filteredItems.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('No items found',
                                  style: GoogleFonts.poppins(
                                      color: _kTextSecondary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text('Try adjusting your filters',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey.shade400, fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = filteredItems[index];
                              return _buildInventoryCard(item);
                            },
                            childCount: filteredItems.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int total, int low, int out) {
    return CustomPageHeader(
      title: 'Inventory',
      onBack: () => Navigator.pop(context),
      bottomChild: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage ingredients and stock levels',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildKPI('Total Items', total.toString(),
                      Icons.inventory_2, Colors.white.withValues(alpha: 0.2))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildKPI('Low Stock', low.toString(),
                      Icons.warning_amber_rounded,
                      Colors.orange.withValues(alpha: 0.3))),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildKPI('Out of Stock', out.toString(),
                      Icons.error_outline, Colors.red.withValues(alpha: 0.4))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPI(String label, String value, IconData icon, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final expectedStock = (item['expectedStock'] ?? item['stock'] ?? 0.0) as num;
    final minStock = (item['minimumStock'] ?? item['reorderLevel'] ?? 20.0) as num;

    String displayStatus;
    if (expectedStock <= 0) {
      displayStatus = 'Out of Stock';
    } else if (expectedStock <= minStock) {
      displayStatus = 'Low Stock';
    } else {
      displayStatus = 'In Stock';
    }

    // Status-based styling
    Color statusColor;
    Color cardTint;
    Color barColor;
    Color borderColor;
    if (displayStatus == 'In Stock') {
      statusColor = const Color(0xFF16A34A);
      cardTint = Colors.white;
      barColor = const Color(0xFF22C55E);
      borderColor = Colors.grey.shade100;
    } else if (displayStatus == 'Low Stock') {
      statusColor = const Color(0xFFD97706);
      cardTint = const Color(0xFFFFFBEB);
      barColor = const Color(0xFFF59E0B);
      borderColor = Colors.orange.shade100;
    } else {
      statusColor = const Color(0xFFDC2626);
      cardTint = const Color(0xFFFFF5F5);
      barColor = const Color(0xFFEF4444);
      borderColor = Colors.red.shade100;
    }

    // Stock level bar fill (0.0 - 1.0)
    final stock = (item['stock'] ?? 0.0) as num;
    final startingStock = stock > 0 ? stock.toDouble() : (expectedStock > 0 ? expectedStock.toDouble() : 1.0);
    final barFill = (expectedStock / startingStock).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardTint,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openDetailsModal(item, item['docId']),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.inventory_2_rounded,
                          color: _kPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['ingredientName'] ?? 'Unnamed',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _kTextPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['category'] ?? 'Category',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _kTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100)),
                      child: Text(displayStatus,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Stock bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: barFill,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${expectedStock.truncateToDouble() == expectedStock ? expectedStock.toInt() : expectedStock.toStringAsFixed(1)}',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kPrimary),
                          ),
                          TextSpan(
                            text: ' ${item['unit'] ?? ''}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _kTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Min: $minStock ${item['unit'] ?? ''}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Inventory Details Modal ──────────────────────────────────────────────────
class _InventoryDetailsModal extends StatelessWidget {
  final Map<String, dynamic> item;
  final String docId;

  const _InventoryDetailsModal({required this.item, required this.docId});

  void _showAddStockDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, secAnim) =>
          _AddStockDialog(item: item, docId: docId),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
          child: FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child)),
        );
      },
    );
  }

  void _showStockCountDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, secAnim) =>
          _StockCountDialog(item: item, docId: docId),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
          child: FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child)),
        );
      },
    );
  }

  void _showViewHistoryModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, secAnim) =>
          _ViewHistoryModal(item: item, docId: docId),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
          child: FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child)),
        );
      },
    );
  }

  void _deleteIngredient(BuildContext context) async {
    bool? confirm = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim, secAnim) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [_kPrimary, _kSecondary]),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text('Delete Ingredient?',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16)),
              ),
              content: Text(
                  'Are you sure you want to delete ${item['ingredientName']}?',
                  style: GoogleFonts.poppins(fontSize: 14)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(color: _kTextSecondary))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
        transitionBuilder: (context, anim, secAnim, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
            child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                    child: child)),
          );
        });

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('inventory')
          .doc(docId)
          .delete();
      if (context.mounted) Navigator.pop(context); // Close details modal
    }
  }

  @override
  Widget build(BuildContext context) {
    final expectedStock = (item['expectedStock'] ?? item['stock'] ?? 0.0) as num;
    final minStock = (item['minimumStock'] ?? item['reorderLevel'] ?? 20.0) as num;

    String displayStatus;
    if (expectedStock <= 0) {
      displayStatus = 'Out of Stock';
    } else if (expectedStock <= minStock) {
      displayStatus = 'Low Stock';
    } else {
      displayStatus = 'In Stock';
    }

    Color statusColor;
    Color barColor;
    if (displayStatus == 'In Stock') {
      statusColor = const Color(0xFF16A34A);
      barColor = const Color(0xFF22C55E);
    } else if (displayStatus == 'Low Stock') {
      statusColor = const Color(0xFFD97706);
      barColor = const Color(0xFFF59E0B);
    } else {
      statusColor = const Color(0xFFDC2626);
      barColor = const Color(0xFFEF4444);
    }

    String dateStr = 'Unknown';
    if (item['updatedAt'] != null) {
      dateStr = DateFormat('MMM dd, yyyy - hh:mm a')
          .format((item['updatedAt'] as Timestamp).toDate());
    }

    final stock = (item['stock'] ?? 0.0) as num;
    final startingStock = stock > 0 ? stock.toDouble() : (expectedStock > 0 ? expectedStock.toDouble() : 1.0);
    final barFill = (expectedStock / startingStock).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(24),
          decoration: _dialogCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient header
              _dialogHeader(item['ingredientName'] ?? 'Ingredient Details', context),

              // Stock level mini-banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: _kBg,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Stock Level',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _kTextSecondary)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100)),
                          child: Text(displayStatus,
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: barFill,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow('Category', item['category']?.toString() ?? 'N/A'),
                    _buildDivider(),
                    _buildDetailRow(
                        'Current Stock', '${item['stock']} ${item['unit']}'),
                    _buildDivider(),
                    _buildDetailRow('Expected Stock',
                        '${item['expectedStock'] ?? item['stock']} ${item['unit']}'),
                    _buildDivider(),
                    _buildDetailRow('Minimum Stock',
                        '${item['minimumStock']} ${item['unit']}'),
                    _buildDivider(),
                    _buildDetailRow('Last Updated', dateStr),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _primaryButton(
                            label: 'Add Stock',
                            icon: Icons.add_circle_outline,
                            onTap: () => _showAddStockDialog(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _primaryButton(
                            label: 'Count',
                            icon: Icons.fact_check_rounded,
                            onTap: () => _showStockCountDialog(context),
                            secondary: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _outlineButton(
                            label: 'History',
                            icon: Icons.history,
                            onTap: () => _showViewHistoryModal(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _outlineButton(
                            label: 'Delete',
                            icon: Icons.delete_outline,
                            onTap: () => _deleteIngredient(context),
                            danger: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 20, thickness: 0.8, color: Colors.grey.shade100);

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(color: _kTextSecondary, fontSize: 13)),
        Text(value,
            style: GoogleFonts.poppins(
                color: _kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool secondary = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: secondary
                  ? [_kSecondary, const Color(0xFFB02248)]
                  : [_kPrimary, _kSecondary],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: _kPrimary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _outlineButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: danger ? Colors.red.shade300 : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: danger ? Colors.red.shade600 : _kTextSecondary,
                  size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      color: danger ? Colors.red.shade600 : _kTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
      );
}

// ─── Add Stock Dialog ─────────────────────────────────────────────────────────
class _AddStockDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final String docId;
  const _AddStockDialog({required this.item, required this.docId});

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  final TextEditingController _addCtrl = TextEditingController();
  bool _isLoading = false;

  void _submit() async {
    final addVal = double.tryParse(_addCtrl.text.trim());
    if (addVal == null || addVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Enter a valid amount to add.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentStock = (widget.item['stock'] ?? 0.0) as num;
      final minStock = (widget.item['minimumStock'] ?? 0.0) as num;
      final newStock = currentStock + addVal;

      String status = "In Stock";
      if (newStock == 0) status = "Out of Stock";
      else if (newStock <= minStock) status = "Low Stock";

      final batch = FirebaseFirestore.instance.batch();
      final invRef =
          FirebaseFirestore.instance.collection('inventory').doc(widget.docId);
      batch.update(invRef, {
        'stock': newStock,
        'expectedStock': newStock,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final histRef =
          FirebaseFirestore.instance.collection('inventory_history').doc();
      batch.set(histRef, {
        'historyID': histRef.id,
        'inventoryID': widget.item['inventoryID'],
        'ingredientName': widget.item['ingredientName'],
        'action': 'Restocked',
        'quantityChanged': '+${addVal.toStringAsFixed(0)} ${widget.item['unit']}',
        'previousStock': currentStock,
        'newStock': newStock,
        'remarks': '',
        'timestamp': FieldValue.serverTimestamp(),
        'recordedBy': SessionManager().userId ?? 'Admin',
      });
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close add stock dialog
        Navigator.pop(context); // Close details modal to force refresh from main list
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Stock updated successfully', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          margin: const EdgeInsets.all(24),
          decoration: _dialogCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader('Add Stock', context),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item['ingredientName'] ?? '',
                        style:
                            GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: TextEditingController(
                          text:
                              '${widget.item['stock']} ${widget.item['unit']}'),
                      enabled: false,
                      style:
                          GoogleFonts.poppins(color: Colors.black54, fontSize: 14),
                      decoration: _filledInput(label: 'Current Stock', enabled: false),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _addCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.poppins(color: _kTextPrimary, fontSize: 14),
                      decoration:
                          _filledInput(label: 'Add Amount (${widget.item['unit']})'),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13)),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    color: _kTextSecondary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _submit,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_kPrimary, _kSecondary]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Save',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stock Count Dialog ───────────────────────────────────────────────────────
class _StockCountDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final String docId;
  const _StockCountDialog({required this.item, required this.docId});

  @override
  State<_StockCountDialog> createState() => _StockCountDialogState();
}

class _StockCountDialogState extends State<_StockCountDialog> {
  final TextEditingController _actualCtrl = TextEditingController();
  bool _isLoading = false;

  void _verifyStock() async {
    final actualVal = double.tryParse(_actualCtrl.text.trim());
    if (actualVal == null || actualVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Enter a valid actual stock.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red));
      return;
    }

    final expectedStock =
        (widget.item['expectedStock'] ?? widget.item['stock'] ?? 0.0) as num;

    if (actualVal == expectedStock) {
      // Stock matches
      setState(() => _isLoading = true);
      try {
        final minStock = (widget.item['minimumStock'] ?? 0.0) as num;
        String status = "In Stock";
        if (actualVal == 0) status = "Out of Stock";
        else if (actualVal <= minStock) status = "Low Stock";

        final batch = FirebaseFirestore.instance.batch();
        final invRef = FirebaseFirestore.instance
            .collection('inventory')
            .doc(widget.docId);
        batch.update(invRef, {
          'stock': actualVal,
          'expectedStock': actualVal,
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final histRef =
            FirebaseFirestore.instance.collection('inventory_history').doc();
        batch.set(histRef, {
          'historyID': histRef.id,
          'inventoryID': widget.item['inventoryID'],
          'ingredientName': widget.item['ingredientName'],
          'action': 'Stock Count',
          'quantityChanged': '0 ${widget.item['unit']}',
          'previousStock': expectedStock,
          'newStock': actualVal,
          'remarks':
              'Expected: ${expectedStock.toStringAsFixed(0)} ${widget.item['unit']}\nActual: ${actualVal.toStringAsFixed(0)} ${widget.item['unit']}\nNo Variance',
          'timestamp': FieldValue.serverTimestamp(),
          'recordedBy': SessionManager().userId ?? 'Admin',
        });
        await batch.commit();
        if (mounted) {
          Navigator.pop(context); // Close count dialog
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Stock verified successfully!', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e', style: GoogleFonts.poppins()),
              backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Variance detected
      Navigator.pop(context); // Close count dialog
      _showVarianceForm(context, expectedStock.toDouble(), actualVal.toDouble());
    }
  }

  void _showVarianceForm(BuildContext context, double expected, double actual) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim, secAnim) => _VarianceFormDialog(
          item: widget.item, docId: widget.docId, expected: expected, actual: actual),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
          child: FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                      CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                  child: child)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          margin: const EdgeInsets.all(24),
          decoration: _dialogCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader('Stock Count', context),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item['ingredientName'] ?? '',
                        style:
                            GoogleFonts.poppins(fontSize: 14, color: _kTextSecondary)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: TextEditingController(
                          text:
                              '${widget.item['expectedStock'] ?? widget.item['stock']} ${widget.item['unit']}'),
                      enabled: false,
                      style:
                          GoogleFonts.poppins(color: Colors.black54, fontSize: 14),
                      decoration:
                          _filledInput(label: 'Expected Stock', enabled: false),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _actualCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.poppins(color: _kTextPrimary, fontSize: 14),
                      decoration: _filledInput(
                          label: 'Actual Stock (${widget.item['unit']})'),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13)),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    color: _kTextSecondary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _verifyStock,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_kSecondary, Color(0xFFB02248)]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Verify',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Variance Form Dialog ─────────────────────────────────────────────────────
class _VarianceFormDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final String docId;
  final double expected;
  final double actual;

  const _VarianceFormDialog(
      {required this.item,
      required this.docId,
      required this.expected,
      required this.actual});

  @override
  State<_VarianceFormDialog> createState() => _VarianceFormDialogState();
}

class _VarianceFormDialogState extends State<_VarianceFormDialog> {
  String? _selectedReason;
  bool _isLoading = false;

  final List<String> _reasons = [
    'Spoilage',
    'Wastage',
    'Pilferage',
    'Other (Count Error)'
  ];

  void _submitVariance() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Please select a reason.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red));
      return;
    }

    if (_selectedReason == 'Other (Count Error)') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Count error detected. Please recount the inventory and enter the correct stock.',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4)));
      Navigator.pop(context); // Close variance form
      // Re-open stock count
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (ctx, anim, secAnim) =>
            _StockCountDialog(item: widget.item, docId: widget.docId),
        transitionBuilder: (context, anim, secAnim, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
            child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                    scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                    child: child)),
          );
        },
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final double variance = widget.actual - widget.expected;
      final minStock = (widget.item['minimumStock'] ?? 0.0) as num;

      String status = "In Stock";
      if (widget.actual == 0) status = "Out of Stock";
      else if (widget.actual <= minStock) status = "Low Stock";

      final shrinkQuery =
          await FirebaseFirestore.instance.collection('shrinkage').get();
      int count = shrinkQuery.docs.length + 1;
      String shrinkId = 'shrink_${count.toString().padLeft(4, '0')}';

      final batch = FirebaseFirestore.instance.batch();

      // 1. Update inventory
      final invRef =
          FirebaseFirestore.instance.collection('inventory').doc(widget.docId);
      batch.update(invRef, {
        'stock': widget.actual,
        'expectedStock': widget.actual,
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Create shrinkage record
      final shrinkRef =
          FirebaseFirestore.instance.collection('shrinkage').doc(shrinkId);
      batch.set(shrinkRef, {
        'shrinkageID': shrinkId,
        'inventoryID': widget.item['inventoryID'],
        'ingredientName': widget.item['ingredientName'],
        'expectedStock': widget.expected,
        'actualStock': widget.actual,
        'variance': variance,
        'unit': widget.item['unit'],
        'reason': _selectedReason,
        'timestamp': FieldValue.serverTimestamp(),
        'recordedBy': SessionManager().userId ?? 'Admin',
        'status': 'Pending',
        'reviewedAt': null,
        'reviewedBy': null,
      });

      // 3. Create history record
      final histRef =
          FirebaseFirestore.instance.collection('inventory_history').doc();
      batch.set(histRef, {
        'historyID': histRef.id,
        'inventoryID': widget.item['inventoryID'],
        'ingredientName': widget.item['ingredientName'],
        'action': 'Stock Count',
        'quantityChanged':
            '${variance > 0 ? '+' : ''}${variance.toStringAsFixed(0)} ${widget.item['unit']}',
        'previousStock': widget.expected,
        'newStock': widget.actual,
        'remarks':
            'Expected: ${widget.expected.toStringAsFixed(0)} ${widget.item['unit']}\nActual: ${widget.actual.toStringAsFixed(0)} ${widget.item['unit']}\nVariance: ${variance.abs().toStringAsFixed(0)} ${widget.item['unit']}\nReason: $_selectedReason',
        'timestamp': FieldValue.serverTimestamp(),
        'recordedBy': SessionManager().userId ?? 'Admin',
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close variance
        Navigator.pop(context); // Close details modal
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Shrinkage recorded and inventory updated.',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double variance = widget.actual - widget.expected;
    final bool isLoss = variance < 0;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 390),
          margin: const EdgeInsets.all(24),
          decoration: _dialogCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Orange-tinted header for variance warning
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Colors.orange.shade800, Colors.orange.shade600]),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Variance Detected',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.white24, shape: BoxShape.circle),
                        child:
                            const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A discrepancy was found in the inventory count for ${widget.item['ingredientName']}.',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: _kTextSecondary),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          _buildRow('Expected',
                              '${widget.expected} ${widget.item['unit']}',
                              _kTextPrimary),
                          Divider(color: Colors.grey.shade200),
                          _buildRow('Actual',
                              '${widget.actual} ${widget.item['unit']}',
                              _kTextPrimary),
                          Divider(color: Colors.grey.shade200),
                          _buildRow(
                              'Variance',
                              '${variance > 0 ? '+' : ''}$variance ${widget.item['unit']}',
                              isLoss
                                  ? Colors.red.shade600
                                  : Colors.green.shade600),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Reason for Variance',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Text('Select Reason',
                              style: GoogleFonts.poppins(
                                  color: _kTextSecondary, fontSize: 14)),
                          value: _selectedReason,
                          items: _reasons
                              .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r,
                                      style:
                                          GoogleFonts.poppins(fontSize: 14))))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedReason = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13)),
                            child: Text('Cancel',
                                style: GoogleFonts.poppins(
                                    color: _kTextSecondary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _submitVariance,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  Colors.orange.shade700,
                                  Colors.orange.shade500
                                ]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Confirm',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(color: _kTextSecondary, fontSize: 13)),
          Text(value,
              style: GoogleFonts.poppins(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── View History Modal ───────────────────────────────────────────────────────
class _ViewHistoryModal extends StatelessWidget {
  final Map<String, dynamic> item;
  final String docId;
  const _ViewHistoryModal({required this.item, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          margin: const EdgeInsets.all(24),
          decoration: _dialogCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogHeader('History: ${item['ingredientName'] ?? ''}', context),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('inventory_history')
                      .where('inventoryID', isEqualTo: item['inventoryID'])
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error loading history',
                              style: GoogleFonts.poppins(color: Colors.red)));
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(color: _kPrimary));
                    }

                    var docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No inventory history available.',
                              style: GoogleFonts.poppins(
                                  color: _kTextSecondary, fontSize: 14)),
                        ],
                      ));
                    }

                    // Client-side sort by timestamp to avoid composite index requirement
                    var sortedDocs = docs.toList();
                    sortedDocs.sort((a, b) {
                      Timestamp tA =
                          (a.data() as Map<String, dynamic>)['timestamp'] ??
                              Timestamp.now();
                      Timestamp tB =
                          (b.data() as Map<String, dynamic>)['timestamp'] ??
                              Timestamp.now();
                      return tB.compareTo(tA);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      itemCount: sortedDocs.length,
                      itemBuilder: (context, index) {
                        final data = sortedDocs[index].data()
                            as Map<String, dynamic>;
                        final dateStr = data['timestamp'] != null
                            ? DateFormat('MMMM dd, yyyy').format(
                                (data['timestamp'] as Timestamp).toDate())
                            : 'Unknown';
                        final action = data['action'] ?? 'Action';
                        final qtyChanged = data['quantityChanged'] ?? '';
                        final prevStock = data['previousStock'] ?? 0;
                        final newStock = data['newStock'] ?? 0;

                        final remaining = action == 'Restocked'
                            ? 'Remaining: $newStock ${item['unit']}'
                            : '$prevStock → $newStock ${item['unit']}';

                        final remarks = data['remarks'] ?? '';
                        final isLast = index == sortedDocs.length - 1;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline column
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: action == 'Restocked'
                                          ? const Color(0xFF22C55E)
                                          : _kPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Colors.grey.shade200,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(bottom: isLast ? 0 : 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(dateStr,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: _kPrimary,
                                          )),
                                      const SizedBox(height: 4),
                                      Text(action,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: _kTextPrimary,
                                          )),
                                      if (qtyChanged.isNotEmpty &&
                                          action == 'Restocked') ...[
                                        const SizedBox(height: 2),
                                        Text(qtyChanged,
                                            style: GoogleFonts.poppins(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            )),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(remaining,
                                          style: GoogleFonts.poppins(
                                            color: _kTextSecondary,
                                            fontSize: 12,
                                          )),
                                      if (remarks.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _kBg,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(remarks,
                                              style: GoogleFonts.poppins(
                                                color: _kTextSecondary,
                                                fontSize: 12,
                                              )),
                                        ),
                                      ],
                                    ],
                                  ),
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
          ),
        ),
      ),
    );
  }
}
