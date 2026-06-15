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
          icon: Icon(Icons.manage_accounts_outlined),
          activeIcon: Icon(Icons.manage_accounts),
          label: 'الإدارة',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_outlined),
          activeIcon: Icon(Icons.report),
          label: 'البلاغات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          activeIcon: Icon(Icons.more_horiz),
          label: 'المزيد',
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        _showManagementMenu(context);
        break;
      case 2:
        context.go('/admin/reports');
        break;
      case 3:
        _showMoreMenu(context);
        break;
    }
  }

  void _showManagementMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.handyman_outlined),
              title: const Text('الصنايعية'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/craftsmen');
              },
            ),
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('المتاجر'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/stores');
              },
            ),
            ListTile(
              leading: const Icon(Icons.motorcycle_outlined),
              title: const Text('طلبات المناديب'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/courier-requests');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard_outlined),
              title: const Text('الباقات'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/manage-packages');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('إدارة المسؤولين'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/roles');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('الحسابات المحذوفة'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/deleted-accounts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('سجلات النشاط'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/activity-logs');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('مكاتب الشحن'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/offices');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('الإعلانات'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/admin/ads');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('حسابي'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/AccountPage');
              },
            ),
          ],
        ),
      ),
    );
  }
}
