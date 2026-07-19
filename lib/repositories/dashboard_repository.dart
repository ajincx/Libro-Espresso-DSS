import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getSalesStream() => _firestore.collection('sales').snapshots();
  Stream<QuerySnapshot> getProductsStream() => _firestore.collection('products').snapshots();
  Stream<QuerySnapshot> getInventoryStream() => _firestore.collection('inventory').snapshots();
  Stream<QuerySnapshot> getAiInsightsStream() => _firestore.collection('ai_insights').orderBy('generatedDate', descending: true).snapshots();
  Stream<QuerySnapshot> getBranchesStream() => _firestore.collection('branches').snapshots();
  
  // Keep futures if needed for manual fetches, but mostly streams now
  Future<QuerySnapshot> getSales() => _firestore.collection('sales').get();
  Future<QuerySnapshot> getProducts() => _firestore.collection('products').get();
  Future<QuerySnapshot> getInventory() => _firestore.collection('inventory').get();
}
