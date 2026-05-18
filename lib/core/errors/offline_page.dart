import 'package:bazar_suez/core/errors/error_page.dart';
import 'package:flutter/material.dart';

class OfflinePage extends StatelessWidget {
  final bool isChecking;
  final Future<bool> Function() onRetry;

  const OfflinePage({
    super.key,
    required this.isChecking,
    required this.onRetry,
  });

  static const _image = 'assets/images/no_internet.png';

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ErrorPage(
        imageAsset: _image,
        title: 'لا يوجد اتصال بالإنترنت',
        subtitle:
            'تحقق من اتصالك بالشبكة ثم اضغط إعادة المحاولة.\nسنعيد تحميل التطبيق تلقائياً عند عودة الاتصال.',
        primaryButtonLabel: 'إعادة المحاولة',
        primaryIcon: Icons.refresh_rounded,
        isPrimaryLoading: isChecking,
        onPrimaryPressed: () => onRetry(),
      ),
    );
  }
}
