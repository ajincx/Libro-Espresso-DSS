import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryCountModel {
  final String id;
  final String branchId;
  final String ingredientId;
  final double countedQuantity;
  final DateTime updatedAt;

  InventoryCountModel({required this.id, required this.branchId, required this.ingredientId, required this.countedQuantity, required this.updatedAt});

  factory InventoryCountModel.fromMap(Map<String, dynamic> data, String documentId) {
    return InventoryCountModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      ingredientId: data['ingredientId'] ?? '',
      countedQuantity: (data['countedQuantity'] ?? 0.0).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'ingredientId': ingredientId,
      'countedQuantity': countedQuantity,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
