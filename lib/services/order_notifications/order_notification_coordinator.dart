import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:bazar_suez/router/app_navigation.dart';
import 'package:bazar_suez/widgets/order_notifications/new_order_alert_dialog.dart';

import 'order_alert_sound_service.dart';
import 'order_notification_constants.dart';

/// يمنع التكرار بين FCM والاستماع المباشر، ويعرض نوافذ متتابعة عند وجود أكثر من طلب.
class OrderNotificationCoordinator {
  OrderNotificationCoordinator._();

  /// Singleton للاستخدام من واجهة المتجر وخدمة FCM.
  static final OrderNotificationCoordinator instance =
      OrderNotificationCoordinator._();

  final OrderAlertSoundService _sound = OrderAlertSoundService();
  final Set<String> _queuedOrShown = {};
  final Queue<String> _queue = Queue<String>();

  /// سلسلة معالجة متتابعة لتجنّب تعارض النوافذ والنداءات المتزامنة.
  Future<void> _chain = Future<void>.value();

  /// طلب جديد من أي مصدر (Firestore / FCM foreground).
  void notifyNewOrder(String orderId) {
    if (orderId.isEmpty) return;
    if (_queuedOrShown.contains(orderId)) return;
    _queuedOrShown.add(orderId);
    _queue.addLast(orderId);
    _chain = _chain.then((_) => _runQueue());
  }

  Future<void> _runQueue() async {
    while (_queue.isNotEmpty) {
      BuildContext? navigatorCtx = rootNavigatorKey.currentContext;
      var retries = 0;
      while (navigatorCtx == null && retries < 40) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        navigatorCtx = rootNavigatorKey.currentContext;
        retries++;
      }
      if (navigatorCtx == null) break;

      final orderId = _queue.first;

      await _sound.startAlertLoop();

      navigatorCtx = rootNavigatorKey.currentContext;
      if (navigatorCtx == null) break;
      if (!navigatorCtx.mounted) break;

      try {
        await showDialog<void>(
          context: navigatorCtx,
          barrierDismissible: false,
          builder: (dialogCtx) => NewOrderAlertDialog(
            orderId: orderId,
            onAccept: () async {
              await _persistResponse(orderId, accepted: true);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            onReject: () async {
              await _persistResponse(orderId, accepted: false);
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
          ),
        );
      } finally {
        await _sound.stop();
        if (_queue.isNotEmpty) {
          _queue.removeFirst();
        }
      }
    }
  }

  Future<void> _persistResponse(String orderId, {required bool accepted}) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      OrderNotificationFields.status:
          accepted ? OrderIndexStatus.accepted : OrderIndexStatus.rejected,
      OrderNotificationFields.respondedAt: FieldValue.serverTimestamp(),
    });
  }

  Future<void> disposeSoundOnly() async {
    await _sound.dispose();
  }
}
