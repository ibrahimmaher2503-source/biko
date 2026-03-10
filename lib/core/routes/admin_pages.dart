import 'package:biko/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Admin panel page registry
///
/// Returns the list of [GetPage] entries for the admin web panel.
/// Admin routes use [AdminAuthGuard] middleware and wrap content
/// in [AdminLayoutShell] for sidebar navigation.
class AdminPages {
  AdminPages._();

  static List<GetPage> get pages => [
    // ==================== Admin Auth ====================
    GetPage(
      name: AppRoutes.adminLogin,
      page: () => const _PlaceholderScreen(title: 'Admin Login'),
    ),

    // ==================== Admin Dashboard ====================
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const _PlaceholderScreen(title: 'Admin Dashboard'),
    ),

    // Additional admin routes added as features are built
  ];
}

/// Temporary placeholder for admin screens
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
