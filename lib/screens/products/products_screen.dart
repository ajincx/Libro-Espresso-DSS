import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_page_header.dart';
import '../dashboard_widgets/bottom_nav.dart';
import '../dashboard/dashboard_screen.dart';

// -----------------------------------------------------------------------------
// PRODUCTS LIST SCREEN
// -----------------------------------------------------------------------------

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All Products';
  
  final List<String> _categories = [
    'All Products',
    'Coffee',
    'Non-Coffee',
    'Pastries',
    'Meals',
    'Desserts'
  ];

  void _navigateToDetails(Map<String, dynamic> product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _navigateToAdd() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const Center(
          child: AddEditProductDialog(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
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
      backgroundColor: const Color(0xFFFDF8F5),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF6A1028).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _navigateToAdd,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('Add Product', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6A1028)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
          }
          
          final docs = snapshot.data?.docs ?? [];
          List<Map<String, dynamic>> allProducts = docs.map((d) => d.data() as Map<String, dynamic>).toList();
          final int activeCount = allProducts.where((p) => (p['status']?.toString() ?? '').toLowerCase() == 'active').length;

          List<Map<String, dynamic>> products = List.from(allProducts);
          
          if (_selectedCategory != 'All Products') {
            products = products.where((p) => (p['category']?.toString() ?? '') == _selectedCategory).toList();
          }
          
          if (_searchQuery.isNotEmpty) {
            products = products.where((p) {
              final name = (p['productName'] ?? '').toString().toLowerCase();
              final cat = (p['category'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) || cat.contains(_searchQuery);
            }).toList();
          }

          return Column(
            children: [
              CustomPageHeader(
                title: 'Products',
                onBack: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (route) => false),
                bottomChild: Text(
                  'Menu and Recipes',
                  style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                ),
              ),
              // Search & Active Counter Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: TextField(
                          style: GoogleFonts.poppins(),
                          decoration: InputDecoration(
                            hintText: 'Search products by name or category...',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF6A1028)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase().trim();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '$activeCount Active',
                            style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
              
              // Category Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
                  child: SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF6A1028) : Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF6A1028) : const Color(0xFF6A1028).withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: const Color(0xFF6A1028).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: () => setState(() => _selectedCategory = category),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                                  child: Center(
                                    child: Text(
                                      category,
                                      style: GoogleFonts.poppins(
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        fontSize: 12,
                                        color: isSelected ? Colors.white : const Color(0xFF6A1028),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              // Product List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                sliver: products.isEmpty 
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16),
                                ],
                              ),
                              child: Icon(Icons.inventory_2_outlined, size: 64, color: const Color(0xFF6A1028).withOpacity(0.2)),
                            ),
                            const SizedBox(height: 24),
                            Text('No products found', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            const SizedBox(height: 8),
                            Text('Try adjusting your search or filters.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];
                          
                          final String productId = product['productID']?.toString() ?? 'N/A';
                          final String name = product['productName']?.toString() ?? 'Unknown';
                          final String category = product['category']?.toString() ?? 'Other';
                          final double price = double.tryParse(product['sellingPrice']?.toString() ?? '0') ?? 0;
                          final double cost = double.tryParse(product['cost']?.toString() ?? '0') ?? 0;
                          final String imageUrl = product['imageUrl']?.toString() ?? '';
                          final String status = product['status']?.toString() ?? 'Unknown';
                          final double grossProfit = price - cost;
                          final bool isActive = status.toLowerCase() == 'active';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _navigateToDetails(product),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Image
                                      Opacity(
                                        opacity: isActive ? 1.0 : 0.6,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (ctx, err, stack) => _buildPlaceholder(100, 100),
                                                )
                                              : _buildPlaceholder(100, 100),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Product Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? Colors.black87 : Colors.grey.shade600),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'ID: $productId',
                                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade500),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isActive ? const Color(0xFF6A1028).withOpacity(0.09) : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(100),
                                                    border: Border.all(
                                                      color: isActive ? const Color(0xFF6A1028).withOpacity(0.25) : Colors.grey.shade300,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    category,
                                                    style: GoogleFonts.poppins(fontSize: 10, color: isActive ? const Color(0xFF6A1028) : Colors.grey.shade600, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Price', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                                    Text('₱${price.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: isActive ? const Color(0xFF6A1028) : Colors.grey)),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Cost', style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
                                                    Text('₱${cost.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: isActive ? Colors.black54 : Colors.grey)),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: isActive ? Colors.green.withOpacity(0.08) : Colors.grey.shade100,
                                                    borderRadius: BorderRadius.circular(100),
                                                    border: Border.all(
                                                      color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.shade300,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        isActive ? Icons.trending_up : Icons.power_settings_new,
                                                        size: 11,
                                                        color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isActive ? '₱${grossProfit.toStringAsFixed(0)}' : 'Inactive',
                                                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.green.shade700 : Colors.grey.shade600),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
              ),
                  ],
                ),
              ),
            ],
          );
        }
      ),
      extendBody: true,
      bottomNavigationBar: const DashboardBottomNav(selectedIndex: 1),
    );
  }

  Widget _buildPlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEE8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Icon(Icons.image_outlined, color: const Color(0xFF6A1028).withOpacity(0.2), size: 32)),
    );
  }
}

