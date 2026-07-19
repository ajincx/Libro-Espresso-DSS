import 'package:flutter/material.dart';
import 'auth_provider.dart';
import '../services/branch_service.dart';
import '../models/branch_model.dart';

class BranchProvider extends ChangeNotifier {
  final BranchService _branchService = BranchService();
  AuthProvider? _authProvider;

  String? _activeBranchId;
  List<BranchModel> _branches = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? get activeBranchId => _activeBranchId;
  List<BranchModel> get branches => _branches;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  BranchModel? get activeBranch {
    if (_activeBranchId == null) return null;
    try {
      return _branches.firstWhere((b) => b.branchId == _activeBranchId);
    } catch (e) {
      return null;
    }
  }

  void update(AuthProvider authProvider) {
    _authProvider = authProvider;

    if (!authProvider.isAuthenticated) {
      _activeBranchId = null;
      _branches = [];
    } else if (authProvider.isManager) {
      _activeBranchId = authProvider.branchID;
      if (_branches.isEmpty) {
        refreshBranches();
      }
    } else if (authProvider.isOwner) {
      if (_branches.isEmpty) {
        refreshBranches();
      }
    }
  }

  Future<void> refreshBranches() async {
    _setLoading(true);
    try {
      if (_authProvider?.isOwner == true) {
        _branches = await _branchService.getBranches();
      } else if (_activeBranchId != null) {
        // Manager only needs their branch
        BranchModel? myBranch = await _branchService.getBranchById(_activeBranchId!);
        _branches = myBranch != null ? [myBranch] : [];
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> search(String query) async {
    _setLoading(true);
    try {
      if (query.isEmpty) {
        await refreshBranches();
      } else {
        if (_authProvider?.isOwner == true) {
          _branches = await _branchService.searchBranches(query);
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setActiveBranch(String branchId) {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;

    if (_authProvider!.isManager) {
      throw Exception('Access Denied: Managers cannot change the active branch context.');
    }

    if (_activeBranchId != branchId) {
      _activeBranchId = branchId;
      notifyListeners();
    }
  }

  void clearActiveBranch() {
    if (_authProvider != null && _authProvider!.isOwner && _activeBranchId != null) {
      _activeBranchId = null;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

