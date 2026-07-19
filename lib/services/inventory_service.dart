import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/inventory_count_model.dart';
import '../models/inventory_movement_model.dart';

class InventoryService extends FirestoreService {
  InventoryService({super.firestore});
  
  Future<InventoryMovementModel> recordMovement(InventoryMovementModel movement) async {
    DocumentReference doc = inventoryMovements.doc();
    var data = movement.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return InventoryMovementModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<InventoryCountModel> updateCount(InventoryCountModel count) async {
    DocumentReference doc = inventoryCounts.doc();
    var data = count.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return InventoryCountModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }
  
  Future<void> deleteMovement(String id) async {
    await inventoryMovements.doc(id).delete();
  }

  Future<void> deleteCount(String id) async {
    await inventoryCounts.doc(id).delete();
  }
}
