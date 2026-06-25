import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import 'package:bazar_suez/firebase_options.dart';
import 'package:bazar_suez/services/order_notifications/local_notification_service.dart';

/// معالج FCM في الخلفية — يجب أن يبقى دالة top-level مع [pragma vm:entry-point].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocalNotificationService.instance.initialize();
  final data = message.data;
  if (data['type']?.toString() == 'announcement') {
    await LocalNotificationService.instance.showFromAnnouncementFcmData(
      data,
      title: message.notification?.title,
      body: message.notification?.body,
    );
  } else {
    await LocalNotificationService.instance.showFromOrderFcmData(data);
  }
}
