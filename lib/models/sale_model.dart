import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String branchId;
  final List<SaleItem> items;
  final double totalAmount;
  final String paymentMethod;
  final DateTime createdAt;

  SaleModel({required this.id, required this.branchId, required this.items, required this.totalAmount, required this.paymentMethod, required this.createdAt});

  factory SaleModel.fromMap(Map<String, dynamic> data, String documentId) {
    var list = data['items'] as List? ?? [];
    return SaleModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      items: list.map((e) => SaleItem.fromMap(e)).toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class SaleItem {
  final String productId;
  final int quantity;
  final double price;

  SaleItem({required this.productId, required this.quantity, required this.price});

  factory SaleItem.fromMap(Map<String, dynamic> data) {
    return SaleItem(
      productId: data['productId'] ?? '',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}
