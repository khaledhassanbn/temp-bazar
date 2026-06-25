import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../authentication/guards/AuthGuard.dart';
import '../services/inbox_service.dart';
import '../services/popup_display_service.dart';
import '../viewmodels/inbox_viewmodel.dart';

/// يهيئ مركز الرسائل ويعرض الإعلانات المنبثقة بعد تسجيل الدخول
class NotificationHost extends StatefulWidget {
  final Widget child;

  const NotificationHost({super.key, required this.child});

  @override
  State<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends State<NotificationHost> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    try {
      final authGuard = context.read<AuthGuard>();
      if (FirebaseAuth.instance.currentUser == null ||
          authGuard.userStatus == null) {
        return;
      }

      final audience = InboxService.audienceForUserStatus(
        authGuard.userStatus ?? 'user',
        isCraftsman: authGuard.userStatus == 'craftsman',
      );

      await context.read<InboxViewModel>().initialize(
            userStatus: authGuard.userStatus ?? 'user',
            isCraftsman: authGuard.userStatus == 'craftsman',
          );

      if (!mounted) return;
      await PopupDisplayService.instance.tryShowPopup(
        context,
        audience: audience,
      );
    } catch (e, st) {
      debugPrint('NotificationHost bootstrap error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
