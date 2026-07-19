import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RoleGuard extends StatelessWidget {
  final Widget child;
  final Widget unauthorizedRoute;
  final bool requireOwner;

  const RoleGuard({
    super.key,
    required this.child,
    required this.unauthorizedRoute,
    this.requireOwner = false,
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

        // If not authenticated, they shouldn't even be here, but just in case:
        if (!authProvider.isAuthenticated) {
          return const Scaffold(body: Center(child: Text('Please log in.')));
        }

        if (requireOwner && !authProvider.isOwner) {
          return unauthorizedRoute;
        }

        return child;
      },
    );
  }
}
