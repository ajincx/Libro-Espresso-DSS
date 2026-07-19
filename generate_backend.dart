// ignore_for_file: avoid_print, deprecated_member_use, curly_braces_in_flow_control_structures, library_prefixes, use_build_context_synchronously, library_private_types_in_public_api
import 'dart:io';

void main() async {
  final baseDir = 'lib';
  final modelsDir = Directory('$baseDir/models');
  final servicesDir = Directory('$baseDir/services');
  
  if (!modelsDir.existsSync()) modelsDir.createSync(recursive: true);
  if (!servicesDir.existsSync()) servicesDir.createSync(recursive: true);

  final Map<String, String> files = {
    'models/branch_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class BranchModel {
  final String id;
  final String name;
  final String location;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  BranchModel({required this.id, required this.name, required this.location, required this.status, required this.createdAt, required this.updatedAt});

  factory BranchModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BranchModel(
      id: documentId,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
''',
    'models/product_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({required this.id, required this.name, required this.category, required this.price, required this.isAvailable, required this.createdAt, required this.updatedAt});

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
''',
    'models/ingredient_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientModel {
  final String id;
  final String name;
  final String unit;
  final double costPerUnit;
  final DateTime createdAt;
  final DateTime updatedAt;

  IngredientModel({required this.id, required this.name, required this.unit, required this.costPerUnit, required this.createdAt, required this.updatedAt});

  factory IngredientModel.fromMap(Map<String, dynamic> data, String documentId) {
    return IngredientModel(
      id: documentId,
      name: data['name'] ?? '',
      unit: data['unit'] ?? '',
      costPerUnit: (data['costPerUnit'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'costPerUnit': costPerUnit,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
''',
    'models/recipe_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeModel {
  final String id;
  final String productId;
  final List<RecipeIngredient> ingredients;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecipeModel({required this.id, required this.productId, required this.ingredients, required this.createdAt, required this.updatedAt});

  factory RecipeModel.fromMap(Map<String, dynamic> data, String documentId) {
    var list = data['ingredients'] as List? ?? [];
    return RecipeModel(
      id: documentId,
      productId: data['productId'] ?? '',
      ingredients: list.map((e) => RecipeIngredient.fromMap(e)).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class RecipeIngredient {
  final String ingredientId;
  final double quantity;

  RecipeIngredient({required this.ingredientId, required this.quantity});

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      ingredientId: data['ingredientId'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ingredientId': ingredientId,
      'quantity': quantity,
    };
  }
}
''',
    'models/sale_model.dart': '''
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
''',
    'models/inventory_count_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryCountModel {
  final String id;
  final String branchId;
  final String ingredientId;
  final double countedQuantity;
  final DateTime updatedAt;

  InventoryCountModel({required this.id, required this.branchId, required this.ingredientId, required this.countedQuantity, required this.updatedAt});

  factory InventoryCountModel.fromMap(Map<String, dynamic> data, String documentId) {
    return InventoryCountModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      ingredientId: data['ingredientId'] ?? '',
      countedQuantity: (data['countedQuantity'] ?? 0.0).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'ingredientId': ingredientId,
      'countedQuantity': countedQuantity,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
''',
    'models/inventory_movement_model.dart': '''
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
''',
    'models/forecast_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class ForecastModel {
  final String id;
  final String branchId;
  final DateTime targetDate;
  final double predictedSales;
  final DateTime generatedAt;

  ForecastModel({required this.id, required this.branchId, required this.targetDate, required this.predictedSales, required this.generatedAt});

  factory ForecastModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ForecastModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      targetDate: (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      predictedSales: (data['predictedSales'] ?? 0.0).toDouble(),
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'targetDate': Timestamp.fromDate(targetDate),
      'predictedSales': predictedSales,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
''',
    'models/ai_insight_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class AiInsightModel {
  final String id;
  final String branchId;
  final String content;
  final String type; // 'optimization', 'warning', 'trend'
  final DateTime generatedAt;

  AiInsightModel({required this.id, required this.branchId, required this.content, required this.type, required this.generatedAt});

  factory AiInsightModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AiInsightModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'trend',
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'content': content,
      'type': type,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
''',
    'models/notification_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String? userId;
  final String? branchId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({required this.id, this.userId, this.branchId, required this.title, required this.message, required this.isRead, required this.createdAt});

  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      userId: data['userId'],
      branchId: data['branchId'],
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'branchId': branchId,
      'title': title,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
''',
    'models/report_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String branchId;
  final String generatedBy;
  final String reportUrl;
  final String type;
  final DateTime generatedAt;

  ReportModel({required this.id, required this.branchId, required this.generatedBy, required this.reportUrl, required this.type, required this.generatedAt});

  factory ReportModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ReportModel(
      id: documentId,
      branchId: data['branchId'] ?? '',
      generatedBy: data['generatedBy'] ?? '',
      reportUrl: data['reportUrl'] ?? '',
      type: data['type'] ?? '',
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'generatedBy': generatedBy,
      'reportUrl': reportUrl,
      'type': type,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}
''',
    'models/setting_model.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingModel {
  final String id;
  final String key;
  final dynamic value;
  final DateTime updatedAt;

  SettingModel({required this.id, required this.key, required this.value, required this.updatedAt});

  factory SettingModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SettingModel(
      id: documentId,
      key: data['key'] ?? documentId,
      value: data['value'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
''',
    'services/firestore_service.dart': '''
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
  CollectionReference get sales => firestore.collection('sales');
  CollectionReference get inventoryCounts => firestore.collection('inventory_counts');
  CollectionReference get inventoryMovements => firestore.collection('inventory_movements');
  CollectionReference get forecasts => firestore.collection('forecasts');
  CollectionReference get aiInsights => firestore.collection('ai_insights');
  CollectionReference get notifications => firestore.collection('notifications');
  CollectionReference get reports => firestore.collection('reports');
  CollectionReference get settings => firestore.collection('settings');
}
''',
    'services/branch_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/branch_model.dart';

class BranchService extends FirestoreService {
  BranchService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<BranchModel> createBranch(BranchModel branch) async {
    DocumentReference doc = branches.doc();
    var data = branch.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return BranchModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<BranchModel?> getBranch(String id) async {
    var doc = await branches.doc(id).get();
    if (doc.exists) {
      return BranchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateBranch(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await branches.doc(id).update(updates);
  }

  Future<void> deleteBranch(String id) async {
    await branches.doc(id).delete();
  }

  Stream<List<BranchModel>> streamAllBranches() {
    return branches.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BranchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}
''',
    'services/product_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/product_model.dart';

class ProductService extends FirestoreService {
  ProductService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<ProductModel> createProduct(ProductModel product) async {
    DocumentReference doc = products.doc();
    var data = product.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return ProductModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<ProductModel?> getProduct(String id) async {
    var doc = await products.doc(id).get();
    if (doc.exists) {
      return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await products.doc(id).update(updates);
  }

  Future<void> deleteProduct(String id) async {
    await products.doc(id).delete();
  }

  Stream<List<ProductModel>> streamProducts() {
    return products.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}
''',
    'services/ingredient_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/ingredient_model.dart';

class IngredientService extends FirestoreService {
  IngredientService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<IngredientModel> createIngredient(IngredientModel ingredient) async {
    DocumentReference doc = ingredients.doc();
    var data = ingredient.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return IngredientModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<IngredientModel?> getIngredient(String id) async {
    var doc = await ingredients.doc(id).get();
    if (doc.exists) {
      return IngredientModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateIngredient(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await ingredients.doc(id).update(updates);
  }

  Future<void> deleteIngredient(String id) async {
    await ingredients.doc(id).delete();
  }
}
''',
    'services/recipe_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/recipe_model.dart';

class RecipeService extends FirestoreService {
  RecipeService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<RecipeModel> createRecipe(RecipeModel recipe) async {
    DocumentReference doc = recipes.doc();
    var data = recipe.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return RecipeModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<RecipeModel?> getRecipe(String id) async {
    var doc = await recipes.doc(id).get();
    if (doc.exists) {
      return RecipeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateRecipe(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await recipes.doc(id).update(updates);
  }

  Future<void> deleteRecipe(String id) async {
    await recipes.doc(id).delete();
  }
}
''',
    'services/sales_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/sale_model.dart';

class SalesService extends FirestoreService {
  SalesService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<SaleModel> recordSale(SaleModel sale) async {
    DocumentReference doc = sales.doc();
    var data = sale.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
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
''',
    'services/inventory_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/inventory_count_model.dart';
import '../models/inventory_movement_model.dart';

class InventoryService extends FirestoreService {
  InventoryService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
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
''',
    'services/forecast_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/forecast_model.dart';

class ForecastService extends FirestoreService {
  ForecastService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<ForecastModel> createForecast(ForecastModel forecast) async {
    DocumentReference doc = forecasts.doc();
    var data = forecast.toMap();
    data['generatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return ForecastModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> deleteForecast(String id) async {
    await forecasts.doc(id).delete();
  }

  Stream<List<ForecastModel>> streamForecasts(String branchId) {
    return forecasts
        .where('branchId', isEqualTo: branchId)
        .orderBy('targetDate', descending: false)
        .snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ForecastModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }
}
''',
    'services/ai_insight_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/ai_insight_model.dart';

class AiInsightService extends FirestoreService {
  AiInsightService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<AiInsightModel> createAiInsight(AiInsightModel insight) async {
    DocumentReference doc = aiInsights.doc();
    var data = insight.toMap();
    data['generatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return AiInsightModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> deleteAiInsight(String id) async {
    await aiInsights.doc(id).delete();
  }
}
''',
    'services/notification_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/notification_model.dart';

class NotificationService extends FirestoreService {
  NotificationService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<NotificationModel> createNotification(NotificationModel notification) async {
    DocumentReference doc = notifications.doc();
    var data = notification.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return NotificationModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> markAsRead(String notificationId) async {
    await notifications.doc(notificationId).update({'isRead': true});
  }
  
  Future<void> deleteNotification(String id) async {
    await notifications.doc(id).delete();
  }
}
''',
    'services/report_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/report_model.dart';

class ReportService extends FirestoreService {
  ReportService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<ReportModel> saveReport(ReportModel report) async {
    DocumentReference doc = reports.doc();
    var data = report.toMap();
    data['generatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data);
    var snapshot = await doc.get();
    return ReportModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }
  
  Future<void> deleteReport(String id) async {
    await reports.doc(id).delete();
  }
}
''',
    'services/settings_service.dart': '''
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/setting_model.dart';

class SettingsService extends FirestoreService {
  SettingsService({FirebaseFirestore? firestore}) : super(firestore: firestore);
  
  Future<SettingModel> createOrUpdateSetting(SettingModel setting) async {
    DocumentReference doc = settings.doc(setting.key);
    var data = setting.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await doc.set(data, SetOptions(merge: true));
    var snapshot = await doc.get();
    return SettingModel.fromMap(snapshot.data() as Map<String, dynamic>, doc.id);
  }

  Future<SettingModel?> getSetting(String key) async {
    var doc = await settings.doc(key).get();
    if (doc.exists) {
      return SettingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }
  
  Future<void> deleteSetting(String key) async {
    await settings.doc(key).delete();
  }
}
'''
  };

  for (var entry in files.entries) {
    File('$baseDir/${entry.key}').writeAsStringSync(entry.value);
  }
  print('Done creating models and services.');
}
