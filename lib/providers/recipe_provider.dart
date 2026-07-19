import 'dart:async';
import 'package:flutter/material.dart';
import '../models/recipe_model.dart';
import '../models/recipe_item_model.dart';
import '../services/recipe_service.dart';
import 'branch_provider.dart';

class RecipeProvider extends ChangeNotifier {
  final RecipeService _recipeService = RecipeService();
  
  BranchProvider? _branchProvider;
  StreamSubscription? _recipeSubscription;
  final Map<String, StreamSubscription> _itemSubscriptions = {};

  List<RecipeModel> _recipes = [];
  final Map<String, List<RecipeItemModel>> _recipeItems = {};
  
  bool _isLoading = false;
  String? _errorMessage;

  List<RecipeModel> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<RecipeItemModel> getItemsForRecipe(String recipeId) {
    return _recipeItems[recipeId] ?? [];
  }

  void update(BranchProvider branchProvider) {
    if (_branchProvider?.activeBranchId != branchProvider.activeBranchId) {
      _branchProvider = branchProvider;
      _initStream();
    } else {
      _branchProvider = branchProvider;
    }
  }

  void _initStream() {
    _recipeSubscription?.cancel();
    _cancelAllItemSubscriptions();
    
    final branchId = _branchProvider?.activeBranchId;

    if (branchId == null) {
      _recipes = [];
      _recipeItems.clear();
      notifyListeners();
      return;
    }

    _setLoading(true);
    _recipeSubscription = _recipeService.streamRecipes(branchId).listen(
      (recipesList) {
        _recipes = recipesList;
        _errorMessage = null;
        
        // Setup item streams for any new active recipes
        for (var recipe in _recipes) {
          if (recipe.status == 'active' && !_itemSubscriptions.containsKey(recipe.recipeId)) {
            _subscribeToRecipeItems(recipe.recipeId);
          }
        }
        
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        _setLoading(false);
      }
    );
  }

  void _subscribeToRecipeItems(String recipeId) {
    _itemSubscriptions[recipeId] = _recipeService.streamRecipeItems(recipeId).listen(
      (items) {
        _recipeItems[recipeId] = items;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      }
    );
  }

  void _cancelAllItemSubscriptions() {
    for (var sub in _itemSubscriptions.values) {
      sub.cancel();
    }
    _itemSubscriptions.clear();
  }

  Future<void> fetchItemsForRecipe(String recipeId) async {
    // A manual fetch if a specific non-active recipe's items are needed
    try {
      _setLoading(true);
      var items = await _recipeService.getRecipeItems(recipeId);
      _recipeItems[recipeId] = items;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _errorMessage = null;
    _initStream();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _recipeSubscription?.cancel();
    _cancelAllItemSubscriptions();
    super.dispose();
  }
}
