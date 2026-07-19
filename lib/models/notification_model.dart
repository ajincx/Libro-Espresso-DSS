import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String? userId;
  final String? branchId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({required this.id, this.userId, this.branchId, required this.title, required this.message, required this.isRead, required this.createdAt});

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      userId: data['userId'],
      branchId: data['branchId'],
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'branchId': branchId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
