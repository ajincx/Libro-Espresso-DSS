import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'branch_provider.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  
  BranchProvider? _branchProvider;
  StreamSubscription? _productSubscription;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;

  List<ProductModel> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;

  void update(BranchProvider branchProvider) {
    if (_branchProvider?.activeBranchId != branchProvider.activeBranchId) {
      _branchProvider = branchProvider;
      _initStream();
    } else {
      _branchProvider = branchProvider;
    }
  }

  void _initStream() {
    _productSubscription?.cancel();
    final branchId = _branchProvider?.activeBranchId;

    if (branchId == null) {
      _allProducts = [];
      _applyFilters();
      return;
    }

    _setLoading(true);
    _productSubscription = _productService.streamProductsByBranch(branchId).listen(
      (productsList) {
        _allProducts = productsList;
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

  void setCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredProducts = _allProducts.where((p) {
      final matchesSearch = p.productName.toLowerCase().contains(_searchQuery) ||
                            p.description.toLowerCase().contains(_searchQuery);
      final matchesCategory = _selectedCategory == null || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
    notifyListeners();
  }

  Future<void> refresh() async {
    // Forces stream re-initialization to clear errors and reload
    _errorMessage = null;
    _initStream();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    super.dispose();
  }
}

