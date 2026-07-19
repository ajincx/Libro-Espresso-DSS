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

// ─── Helpers ──────────────────────────────────────────────────────────────────
Color _reasonColor(String? reason) {
  switch (reason) {
    case 'Spoilage':   return const Color(0xFFEA580C); // orange
    case 'Wastage':    return const Color(0xFFD97706); // amber
    case 'Pilferage':  return const Color(0xFFDC2626); // red
    default:           return const Color(0xFF6B7280); // grey (Count Error / other)
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class ShrinkagesScreen extends StatefulWidget {
  const ShrinkagesScreen({super.key});

  @override
  State<ShrinkagesScreen> createState() => _ShrinkagesScreenState();
}

class _ShrinkagesScreenState extends State<ShrinkagesScreen> {
  String _searchQuery = '';
  String _selectedReason = 'All';
  String _selectedStatus = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  final SessionManager _session = SessionManager();

  void _showDetails(Map<String, dynamic> item, String docId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secAnim) => _ShrinkageDetailsModal(
          item: item,
          docId: docId,
          isOwner: _session.isOwner,
          userId: _session.userId ?? 'Admin'),
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

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: _kPrimary),
            ),
            child: child!,
          );
        });
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
      });
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Gradient Header ────────────────────────────────────────────────
          CustomPageHeader(
            title: 'Shrinkages',
            onBack: () => Navigator.pop(context),
            bottomChild: Text('Monitor all recorded inventory variances.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _session.isOwner
                  ? FirebaseFirestore.instance
                      .collection('shrinkage')
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('shrinkage')
                      .where('recordedBy', isEqualTo: _session.userId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: GoogleFonts.poppins()));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: _kPrimary));
                }

                var docs = snapshot.data!.docs.map((e) {
                  final data = e.data() as Map<String, dynamic>;
                  data['docId'] = e.id;
                  return data;
                }).toList();

                if (!_session.isOwner) {
                  docs.sort((a, b) {
                    Timestamp tA = a['timestamp'] ?? Timestamp.now();
                    Timestamp tB = b['timestamp'] ?? Timestamp.now();
                    return tB.compareTo(tA);
                  });
                }

                // Filters
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final name =
                        (d['ingredientName'] ?? '').toString().toLowerCase();
                    final invId =
                        (d['inventoryID'] ?? '').toString().toLowerCase();
                    final shrinkId =
                        (d['shrinkageID'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery.toLowerCase()) ||
                        invId.contains(_searchQuery.toLowerCase()) ||
                        shrinkId.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                if (_selectedReason != 'All') {
                  docs = docs.where((d) => d['reason'] == _selectedReason).toList();
                }

                if (_selectedStatus != 'All') {
                  docs = docs
                      .where(
                          (d) => (d['status'] ?? 'Pending') == _selectedStatus)
                      .toList();
                }

                if (_startDate != null && _endDate != null) {
                  docs = docs.where((d) {
                    if (d['timestamp'] == null) return false;
                    final dt = (d['timestamp'] as Timestamp).toDate();
                    return dt.isAfter(_startDate!) && dt.isBefore(_endDate!);
                  }).toList();
                }

                // KPIs
                int totalRecords = docs.length;
                int pending =
                    docs.where((d) => (d['status'] ?? 'Pending') == 'Pending').length;
                int reviewed = docs.where((d) => d['status'] == 'Reviewed').length;
                double totalLoss = 0.0;
                for (var d in docs) {
                  totalLoss += (d['variance'] as num? ?? 0.0).abs();
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          children: [
                            // KPIs
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildKpiCard('Total Records',
                                      totalRecords.toString(), _kPrimary,
                                      Icons.list_alt_rounded),
                                  const SizedBox(width: 12),
                                  _buildKpiCard('Total Variance',
                                      totalLoss.toStringAsFixed(0),
                                      const Color(0xFFDC2626),
                                      Icons.trending_down_rounded),
                                  const SizedBox(width: 12),
                                  _buildKpiCard('Pending',
                                      pending.toString(),
                                      const Color(0xFFD97706),
                                      Icons.hourglass_bottom_rounded),
                                  const SizedBox(width: 12),
                                  _buildKpiCard('Reviewed',
                                      reviewed.toString(),
                                      const Color(0xFF16A34A),
                                      Icons.check_circle_outline_rounded),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Search and Date Filter
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: _kTextPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'Search shrinkages...',
                                      hintStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade400),
                                      prefixIcon: Icon(Icons.search,
                                          color: Colors.grey.shade400),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade200)),
                                      focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          borderSide: const BorderSide(
                                              color: _kPrimary, width: 1.8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _iconAction(
                                    icon: Icons.date_range,
                                    onTap: _pickDateRange),
                                if (_startDate != null) ...[
                                  const SizedBox(width: 8),
                                  _iconAction(
                                      icon: Icons.clear,
                                      onTap: _clearDateRange,
                                      color: Colors.red.shade400),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Filters
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterDropdown(
                                      'Reason',
                                      ['All', 'Spoilage', 'Wastage', 'Pilferage'],
                                      _selectedReason,
                                      (v) => setState(
                                          () => _selectedReason = v!)),
                                  const SizedBox(width: 10),
                                  _buildFilterDropdown(
                                      'Status',
                                      ['All', 'Pending', 'Reviewed'],
                                      _selectedStatus,
                                      (v) => setState(
                                          () => _selectedStatus = v!)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                    if (docs.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('No shrinkage records available.',
                                  style: GoogleFonts.poppins(
                                      color: _kTextSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final item = docs[index];
                              return _buildShrinkageCard(item);
                            },
                            childCount: docs.length,
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconAction(
      {required IconData icon,
      required VoidCallback onTap,
      Color? color}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ]),
          child: Icon(icon, color: color ?? _kPrimary, size: 20),
        ),
      );

  Widget _buildKpiCard(
      String title, String value, Color accentColor, IconData icon) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accentColor)),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: _kTextSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String current,
      void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: _kTextSecondary)),
          DropdownButton<String>(
            value: current,
            items: items
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary))))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(Icons.expand_more,
                color: _kPrimary, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildShrinkageCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'Pending';
    final reason = item['reason'] as String?;
    final dateStr = item['timestamp'] != null
        ? DateFormat('MMM dd, yyyy · hh:mm a')
            .format((item['timestamp'] as Timestamp).toDate())
        : 'Unknown Date';
    final isPending = status == 'Pending';
    final rColor = _reasonColor(reason);
    final statusColor =
        isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A);
    final variance = (item['variance'] ?? 0) as num;

    return GestureDetector(
      onTap: () => _showDetails(item, item['docId']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: name + status pill
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: _kPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['ingredientName'] ?? 'Unknown',
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _kTextPrimary)),
                        const SizedBox(height: 2),
                        Text('ID: ${item['inventoryID'] ?? ''}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _kTextSecondary)),
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
                    child: Text(status,
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 14),
              // Stats row
              Row(
                children: [
                  Expanded(
                      child: _buildCardStat('Expected',
                          '${item['expectedStock'] ?? 0} ${item['unit'] ?? ''}')),
                  Expanded(
                      child: _buildCardStat('Actual',
                          '${item['actualStock'] ?? 0} ${item['unit'] ?? ''}')),
                  Expanded(
                      child: _buildCardStat(
                          'Variance',
                          '${variance < 0 ? '' : '+'}$variance ${item['unit'] ?? ''}',
                          color: variance < 0
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A))),
                ],
              ),
              const SizedBox(height: 14),
              // Bottom row: reason pill + date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Reason pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: rColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: rColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(reason ?? 'Unknown',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: rColor)),
                      ],
                    ),
                  ),
                  Text(dateStr,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 11, color: _kTextSecondary)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color ?? _kTextPrimary)),
      ],
    );
  }
}

