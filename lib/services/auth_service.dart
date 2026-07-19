import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/session_manager.dart';

// Handles user authentication with Firestore.
class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Validates user credentials during login.
  static Future<void> signIn(String email, String password) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Invalid email or password.');
    }

    final userDoc = querySnapshot.docs.first;
    final userData = userDoc.data();

    if (userData['password'] != password) {
      throw Exception('Invalid email or password.');
    }

    if ((userData['status']?.toString().toLowerCase() ?? '') != 'active') {
      throw Exception('Account is inactive.');
    }

    SessionManager().setSession(
      id: userDoc.id,
      name: userData['displayName'] ?? 'Unknown',
      mail: userData['email'] ?? email,
      userRole: userData['role'] ?? 'manager',
      branchId: userData['branchID'],
    );
  }

  // Clears the current user session on sign out.
  static void signOut() {
    SessionManager().clearSession();
  }
}
