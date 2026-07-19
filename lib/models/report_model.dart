import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String branchId;
  final String generatedBy;
  final String reportUrl;
  final String type;
  final DateTime generatedAt;

  ReportModel({required this.id, required this.branchId, required this.generatedBy, required this.reportUrl, required this.type, required this.generatedAt});

  factory ReportModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ReportModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      generatedBy: data['generatedBy'] ?? '',
      reportUrl: data['reportUrl'] ?? '',
      type: data['type'] ?? '',
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'generatedBy': generatedBy,
      'reportUrl': reportUrl,
      'type': type,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
