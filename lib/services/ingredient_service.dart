// ignore_for_file: unused_import, unused_field
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/ingredient_model.dart';
import 'branch_service.dart';

class IngredientService extends FirestoreService {
  final BranchService _branchService = BranchService();
  IngredientService({super.firestore});

  Future<void> addIngredient(IngredientModel ingredient) async {}
  Future<void> updateIngredient(String id, Map<String, dynamic> updates) async {}
  Future<void> updateStock(String id, double newStock) async {}
  Future<void> deleteIngredient(String id) async {}
  Future<IngredientModel?> getIngredientById(String id) async => null;
  Future<List<IngredientModel>> getIngredientsByBranch(String branchId) async => [];
  Stream<List<IngredientModel>> streamIngredients(String branchId) => Stream.value([]);
  Stream<List<IngredientModel>> streamLowStock(String branchId) => Stream.value([]);
}

