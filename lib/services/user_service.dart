import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class UserService extends FirestoreService {
  UserService({super.firestore});

  // Create or Update User Document
  Future<void> createUser(UserModel user) async {
    try {
      await users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error creating user: \$e');
    }
  }

  // Get User Document by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await users.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user: \$e');
    }
  }

  // Stream User Data
  Stream<UserModel?> streamUser(String uid) {
    return users.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Stream all Users (Owner view)
  Stream<List<UserModel>> streamAllUsers() {
    return users.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Stream Users by Branch (if needed)
  Stream<List<UserModel>> streamBranchUsers(String branchId) {
    return users.where('branchID', isEqualTo: branchId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Update User specific fields
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await users.doc(uid).update(data);
    } catch (e) {
      throw Exception('Error updating user: \$e');
    }
  }

  // Delete User
  Future<void> deleteUser(String uid) async {
    try {
      await users.doc(uid).delete();
    } catch (e) {
      throw Exception('Error deleting user: \$e');
    }
  }
}
