import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/sale_model.dart';

class SalesService extends FirestoreService {
  SalesService({super.firestore});
  
  Future<SaleModel> recordSale(SaleModel sale) async {
    final batch = firestore.batch();
    DocumentReference doc = sales.doc();
    var data = sale.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    batch.set(doc, data);

    for (var item in sale.items) {
      final productDoc = await firestore.collection('products').doc(item.productId).get();
      if (productDoc.exists) {
        final pData = productDoc.data();
        if (pData != null && pData.containsKey('recipe')) {
          List<dynamic> recipe = pData['recipe'];
          for (var ing in recipe) {
            String invId = ing['inventoryID'] ?? '';
            num quantity = (ing['quantity'] ?? 0) * item.quantity;
            if (invId.isNotEmpty && quantity > 0) {
              final invRef = firestore.collection('inventory').doc(invId);
              batch.update(invRef, {
                'expectedStock': FieldValue.increment(-quantity),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }
    }

    await batch.commit();
    var snapshot = await doc.get();
    return SaleModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<SaleModel?> getSale(String id) async {
    var doc = await sales.doc(id).get();
    if (doc.exists) {
      return SaleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> deleteSale(String id) async {
    await sales.doc(id).delete();
  }

  Stream<List<SaleModel>> streamSalesByBranch(String branchId) {
    return sales
        .where('branchId', isEqualTo: branchId)
        .orderBy('createdAt', descending: true)
        .snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SaleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}
