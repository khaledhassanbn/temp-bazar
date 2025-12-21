import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_color.dart';

class AdminBottomNavigation extends StatelessWidget {
  final int currentIndex;
  const AdminBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _handleTap(context, index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.mainColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'لوحة التحكم',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard_outlined),
          activeIcon: Icon(Icons.card_giftcard),
          label: 'الباقات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'المتاجر',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'حسابي',
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, int index) {
    final currentRoute = GoRouterState.of(context).matchedLocation;

    switch (index) {
      case 0:
        // لوحة التحكم
        if (currentRoute != '/admin/dashboard') {
          context.go('/admin/dashboard');
        }
        break;
      case 1:
        // الباقات
        if (!currentRoute.startsWith('/admin/manage-packages') &&
            !currentRoute.startsWith('/admin/create-package') &&
            !currentRoute.startsWith('/admin/manage-categories') &&
            !currentRoute.startsWith('/admin/create-category') &&
            !currentRoute.startsWith('/admin/edit-category')) {
          context.go('/admin/manage-packages');
        }
        break;
      case 2:
        // المتاجر
        if (!currentRoute.startsWith('/admin/stores')) {
          context.go('/admin/stores');
        }
        break;
      case 3:
        // حسابي
        if (currentRoute != '/AccountPage') {
          context.go('/AccountPage');
        }
        break;
    }
  }
}
