import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String branchId;
  final String productName;
  final String description;
  final String category;
  final double sellingPrice;
  final String status;
  final String? imageUrl;
  final List<Map<String, dynamic>> ingredients;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  ProductModel({
    required this.productId,
    required this.branchId,
    required this.productName,
    required this.description,
    required this.category,
    required this.sellingPrice,
    required this.status,
    this.imageUrl,
    this.ingredients = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      productId: documentId,
      branchId: data['branchId'] ?? '',
      productName: data['productName'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      sellingPrice: (data['sellingPrice'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'active',
      imageUrl: data['imageUrl'],
      ingredients: data['ingredients'] != null
          ? List<Map<String, dynamic>>.from(data['ingredients'])
          : [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'productName': productName,
      'description': description,
      'category': category,
      'sellingPrice': sellingPrice,
      'status': status,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}
