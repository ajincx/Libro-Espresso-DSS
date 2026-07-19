import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientModel {
  final String ingredientId;
  final String branchId;
  final String ingredientName;
  final String category;
  final String unit;
  final double costPerUnit;
  final String? supplier;
  final double reorderLevel;
  final double currentStock;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  IngredientModel({
    required this.ingredientId,
    required this.branchId,
    required this.ingredientName,
    required this.category,
    required this.unit,
    required this.costPerUnit,
    this.supplier,
    required this.reorderLevel,
    required this.currentStock,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory IngredientModel.fromMap(Map<String, dynamic> data, String documentId) {
    return IngredientModel(
      ingredientId: documentId,
      branchId: data['branchId'] ?? '',
      ingredientName: data['ingredientName'] ?? '',
      category: data['category'] ?? '',
      unit: data['unit'] ?? '',
      costPerUnit: (data['costPerUnit'] ?? 0.0).toDouble(),
      supplier: data['supplier'],
      reorderLevel: (data['reorderLevel'] ?? 0.0).toDouble(),
      currentStock: (data['currentStock'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'ingredientName': ingredientName,
      'category': category,
      'unit': unit,
      'costPerUnit': costPerUnit,
      'supplier': supplier,
      'reorderLevel': reorderLevel,
      'currentStock': currentStock,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
