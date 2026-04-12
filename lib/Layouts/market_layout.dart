import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/market_bottom_navigation.dart';
import 'package:bazar_suez/router/widgets/app_back_guard.dart';

class MarketLayout extends StatelessWidget {
  final Widget child;
  const MarketLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getIndexFromRoute(context);
    return AppBackGuard(
      homePath: '/HomePage',
      bypassToPreviousPaths: const ['/edit-store'],
      child: Scaffold(
        body: child,
        bottomNavigationBar: MarketBottomNavigation(currentIndex: currentIndex),
      ),
    );
  }

  int _getIndexFromRoute(BuildContext context) {
    final route = GoRouterState.of(context).matchedLocation;
    if (route.startsWith('/myorder')) return 1;
    if (route.startsWith('/addproduct') ||
        route.startsWith('/ManageProducts') ||
        route.startsWith('/edit-store') ||
        route.startsWith('/pricingpage'))
      return 2;
    if (route.startsWith('/MyStorePage')) return 3;
    if (route.startsWith('/AccountPage')) return 4;
    return 0;
  }
}
