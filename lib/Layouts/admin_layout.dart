import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/admin_bottom_navigation.dart';
import 'package:bazar_suez/router/widgets/app_back_guard.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromRoute(context);

    return AppBackGuard(
      homePath: '/admin/dashboard',
      child: Scaffold(
        body: child,
        bottomNavigationBar: AdminBottomNavigation(currentIndex: currentIndex),
      ),
    );
  }

  int _getIndexFromRoute(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    if (route.startsWith('/admin/dashboard')) return 0;
    if (route.startsWith('/admin/craftsmen') ||
        route.startsWith('/admin/stores') ||
        route.startsWith('/admin/courier') ||
        route.startsWith('/admin/manage-packages') ||
        route.startsWith('/admin/create-package') ||
        route.startsWith('/admin/manage-categories') ||
        route.startsWith('/admin/create-category') ||
        route.startsWith('/admin/edit-category')) {
      return 1;
    }
    if (route.startsWith('/admin/reports')) return 2;
    if (route.startsWith('/admin/roles') ||
        route.startsWith('/admin/add-admin') ||
        route.startsWith('/admin/deleted-accounts') ||
        route.startsWith('/admin/activity-logs') ||
        route.startsWith('/admin/offices') ||
        route.startsWith('/admin/ads') ||
        route.startsWith('/AccountPage')) {
      return 3;
    }
    return 0;
  }
}
