import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'user_custom_bottom_app_bar.dart';

class UserBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const UserBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return UserCustomBottomAppBar(
      currentIndex: currentIndex,
      onTap: (index) {
        Feedback.forTap(context);
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
    );
  }
}
