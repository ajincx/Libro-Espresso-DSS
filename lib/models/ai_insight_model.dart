import 'package:cloud_firestore/cloud_firestore.dart';

class AiInsightModel {
  final String id;
  final String branchId;
  final String content;
  final String type; // 'optimization', 'warning', 'trend'
  final DateTime generatedAt;

  AiInsightModel({required this.id, required this.branchId, required this.content, required this.type, required this.generatedAt});

  factory AiInsightModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AiInsightModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'trend',
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'content': content,
      'type': type,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
