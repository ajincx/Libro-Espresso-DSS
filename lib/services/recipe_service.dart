// ignore_for_file: unused_import, unused_field
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/recipe_model.dart';
import '../models/recipe_item_model.dart';
import 'product_service.dart';
import 'ingredient_service.dart';

class RecipeService extends FirestoreService {
  final ProductService _productService = ProductService();
  final IngredientService _ingredientService = IngredientService();

  RecipeService({super.firestore});

  Future<void> addRecipeWithItems(RecipeModel recipe, List<RecipeItemModel> items) async {}
  Future<void> updateRecipe(String recipeId, Map<String, RecipeItemModel> updates) async {}
  Future<void> deleteRecipe(String recipeId) async {}
  Future<RecipeModel?> getRecipeById(String id) async => null;
  Future<List<RecipeModel>> getRecipesByProduct(String productId) async => [];
  Stream<List<RecipeItemModel>> streamRecipeItems(String recipeId) => Stream.value([]);
  Future<List<RecipeItemModel>> getRecipeItems(String recipeId) async => [];
  Stream<List<RecipeModel>> streamRecipes(String productId) => Stream.value([]);
  Future<Map<String, RecipeItemModel>> calculateRecipeCost(String recipeId) async => {};
  Future<bool> checkInventoryForRecipe(String recipeId, int quantityToProduce) async => false;
}




