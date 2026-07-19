class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;

  factory AuthException.fromFirebaseCode(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthException('The email address is badly formatted.');
      case 'user-disabled':
        return AuthException('This user account has been disabled.');
      case 'user-not-found':
        return AuthException('No user found for this email.');
      case 'wrong-password':
        return AuthException('Incorrect password provided.');
      case 'network-request-failed':
        return AuthException('A network error occurred. Please check your connection.');
      case 'invalid-credential':
        return AuthException('Invalid login credentials.');
      default:
        return AuthException('An unknown authentication error occurred.');
    }
  }
}
