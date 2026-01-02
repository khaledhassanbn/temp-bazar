// lib/layouts/user_layout.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserLayout extends StatelessWidget {
  final Widget child;
  const UserLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ❌ تم حذف الـ AppBar
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: _getIndexFromRoute(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/HomePage');
              break;
            case 1:
              context.go('/user-orders');
              break;
            case 2:
              context.go('/AccountPage');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "طلباتي"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "حسابي"),
        ],
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
