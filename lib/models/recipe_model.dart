import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeModel {
  final String recipeId;
  final String branchId;
  final String productId;
  final int servingSize;
  final int version;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  RecipeModel({
    required this.recipeId,
    required this.branchId,
    required this.productId,
    required this.servingSize,
    required this.version,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory RecipeModel.fromMap(Map<String, dynamic> data, String documentId) {
    return RecipeModel(
      recipeId: documentId,
      branchId: data['branchId'] ?? '',
      productId: data['productId'] ?? '',
      servingSize: data['servingSize'] ?? 1,
      version: data['version'] ?? 1,
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'productId': productId,
      'servingSize': servingSize,
      'version': version,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
