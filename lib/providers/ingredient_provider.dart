import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../services/ingredient_service.dart';
import 'branch_provider.dart';

class IngredientProvider extends ChangeNotifier {
  final IngredientService _ingredientService = IngredientService();
  
  BranchProvider? _branchProvider;
  StreamSubscription? _ingredientSubscription;

  List<IngredientModel> _allIngredients = [];
  List<IngredientModel> _filteredIngredients = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<IngredientModel> get ingredients => _filteredIngredients;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void update(BranchProvider branchProvider) {
    if (_branchProvider?.activeBranchId != branchProvider.activeBranchId) {
      _branchProvider = branchProvider;
      _initStream();
    } else {
      _branchProvider = branchProvider;
    }
  }

  void _initStream() {
    _ingredientSubscription?.cancel();
    final branchId = _branchProvider?.activeBranchId;

    if (branchId == null) {
      _allIngredients = [];
      _applyFilters();
      return;
    }

    _setLoading(true);
    _ingredientSubscription = _ingredientService.streamIngredients(branchId).listen(
      (ingredientsList) {
        _allIngredients = ingredientsList;
        _errorMessage = null;
        _applyFilters();
        _setLoading(false);
      },
      onError: (error) {
        _errorMessage = error.toString();
        _setLoading(false);
      }
    );
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    _filteredIngredients = _allIngredients.where((i) {
      return i.ingredientName.toLowerCase().contains(_searchQuery) ||
             i.category.toLowerCase().contains(_searchQuery);
    }).toList();
    notifyListeners();
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
    _ingredientSubscription?.cancel();
    super.dispose();
  }
}

