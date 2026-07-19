import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String branchId;
  final String branchName;
  final String address;
  final String contactNumber;
  final String email;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  BranchModel({
    required this.branchId,
    required this.branchName,
    required this.address,
    required this.contactNumber,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory BranchModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BranchModel(
      branchId: documentId,
      branchName: data['branchName'] ?? '',
      address: data['address'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      email: data['email'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchName': branchName,
      'address': address,
      'contactNumber': contactNumber,
      'email': email,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
