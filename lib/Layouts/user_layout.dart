import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bazar_suez/router/widgets/app_back_guard.dart';

import 'widgets/user_bottom_navigation.dart';

class UserLayout extends StatelessWidget {
  final Widget child;
  const UserLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromRoute(context);
    return AppBackGuard(
      homePath: '/',
      child: Scaffold(
        body: child,
        bottomNavigationBar: UserBottomNavigation(currentIndex: currentIndex),
      ),
    );
  }

  int _getIndexFromRoute(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    if (route.startsWith('/user-orders')) return 1;
    if (route.startsWith('/AccountPage')) return 2;
    return 0;
  }
}

