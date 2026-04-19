import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:bazar_suez/router/app_navigation.dart';
import 'order_notification_constants.dart';

/// إشعارات محلية (مقدّمة + خلفية) مع دعم الضغط للانتقال لشاشة الطلبات.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _payloadSep = '|';

  /// يجب استدعاؤه بعد [Firebase.initializeApp] وقبل تسجيل خلفية FCM.
  Future<void> initialize() async {
    if (_ready) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _ensureAndroidChannel();

    _ready = true;
    debugPrint('✅ LocalNotificationService initialized');
  }

  Future<void> _ensureAndroidChannel() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    const channel = AndroidNotificationChannel(
      kAndroidOrderChannelId,
      'الطلبات',
      description: 'تنبيهات طلبات جديدة للتاجر',
      importance: Importance.max,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  void _onNotificationResponse(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final parts = payload.split(_payloadSep);
    if (parts.length < 2) return;
    final storeId = parts[1];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateToStoreOrders(storeId);
    });
  }

  /// إظهار إشعار من بيانات FCM (خلفية / غير نشط).
  Future<void> showFromOrderFcmData(Map<String, dynamic> data) async {
    if (!_ready) await initialize();

    final type = data[FcmOrderDataKeys.type]?.toString();
    if (type != FcmOrderDataKeys.newOrder) return;

    final orderId = data[FcmOrderDataKeys.orderId]?.toString() ?? '';
    final storeId = data[FcmOrderDataKeys.storeId]?.toString() ?? '';
    final title =
        data[FcmOrderDataKeys.title]?.toString() ?? 'طلب جديد';
    final body =
        data[FcmOrderDataKeys.body]?.toString() ?? 'فيه طلب جديد عندك';

    if (orderId.isEmpty || storeId.isEmpty) return;

    final id = orderId.hashCode & 0x7fffffff;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        kAndroidOrderChannelId,
        'الطلبات',
        channelDescription: 'تنبيهات الطلبات للمتجر',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: '$orderId$_payloadSep$storeId',
    );
  }
}
