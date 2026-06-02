import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:bazar_suez/router/app_navigation.dart';
import 'package:bazar_suez/widgets/order_notifications/new_order_alert_dialog.dart';
import 'package:bazar_suez/widgets/order_notifications/office_return_alert_dialog.dart';

import 'order_alert_sound_service.dart';
import 'order_notification_constants.dart';

enum _QueuedAlertKind { newOrder, officeReturned }

class _QueuedAlert {
  const _QueuedAlert.newOrder(this.storeId, this.orderId)
      : kind = _QueuedAlertKind.newOrder,
        orderDocumentId = orderId;

  const _QueuedAlert.officeReturned(this.storeId, this.orderDocumentId)
      : kind = _QueuedAlertKind.officeReturned,
        orderId = orderDocumentId;

  final _QueuedAlertKind kind;
  final String storeId;
  /// معرّف مستند طلب جديد فى مجموعة [orders] (مسار الإشعارات القديم).
  final String orderId;
  /// معرّف مستند الطلب فى [present_order] — يُستخدم لإرجاع المكتب للتاجر.
  final String orderDocumentId;
}

/// يمنع التكرار بين FCM والاستماع المباشر، ويعرض نوافذ متتابعة عند وجود أكثر من طلب.
class OrderNotificationCoordinator {
  OrderNotificationCoordinator._();

  /// Singleton للاستخدام من واجهة المتجر وخدمة FCM.
  static final OrderNotificationCoordinator instance =
      OrderNotificationCoordinator._();

  final OrderAlertSoundService _sound = OrderAlertSoundService();
  final Set<String> _queuedOrShown = {};
  final Set<String> _queuedOrShownOfficeReturn = {};
  final Queue<_QueuedAlert> _queue = Queue<_QueuedAlert>();

  /// سلسلة معالجة متتابعة لتجنّب تعارض النوافذ والنداءات المتزامنة.
  Future<void> _chain = Future<void>.value();

  /// طلب جديد من أي مصدر (Firestore / FCM foreground).
  ///
  /// [storeId] مطلوب لعرض تفاصيل المنتجات وربط زر "عرض الطلب" بالمتجر الصحيح.
  void notifyNewOrder({required String orderId, required String storeId}) {
    if (orderId.isEmpty || storeId.isEmpty) return;
    final key = '$storeId::$orderId';
    if (_queuedOrShown.contains(key)) return;
    _queuedOrShown.add(key);
    _queue.addLast(_QueuedAlert.newOrder(storeId, orderId));
    _chain = _chain.then((_) => _runQueue());
  }

  /// المكتب رجّع الطلب للتاجر (`returned_to_merchant`) — صوت وتنبيه مثل الطلب الجديد.
  void notifyOfficeReturnedOrder({
    required String orderDocumentId,
    required String storeId,
  }) {
    if (orderDocumentId.isEmpty || storeId.isEmpty) return;
    final key = '$storeId::$orderDocumentId';
    if (_queuedOrShownOfficeReturn.contains(key)) return;
    _queuedOrShownOfficeReturn.add(key);
    _queue.addLast(_QueuedAlert.officeReturned(storeId, orderDocumentId));
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

      final item = _queue.first;
      if (item.storeId.isEmpty ||
          (item.kind == _QueuedAlertKind.newOrder && item.orderId.isEmpty) ||
          (item.kind == _QueuedAlertKind.officeReturned &&
              item.orderDocumentId.isEmpty)) {
        _queue.removeFirst();
        continue;
      }

      await _sound.startAlertLoop();

      navigatorCtx = rootNavigatorKey.currentContext;
      if (navigatorCtx == null) break;
      if (!navigatorCtx.mounted) break;

      try {
        if (item.kind == _QueuedAlertKind.newOrder) {
          await showDialog<void>(
            context: navigatorCtx,
            barrierDismissible: false,
            builder: (dialogCtx) => NewOrderAlertDialog(
              orderId: item.orderId,
              storeId: item.storeId,
              onAccept: () async {
                await _persistResponse(item.orderId, accepted: true);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              onReject: () async {
                await _persistResponse(item.orderId, accepted: false);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
            ),
          );
        } else {
          await showDialog<void>(
            context: navigatorCtx,
            barrierDismissible: false,
            builder: (dialogCtx) => OfficeReturnAlertDialog(
              orderDocumentId: item.orderDocumentId,
              storeId: item.storeId,
            ),
          );
        }
      } finally {
        await _sound.stop();
        if (_queue.isNotEmpty) {
          _queue.removeFirst();
        }
      }
    }
  }

  Future<void> _persistResponse(String orderId, {required bool accepted}) async {
    final now = DateTime.now();
    final String statusText = accepted ? 'تم استلام الطلب' : 'تم رفض الطلب';
    
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      OrderNotificationFields.respondedAt: FieldValue.serverTimestamp(),
      // `status` للعرض فى واجهة التاجر؛ `orderStatus` للحالة الموحدة
      'status': statusText,
      'orderStatus': accepted ? 'accepted' : 'rejected',
      if (!accepted) 'isActive': false,
      if (!accepted) 'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': statusText,
          'time': Timestamp.fromDate(now),
        }
      ]),
    });
  }

  Future<void> disposeSoundOnly() async {
    await _sound.dispose();
  }
}
