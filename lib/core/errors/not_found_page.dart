import 'package:bazar_suez/core/errors/error_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  static const _image = 'assets/images/404.png';

  @override
  Widget build(BuildContext context) {
    return ErrorPage(
      imageAsset: _image,
      title: 'الصفحة غير موجودة',
      subtitle:
          'الرابط الذي فتحته غير صالح أو لم يعد متاحاً.\nتأكد من الرابط أو ارجع للصفحة الرئيسية.',
      primaryButtonLabel: 'العودة للرئيسية',
      primaryIcon: Icons.home_rounded,
      onPrimaryPressed: () => context.go('/'),
      secondaryButtonLabel: 'رجوع',
      onSecondaryPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
    );
  }
}