// -----------------------------------------------------------------------------
// PRODUCT DETAILS SCREEN
// -----------------------------------------------------------------------------

class ProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductDetailsScreen({super.key, required this.product});

  void _navigateToEdit(BuildContext context, Map<String, dynamic> latestProduct) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: AddEditProductDialog(product: latestProduct),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * animation.value, sigmaY: 4 * animation.value),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleStatus(BuildContext context, Map<String, dynamic> currentData) async {
    final String currentStatus = currentData['status']?.toString() ?? 'Unknown';
    final bool isActive = currentStatus.toLowerCase() == 'active';
    final String newStatus = isActive ? 'Inactive' : 'Active';
    final String productId = currentData['productID'];
    
    try {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
      }
    }
  }

  void _confirmDelete(BuildContext context, String productId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secAnim) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this product? This action cannot be undone.', style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('products').doc(productId).delete();
                if (context.mounted) {
                  Navigator.pop(context); // Go back to list
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String productId = product['productID']?.toString() ?? 'N/A';
    
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.25), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade600.withOpacity(0.9), shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
            ),
            tooltip: 'Delete Product',
            onPressed: () => _confirmDelete(context, productId),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('products').doc(productId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.poppins()));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF6A1028)));
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Product no longer exists.', style: GoogleFonts.poppins()));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['productName']?.toString() ?? 'Unknown';
          final String category = data['category']?.toString() ?? 'Other';
          final double price = double.tryParse(data['sellingPrice']?.toString() ?? '0') ?? 0;
          final double cost = double.tryParse(data['cost']?.toString() ?? '0') ?? 0;
          final String imageUrl = data['imageUrl']?.toString() ?? '';
          final String status = data['status']?.toString() ?? 'Unknown';
          final double grossProfit = price - cost;
          final bool isActive = status.toLowerCase() == 'active';
          
          final List<dynamic> recipe = data['recipe'] is List ? data['recipe'] : [];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Header
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Icon(Icons.image_outlined, size: 80, color: Colors.grey.shade400),
                        )
                      : Icon(Icons.image_outlined, size: 80, color: Colors.grey.shade400),
                ),
                
                // Content
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDF8F5),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937), height: 1.2),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'ID: $productId',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6A1028).withOpacity(0.09),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: const Color(0xFF6A1028).withOpacity(0.25), width: 1),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(color: const Color(0xFF6A1028), fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Metrics Row
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricCol('Selling Price', '₱${price.toStringAsFixed(2)}', const Color(0xFF6A1028)),
                                Container(width: 1, height: 40, color: Colors.grey.shade200),
                                _buildMetricCol('Cost', '₱${cost.toStringAsFixed(2)}', Colors.grey.shade600),
                                Container(width: 1, height: 40, color: Colors.grey.shade200),
                                _buildMetricCol('Gross Profit', '₱${grossProfit.toStringAsFixed(2)}', const Color(0xFF2E7D32)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _navigateToEdit(context, data),
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  label: Text('Edit', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6A1028),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _toggleStatus(context, data),
                                  icon: Icon(isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  label: Text(isActive ? 'Deactivate' : 'Activate', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isActive ? Colors.grey.shade200 : Colors.green.shade50,
                                    foregroundColor: isActive ? Colors.black87 : Colors.green.shade700,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          Text('Status', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: isActive ? Colors.green.withOpacity(0.35) : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(isActive ? Icons.check_circle : Icons.cancel, size: 15, color: isActive ? Colors.green.shade700 : Colors.grey.shade600),
                                    const SizedBox(width: 8),
                                    Text(status, style: GoogleFonts.poppins(fontSize: 13, color: isActive ? Colors.green.shade700 : Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 40),
                          Text('Complete Recipe', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                          const SizedBox(height: 16),
                          
                          if (recipe.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.restaurant_menu, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text('No recipe added yet', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recipe.length,
                                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100, indent: 64),
                                itemBuilder: (context, index) {
                                  final ing = recipe[index];
                                  final ingName = ing['ingredientName']?.toString() ?? 'Unknown';
                                  final qty = ing['quantity']?.toString() ?? '0';
                                  final unit = ing['unit']?.toString() ?? '';
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6A1028).withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.eco_outlined, color: Color(0xFF6A1028), size: 20),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(ingName, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Text('$qty $unit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
  
  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ADD / EDIT PRODUCT DIALOG MODAL
// -----------------------------------------------------------------------------

class _RecipeItemData {
  TextEditingController nameCtrl;
  TextEditingController qtyCtrl;
  TextEditingController unitCtrl;

  _RecipeItemData({String name = '', String qty = '', String unit = ''})
      : nameCtrl = TextEditingController(text: name),
        qtyCtrl = TextEditingController(text: qty),
        unitCtrl = TextEditingController(text: unit);

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    unitCtrl.dispose();
  }
}

class AddEditProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  const AddEditProductDialog({super.key, this.product});

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _categoryCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _imageCtrl;
  
  final List<_RecipeItemData> _recipeRows = [];
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _categoryCtrl = TextEditingController(text: p?['category']?.toString() ?? '');
    _nameCtrl = TextEditingController(text: p?['productName']?.toString() ?? '');
    _priceCtrl = TextEditingController(text: p?['sellingPrice']?.toString() ?? '');
    _costCtrl = TextEditingController(text: p?['cost']?.toString() ?? '');
    _imageCtrl = TextEditingController(text: p?['imageUrl']?.toString() ?? '');
    
    if (p != null && p['recipe'] is List) {
      final List<dynamic> rec = p['recipe'];
      for (var r in rec) {
        _recipeRows.add(_RecipeItemData(
          name: r['ingredientName']?.toString() ?? '',
          qty: r['quantity']?.toString() ?? '',
          unit: r['unit']?.toString() ?? '',
        ));
      }
    }
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _imageCtrl.dispose();
    for (var r in _recipeRows) {
      r.dispose();
    }
    super.dispose();
  }
  
  void _markChanged() {
    if (!_hasUnsavedChanges) _hasUnsavedChanges = true;
  }

  void _addRecipeRow() {
    setState(() {
      _recipeRows.add(_RecipeItemData());
      _markChanged();
    });
  }

  void _removeRecipeRow(int index) {
    setState(() {
      _recipeRows[index].dispose();
      _recipeRows.removeAt(index);
      _markChanged();
    });
  }

  Future<String> _getOrCreateInventoryId(String ingredientName) async {
    final query = await FirebaseFirestore.instance
        .collection('inventory')
        .where('ingredientName', isEqualTo: ingredientName)
        .limit(1)
        .get();
        
    if (query.docs.isNotEmpty) {
      return query.docs.first['inventoryID'] ?? query.docs.first.id;
    }
    
    final invDocs = await FirebaseFirestore.instance.collection('inventory').get();
    int maxNum = 0;
    for (var doc in invDocs.docs) {
      final id = doc.id;
      if (id.startsWith('inv_')) {
        final numStr = id.substring(4);
        final num = int.tryParse(numStr);
        if (num != null && num > maxNum) maxNum = num;
      }
    }
    final newInvId = 'inv_${(maxNum + 1).toString().padLeft(2, '0')}';
    
    await FirebaseFirestore.instance.collection('inventory').doc(newInvId).set({
      'inventoryID': newInvId,
      'ingredientName': ingredientName,
      'category': 'Others',
      'stock': 0.0,
      'expectedStock': 0.0,
      'unit': 'unknown',
      'minimumStock': 10.0,
      'status': 'Out of Stock',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return newInvId;
  }

  Future<String> _generateProductId() async {
    final prodDocs = await FirebaseFirestore.instance.collection('products').get();
    int maxNum = 0;
    for (var doc in prodDocs.docs) {
      final id = doc.id;
      if (id.startsWith('prod_')) {
        final numStr = id.substring(5);
        final num = int.tryParse(numStr);
        if (num != null && num > maxNum) maxNum = num;
      }
    }
    return 'prod_${(maxNum + 1).toString().padLeft(2, '0')}';
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_recipeRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recipe must have at least one ingredient.', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
      return;
    }
    
    for (var r in _recipeRows) {
      if (r.nameCtrl.text.trim().isEmpty || r.qtyCtrl.text.trim().isEmpty || r.unitCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All ingredient fields must be filled.', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> finalRecipe = [];
      for (var r in _recipeRows) {
        final name = r.nameCtrl.text.trim();
        final qty = double.tryParse(r.qtyCtrl.text.trim()) ?? 0.0;
        final unit = r.unitCtrl.text.trim();
        
        final invId = await _getOrCreateInventoryId(name);
        
        finalRecipe.add({
          'inventoryID': invId,
          'ingredientName': name,
          'quantity': qty,
          'unit': unit,
        });
      }
      
      final bool isEdit = widget.product != null;
      final String productId = isEdit ? widget.product!['productID'] : await _generateProductId();
      
      final docData = {
        'productID': productId,
        'productName': _nameCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'sellingPrice': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'cost': double.tryParse(_costCtrl.text.trim()) ?? 0.0,
        'imageUrl': _imageCtrl.text.trim(),
        'status': isEdit ? widget.product!['status'] : 'Active',
        'recipe': finalRecipe,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (!isEdit) {
        docData['createdAt'] = FieldValue.serverTimestamp();
      }
      
      await FirebaseFirestore.instance.collection('products').doc(productId).set(docData, SetOptions(merge: true));
      
      if (mounted) {
        _hasUnsavedChanges = false;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Product updated' : 'Product added', style: GoogleFonts.poppins()), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e', style: GoogleFonts.poppins()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFFDF8F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6A1028), width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDense: true,
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secAnim) => AlertDialog(
        title: Text('Discard Changes?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('You have unsaved changes. Are you sure you want to discard them?', style: GoogleFonts.poppins()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Discard', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4 * anim.value, sigmaY: 4 * anim.value),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF8F5),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 20)),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Product' : 'New Product',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () async {
                        if (await _onWillPop()) {
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scrollable Form Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A1028)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          onChanged: _markChanged,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Basic Information', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _categoryCtrl,
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: _inputDecor('Category (e.g. Coffee)'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameCtrl,
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: _inputDecor('Product Name'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceCtrl,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecor('Selling Price (₱)'),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Required';
                                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _costCtrl,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecor('Cost (₱)'),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Required';
                                        if (double.tryParse(val.trim()) == null) return 'Invalid';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _imageCtrl,
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: _inputDecor('Image URL'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                              ),
                              
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Recipe Ingredients', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937))),
                                  TextButton.icon(
                                    onPressed: _addRecipeRow,
                                    icon: const Icon(Icons.add_circle_outline, size: 18),
                                    label: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF6A1028),
                                      backgroundColor: const Color(0xFF6A1028).withOpacity(0.05),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              if (_recipeRows.isEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF8F5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.kitchen_outlined, size: 32, color: const Color(0xFF6A1028).withOpacity(0.3)),
                                      const SizedBox(height: 8),
                                      Text('No ingredients added', style: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _recipeRows.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final r = _recipeRows[index];
                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDF8F5),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE5E7EB)),
                                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 8)],
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 4,
                                            child: TextFormField(
                                              controller: r.nameCtrl,
                                              style: GoogleFonts.poppins(fontSize: 13),
                                              decoration: InputDecoration(
                                                labelText: 'Ingredient',
                                                labelStyle: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280)),
                                                isDense: true,
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6A1028), width: 1.5)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: r.qtyCtrl,
                                              style: GoogleFonts.poppins(fontSize: 13),
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                labelText: 'Qty',
                                                labelStyle: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280)),
                                                isDense: true,
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6A1028), width: 1.5)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              controller: r.unitCtrl,
                                              style: GoogleFonts.poppins(fontSize: 13),
                                              decoration: InputDecoration(
                                                labelText: 'Unit',
                                                labelStyle: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF6B7280)),
                                                isDense: true,
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF6A1028), width: 1.5)),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () => _removeRecipeRow(index),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                                              child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
              
              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF8F5),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          if (await _onWillPop()) {
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1028),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isLoading ? null : _saveProduct,
                        child: Text(isEdit ? 'Save Changes' : 'Create Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ),
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
