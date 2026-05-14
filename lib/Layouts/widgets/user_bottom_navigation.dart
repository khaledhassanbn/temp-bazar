import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bazar_suez/widgets/auth_gate.dart';

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
            context.go('/');
            break;
          case 1:
            // طلباتي - تتطلب تسجيل دخول
            if (!requireAuth(context, message: 'سجّل دخولك لعرض طلباتك السابقة ومتابعة حالتها')) return;
            context.go('/user-orders');
            break;
          case 2:
            // حسابي - تتطلب تسجيل دخول
            if (!requireAuth(context, message: 'سجّل دخولك للوصول لحسابك وإدارة إعداداتك')) return;
            context.go('/AccountPage');
            break;
        }
      },
    );
  }
}
