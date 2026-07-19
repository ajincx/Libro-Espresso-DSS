import 'package:flutter/material.dart';
import '../core/session_manager.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => SessionManager().isLoggedIn;
  bool get isAuthenticated => SessionManager().isLoggedIn; // Backward compatibility
  bool get isOwner => SessionManager().isOwner;
  bool get isManager => SessionManager().isManager;
  
  String? get currentUserId => SessionManager().userId;
  SessionManager get currentUser => SessionManager(); // To satisfy any generic 'currentUser' checks, though in the past it returned UserModel.
  String? get role => SessionManager().role;
  String? get branchID => SessionManager().branchID;
  String? get displayName => SessionManager().displayName;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signIn(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    AuthService.signOut();
    notifyListeners();
  }
}
