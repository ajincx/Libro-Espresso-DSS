import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { owner, manager }
enum UserStatus { active, inactive }

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final UserRole role;
  final String? branchID;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    this.branchID,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] == 'owner' ? UserRole.owner : UserRole.manager,
      branchID: data['branchID'],
      status: data['status'] == 'inactive' ? UserStatus.inactive : UserStatus.active,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'role': role.name,
      'branchID': branchID,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
