import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget loginRoute;

  const AuthGuard({
    super.key,
    required this.child,
    required this.loginRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isAuthenticated) {
          return loginRoute;
        }

        return child;
      },
    );
  }
}
