import 'package:cloud_firestore/cloud_firestore.dart';

class ForecastModel {
  final String id;
  final String branchId;
  final DateTime targetDate;
  final double predictedSales;
  final DateTime generatedAt;

  ForecastModel({required this.id, required this.branchId, required this.targetDate, required this.predictedSales, required this.generatedAt});

  factory ForecastModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ForecastModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      targetDate: (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      predictedSales: (data['predictedSales'] ?? 0.0).toDouble(),
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'targetDate': Timestamp.fromDate(targetDate),
      'predictedSales': predictedSales,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
