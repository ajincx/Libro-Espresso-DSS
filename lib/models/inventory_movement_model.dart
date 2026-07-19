import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryMovementModel {
  final String id;
  final String branchId;
  final String ingredientId;
  final double quantity;
  final String type; // 'in', 'out', 'adjustment'
  final String reason;
  final DateTime timestamp;

  InventoryMovementModel({required this.id, required this.branchId, required this.ingredientId, required this.quantity, required this.type, required this.reason, required this.timestamp});

  factory InventoryMovementModel.fromMap(Map<String, dynamic> data, String documentId) {
    return InventoryMovementModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      ingredientId: data['ingredientId'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      type: data['type'] ?? 'out',
      reason: data['reason'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'ingredientId': ingredientId,
      'quantity': quantity,
      'type': type,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
