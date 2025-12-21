import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/admin_bottom_navigation.dart';

/// Layout wrapper for admin pages that adds bottom navigation bar
/// Similar to MarketLayout - wraps child in Scaffold with bottom nav
class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromRoute(context);

    // Wrap child in Scaffold with bottom navigation bar
    // Child pages should not have their own Scaffold to avoid nesting
    return Scaffold(
      body: child,
      bottomNavigationBar: AdminBottomNavigation(currentIndex: currentIndex),
    );
  }

  int _getIndexFromRoute(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    if (route.startsWith('/admin/dashboard')) {
      return 0;
    }
    if (route.startsWith('/admin/create-package') ||
        route.startsWith('/admin/manage-packages') ||
        route.startsWith('/admin/manage-categories') ||
        route.startsWith('/admin/create-category') ||
        route.startsWith('/admin/edit-category')) {
      return 1;
    }
    if (route.startsWith('/admin/stores')) {
      return 2;
    }
    if (route.startsWith('/AccountPage')) {
      return 3;
    }
    // الصفحة الافتراضية (لوحة التحكم)
    return 0;
  }
}
