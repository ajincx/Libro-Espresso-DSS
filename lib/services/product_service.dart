// ignore_for_file: unused_import, unused_field
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/product_model.dart';
import 'branch_service.dart';

class ProductService extends FirestoreService {
  final BranchService _branchService = BranchService();
  ProductService({super.firestore});

  Future<void> addProduct(ProductModel product) async {
    await firestore.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await firestore.collection('products').doc(id).update(updates);
  }

  Future<void> updatePrice(String id, double newPrice) async {
    await firestore.collection('products').doc(id).update({
      'sellingPrice': newPrice,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String id) async {
    await firestore.collection('products').doc(id).delete();
  }

  Future<ProductModel?> getProductById(String id) async {
    final doc = await firestore.collection('products').doc(id).get();
    if (doc.exists && doc.data() != null) {
      return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<ProductModel>> getProductsByBranch(String branchId) async {
    final snapshot = await firestore.collection('products').where('branchId', isEqualTo: branchId).get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Stream<List<ProductModel>> streamProductsByBranch(String branchId) {
    return firestore.collection('products').where('branchId', isEqualTo: branchId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );
  }

  Stream<List<ProductModel>> streamActiveProducts(String branchId) {
    return firestore.collection('products')
      .where('branchId', isEqualTo: branchId)
      .where('status', isEqualTo: 'active')
      .snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
      );
  }
}
