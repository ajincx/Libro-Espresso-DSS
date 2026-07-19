import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String userId;
  final String userRole;
  final String? branchId;
  final String module;
  final String action;
  final String description;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userRole,
    this.branchId,
    required this.module,
    required this.action,
    required this.description,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AuditLogModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userRole: data['userRole'] ?? '',
      branchId: data['branchId'],
      module: data['module'] ?? '',
      action: data['action'] ?? '',
      description: data['description'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userRole': userRole,
      'branchId': branchId,
      'module': module,
      'action': action,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
