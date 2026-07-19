import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore;

  FirestoreService({FirebaseFirestore? firestore}) : firestore = firestore ?? FirebaseFirestore.instance;

  // Collection References
  CollectionReference get users => firestore.collection('users');
  CollectionReference get branches => firestore.collection('branches');
  CollectionReference get products => firestore.collection('products');
  CollectionReference get ingredients => firestore.collection('ingredients');
  CollectionReference get recipes => firestore.collection('recipes');
  CollectionReference get recipeItems => firestore.collection('recipe_items');
  CollectionReference get sales => firestore.collection('sales');
  CollectionReference get inventoryCounts => firestore.collection('inventory_counts');
  CollectionReference get inventoryMovements => firestore.collection('inventory_movements');
  CollectionReference get forecasts => firestore.collection('forecasts');
  CollectionReference get aiInsights => firestore.collection('ai_insights');
  CollectionReference get notifications => firestore.collection('notifications');
  CollectionReference get reports => firestore.collection('reports');
}

