import 'package:flutter/material.dart';
import 'package:bazar_suez/router/widgets/app_back_guard.dart';

class UserLayout extends StatelessWidget {
  final Widget child;
  const UserLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppBackGuard(
      homePath: '/HomePage',
      child: Scaffold(
        body: child,
      ),
    );
  }
}