// ─── Shrinkage Details Modal ──────────────────────────────────────────────────
class _ShrinkageDetailsModal extends StatefulWidget {
  final Map<String, dynamic> item;
  final String docId;
  final bool isOwner;
  final String userId;

  const _ShrinkageDetailsModal(
      {required this.item,
      required this.docId,
      required this.isOwner,
      required this.userId});

  @override
  State<_ShrinkageDetailsModal> createState() =>
      _ShrinkageDetailsModalState();
}

class _ShrinkageDetailsModalState extends State<_ShrinkageDetailsModal> {
  bool _isLoading = false;

  void _markAsReviewed() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('shrinkage')
          .doc(widget.docId)
          .update({
        'status': 'Reviewed',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': widget.userId,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Marked as Reviewed', style: GoogleFonts.poppins()),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red));
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.item['status'] ?? 'Pending';
    final isPending = status == 'Pending';
    final reason = widget.item['reason'] as String?;
    final rColor = _reasonColor(reason);
    final statusColor =
        isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A);
    final variance = (widget.item['variance'] ?? 0) as num;

    final dateStr = widget.item['timestamp'] != null
        ? DateFormat('MMMM dd, yyyy - hh:mm a')
            .format((widget.item['timestamp'] as Timestamp).toDate())
        : 'Unknown';

    String reviewedStr = '';
    if (!isPending && widget.item['reviewedAt'] != null) {
      reviewedStr =
          'Reviewed on ${DateFormat('MMM dd, yyyy').format((widget.item['reviewedAt'] as Timestamp).toDate())}';
    }

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 30, offset: Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimary, _kSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Variance Details',
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
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Reason + Status band
              Container(
                color: _kBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    // Reason pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: rColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                                color: rColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(reason ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: rColor)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100)),
                      child: Text(status,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor)),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow('Ingredient', widget.item['ingredientName'] ?? ''),
                    const SizedBox(height: 10),
                    _buildRow('Inventory ID', widget.item['inventoryID'] ?? ''),
                    const SizedBox(height: 10),
                    _buildRow('Date Recorded', dateStr),
                    const SizedBox(height: 10),
                    _buildRow(
                        'Recorded By', widget.item['recordedBy'] ?? 'Unknown'),
                    Divider(height: 28, color: Colors.grey.shade100),
                    // Variance summary box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        children: [
                          _buildVarianceRow('Expected Stock',
                              '${widget.item['expectedStock'] ?? 0} ${widget.item['unit']}',
                              _kTextPrimary),
                          Divider(
                              height: 16, color: Colors.grey.shade200),
                          _buildVarianceRow('Actual Stock',
                              '${widget.item['actualStock'] ?? 0} ${widget.item['unit']}',
                              _kTextPrimary),
                          Divider(
                              height: 16, color: Colors.grey.shade200),
                          _buildVarianceRow(
                              'Variance',
                              '${variance < 0 ? '' : '+'}$variance ${widget.item['unit']}',
                              variance < 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A)),
                        ],
                      ),
                    ),

                    if (reviewedStr.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              size: 14,
                              color: Colors.green.shade600),
                          const SizedBox(width: 6),
                          Text(reviewedStr,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ],

                    if (widget.isOwner && isPending) ...[
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _isLoading ? null : _markAsReviewed,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF16A34A),
                              Color(0xFF22C55E)
                            ]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2))
                                  : const Icon(Icons.check_circle,
                                      color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  _isLoading
                                      ? 'Processing...'
                                      : 'Mark as Reviewed',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            flex: 2,
            child: Text(label,
                style:
                    GoogleFonts.poppins(color: _kTextSecondary, fontSize: 13))),
        Expanded(
            flex: 3,
            child: Text(value,
                style: GoogleFonts.poppins(
                    color: color ?? _kTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildVarianceRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                color: _kTextSecondary, fontSize: 13)),
        Text(value,
            style: GoogleFonts.poppins(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }
}

