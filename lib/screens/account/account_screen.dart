import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/session_manager.dart';
import '../dashboard/dashboard_screen.dart';
import '../../widgets/custom_page_header.dart';
import '../dashboard_widgets/bottom_nav.dart';
import '../login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final SessionManager _session = SessionManager();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F5),
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: DashboardBottomNav(selectedIndex: _session.isOwner ? 3 : 4),
      floatingActionButton: _session.isOwner
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A1028).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _showAddUserModal,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                  label: const Text(
                    'Add User',
                    style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          // Gradient header
          CustomPageHeader(
            title: 'Account Management',
            onBack: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardScreen()), (route) => false),
            bottomChild: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _session.displayName ?? 'User',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _session.email ?? '',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A853),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _session.role ?? 'User',
                          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeneralSettings(),
                  const SizedBox(height: 20),
                  if (_session.isOwner) _buildManageAccounts(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: _buildLogoutButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Maroon left-accent header bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF6A1028), width: 4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_outlined, color: Color(0xFF6A1028), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'General Settings',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', _session.displayName ?? 'N/A'),
                _buildInfoRow('Email', _session.email ?? 'N/A'),
                _buildInfoRow('Role', _session.role ?? 'N/A'),
                _buildInfoRow('Branch', _session.branchName ?? 'N/A'),
                const Divider(height: 28),
                _buildInfoRow('Theme', 'Light (Default)'),
                _buildInfoRow('System Version', '1.0.0'),
                const SizedBox(height: 12),
                const Text(
                  'About Libro Espresso',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF6B7280))),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFF9B1C3F), width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.manage_accounts_outlined, color: Color(0xFF9B1C3F), size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Manage Accounts',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF6B7280)),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF6A1028), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFFDF8F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6A1028), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6A1028)));
            var docs = snapshot.data!.docs;
            if (_searchQuery.isNotEmpty) {
              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['displayName'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();
            }

            if (docs.isEmpty) {
              return const Text('No users found.', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B7280)));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final String role = data['role'] ?? 'Manager';
                final String status = data['status'] ?? 'Active';
                final bool isActive = status.toLowerCase() == 'active';
                final bool isOwner = role.toLowerCase() == 'owner';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A1028).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person, color: Color(0xFF6A1028), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['displayName'] ?? 'No Name',
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    data['email'] ?? '',
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF6B7280)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6A1028).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.edit_outlined, color: Color(0xFF6A1028), size: 16),
                                  ),
                                  onPressed: () => _showEditUserModal(doc.id, data),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                  ),
                                  onPressed: () => _showDeleteDialog(doc.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            // Role badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOwner ? const Color(0xFF6A1028) : const Color(0xFF9B1C3F),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                role,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF2E7D32).withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? const Color(0xFF2E7D32) : Colors.red.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Branch: ${data['branch'] ?? data['branchID'] ?? ''}',
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF6B7280)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        onPressed: () {
          _session.clearSession();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (r) => false,
            );
          }
        },
        label: const Text(
          'Logout',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }



  void _showAddUserModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secAnim) => const UserFormDialog(),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim.value, sigmaY: 5 * anim.value),
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

  void _showEditUserModal(String docId, Map<String, dynamic> data) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secAnim) => UserFormDialog(docId: docId, initialData: data),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim.value, sigmaY: 5 * anim.value),
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

  void _showDeleteDialog(String docId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim, secAnim) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Delete User', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            ],
          ),
          content: const Text('Are you sure you want to delete this user? This action cannot be undone.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF6B7280))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              },
              child: const Text('Delete', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      transitionBuilder: (context, anim, secAnim, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6 * anim.value, sigmaY: 6 * anim.value),
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
}

class UserFormDialog extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;

  const UserFormDialog({super.key, this.docId, this.initialData});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String displayName, email, password, role, branch, status;
  List<String> _branchesList = [];

  @override
  void initState() {
    super.initState();
    displayName = widget.initialData?['displayName'] ?? '';
    email = widget.initialData?['email'] ?? '';
    password = widget.initialData?['password'] ?? '';
    role = widget.initialData?['role'] ?? 'Manager';
    branch = widget.initialData?['branch'] ?? widget.initialData?['branchID'] ?? '';
    status = widget.initialData?['status'] ?? 'Active';
    _fetchBranches();
  }

  Future<void> _fetchBranches() async {
    final snap = await FirebaseFirestore.instance.collection('branches').get();
    final list = snap.docs.map((d) => d['branchName'] as String).toList();
    if (list.isNotEmpty && !list.contains(branch) && branch.isEmpty) {
       branch = list.first;
    } else if (list.isNotEmpty && !list.contains(branch) && branch.isNotEmpty) {
       list.add(branch); // keep the old one just in case so it doesn't crash dropdown
    }
    setState(() {
      _branchesList = list;
    });
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final data = {
        'displayName': displayName,
        'email': email,
        'password': password,
        'role': role,
        'branch': branch,
        'branchID': branch,
        'status': status,
      };

      if (widget.docId == null) {
        // Add
        final prefix = role.toLowerCase() == 'owner' ? 'user_owner_' : 'user_mgr_';
        final snapshot = await FirebaseFirestore.instance.collection('users').get();
        int maxNum = 0;
        for (var doc in snapshot.docs) {
          if (doc.id.startsWith(prefix)) {
            final numStr = doc.id.substring(prefix.length);
            final num = int.tryParse(numStr) ?? 0;
            if (num > maxNum) maxNum = num;
          }
        }
        final newId = '$prefix${(maxNum + 1).toString().padLeft(2, '0')}';
        await FirebaseFirestore.instance.collection('users').doc(newId).set(data);
      } else {
        // Edit
        await FirebaseFirestore.instance.collection('users').doc(widget.docId).update(data);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Maroon header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Icon(widget.docId == null ? Icons.person_add_alt_1 : Icons.edit_outlined, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.docId == null ? 'Add User' : 'Edit User',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Form body
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: displayName,
                        decoration: _inputDeco('Display Name', Icons.person_outline),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        onSaved: (v) => displayName = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: email,
                        decoration: _inputDeco('Email', Icons.email_outlined),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        onSaved: (v) => email = v!,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: password,
                        decoration: _inputDeco('Password', Icons.lock_outline),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                        onSaved: (v) => password = v!,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: ['Owner', 'Manager'].contains(role) ? role : 'Manager',
                        decoration: _inputDeco('Role', Icons.badge_outlined),
                        items: ['Owner', 'Manager'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontFamily: 'Poppins')))).toList(),
                        onChanged: (v) => setState(() => role = v!),
                        onSaved: (v) => role = v!,
                      ),
                      const SizedBox(height: 12),
                      _branchesList.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: _branchesList.contains(branch) ? branch : (_branchesList.isNotEmpty ? _branchesList.first : null),
                              decoration: _inputDeco('Branch', Icons.store_outlined),
                              items: _branchesList.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontFamily: 'Poppins')))).toList(),
                              onChanged: (v) => setState(() => branch = v!),
                              onSaved: (v) => branch = v!,
                            ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: ['Active', 'Inactive'].contains(status) ? status : 'Active',
                        decoration: _inputDeco('Status', Icons.toggle_on_outlined),
                        items: ['Active', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: 'Poppins')))).toList(),
                        onChanged: (v) => setState(() => status = v!),
                        onSaved: (v) => status = v!,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF6B7280))),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6A1028), Color(0xFF9B1C3F)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _saveUser,
                              child: const Text('Save', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF6B7280)),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF6A1028), size: 18) : null,
      filled: true,
      fillColor: const Color(0xFFFDF8F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6A1028), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
