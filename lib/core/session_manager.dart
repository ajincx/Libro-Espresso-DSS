class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  String? userId;
  String? displayName;
  String? email;
  String? role;
  String? branchID;
  String? branchName;

  bool get isLoggedIn => userId != null;
  bool get isOwner => role?.toLowerCase() == 'owner';
  bool get isManager => role?.toLowerCase() == 'manager';

  void setSession({
    required String id,
    required String name,
    required String mail,
    required String userRole,
    String? branchId,
    String? bName,
  }) {
    userId = id;
    displayName = name;
    email = mail;
    role = userRole;
    branchID = branchId;
    branchName = bName ?? branchId;
  }

  void clearSession() {
    userId = null;
    displayName = null;
    email = null;
    role = null;
    branchID = null;
    branchName = null;
  }
}
