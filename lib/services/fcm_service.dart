import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:bazar_suez/router/app_navigation.dart';
import 'package:bazar_suez/services/fcm_background_handler.dart'
    show firebaseMessagingBackgroundHandler;
import 'package:bazar_suez/services/order_notifications/order_notification_constants.dart';
import 'package:bazar_suez/services/order_notifications/order_notification_coordinator.dart';

/// خدمة FCM للتاجر والعميل — إشعار طلب جديد يتكامل مع [OrderNotificationCoordinator].
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static FcmService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentToken;
  String? get currentToken => _currentToken;

  // تقليل الكتابات على Firestore (خصوصًا عند فتح صفحات المتجر)
  static const Duration _tokenWriteThrottle = Duration(hours: 6);
  final Map<String, DateTime> _storeTokenLastWriteAttempt = <String, DateTime>{};
  final Map<String, DateTime> _userTokenLastWriteAttempt = <String, DateTime>{};

  static final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  static final StreamController<RemoteMessage> _messageOpenedController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundMessageController.stream;

  Stream<RemoteMessage> get onMessageOpened => _messageOpenedController.stream;

  /// تهيئة FCM ومعالجات الخلفية/المقدمة.
  Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _requestPermission();

      _currentToken = await _messaging.getToken();
      debugPrint('🔔 FCM Token: $_currentToken');

      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationOpen(
          Map<String, dynamic>.from(initialMessage.data),
        );
      }

      debugPrint('✅ FCM Service initialized successfully');
    } catch (e, st) {
      debugPrint('❌ Error initializing FCM: $e\n$st');
    }
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔐 Notification permission: ${settings.authorizationStatus}');
  }

  void _onTokenRefresh(String newToken) {
    debugPrint('🔄 FCM Token refreshed: $newToken');
    _currentToken = newToken;
    _updateStoredTokens(newToken);
  }

  Future<void> _updateStoredTokens(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await saveTokenForUser(user.uid);

      final storesQuery = await _firestore
          .collection('markets')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      for (final doc in storesQuery.docs) {
        await saveTokenForStore(doc.id);
      }
    } catch (e) {
      debugPrint('❌ Error updating stored tokens: $e');
    }
  }

  /// يحفظ التوكن في `stores` (لـ Cloud Functions) و`markets` (للتوافق مع النسخة السابقة).
  Future<void> saveTokenForStore(String storeId, {bool force = false}) async {
    // حماية: لا نسمح لأي مستخدم غير صاحب المتجر أن يكتب token داخل مستند المتجر.
    // الخطأ الشائع: عميل يفتح صفحة تمرّر marketId فيكتب token جهازه داخل markets/{storeId}
    // وبذلك تصل إشعارات "طلب جديد" للعميل بدل التاجر.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final marketDoc = await _firestore.collection('markets').doc(storeId).get();
      final ownerId = marketDoc.data()?['ownerId'];
      if (ownerId is! String || ownerId.isEmpty || ownerId != user.uid) {
        debugPrint(
          '⛔ Refused to save store token: user=${user.uid} is not owner of store=$storeId',
        );
        return;
      }
    } catch (e) {
      // لو فشلنا في التحقق لا نكتب التوكن (أماناً).
      debugPrint('⛔ Could not verify store ownership for $storeId: $e');
      return;
    }

    final last = _storeTokenLastWriteAttempt[storeId];
    final nowLocal = DateTime.now();
    if (!force && last != null && nowLocal.difference(last) < _tokenWriteThrottle) {
      return;
    }
    _storeTokenLastWriteAttempt[storeId] = nowLocal;

    _currentToken ??= await _messaging.getToken();

    if (_currentToken == null) {
      debugPrint('⚠️ Could not get FCM token for store $storeId');
      return;
    }

    final now = FieldValue.serverTimestamp();

    try {
      await _firestore.collection('stores').doc(storeId).set({
        'fcmToken': _currentToken,
        'fcmTokenUpdatedAt': now,
      }, SetOptions(merge: true));

      await _firestore.collection('markets').doc(storeId).set({
        'fcmToken': _currentToken,
        'fcmTokenUpdatedAt': now,
      }, SetOptions(merge: true));

      debugPrint('✅ FCM token saved for store: $storeId (stores + markets)');
    } catch (e) {
      debugPrint('❌ Error saving token for store $storeId: $e');
    }
  }

  Future<void> saveTokenForUser(String userId) async {
    final last = _userTokenLastWriteAttempt[userId];
    final nowLocal = DateTime.now();
    if (last != null && nowLocal.difference(last) < _tokenWriteThrottle) {
      return;
    }
    _userTokenLastWriteAttempt[userId] = nowLocal;

    _currentToken ??= await _messaging.getToken();

    if (_currentToken == null) {
      debugPrint('⚠️ Could not get FCM token for user $userId');
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _currentToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ FCM token saved for user: $userId');
    } catch (e) {
      debugPrint('❌ Error saving token for user $userId: $e');
    }
  }

  Future<void> saveTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await saveTokenForUser(user.uid);
    }
  }

  Future<bool> _isUserAuthorizedForStore(String storeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data();
      if (data != null) {
        final mid = data['market_id'] ?? data['marketId'] ?? data['market']?['id'];
        if (mid == storeId) return true;
      }
    } catch (_) {}

    try {
      final marketDoc = await _firestore.collection('markets').doc(storeId).get();
      final ownerId = marketDoc.data()?['ownerId'];
      if (ownerId == user.uid) return true;
    } catch (_) {}

    return false;
  }

  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Foreground FCM: ${message.data}');
    await _routeNewOrderFromData(Map<String, dynamic>.from(message.data));
    _foregroundMessageController.add(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('👆 Notification opened app: ${message.data}');
    await _handleNotificationOpen(Map<String, dynamic>.from(message.data));
    _messageOpenedController.add(message);
  }

  /// فتح التطبيق من الإشعار — الانتقال لشاشة الطلبات فقط (بدون إعادة عرض الحوار).
  Future<void> _handleNotificationOpen(Map<String, dynamic> data) async {
    final type = data[FcmOrderDataKeys.type]?.toString();
    if (type != FcmOrderDataKeys.newOrder) return;

    final storeId = data[FcmOrderDataKeys.storeId]?.toString();
    final orderId = data[FcmOrderDataKeys.orderId]?.toString();
    if (storeId != null && storeId.isNotEmpty) {
      if (!await _isUserAuthorizedForStore(storeId)) {
        debugPrint('⛔ Access denied: Current user is not authorized for store $storeId on notification open.');
        return;
      }
      navigateToStoreOrders(storeId, orderId: orderId);
    }
  }

  Future<void> _routeNewOrderFromData(Map<String, dynamic> data) async {
    final type = data[FcmOrderDataKeys.type]?.toString();
    if (type != FcmOrderDataKeys.newOrder) return;
    final orderId = data[FcmOrderDataKeys.orderId]?.toString() ?? '';
    final storeId = data[FcmOrderDataKeys.storeId]?.toString() ?? '';
    if (orderId.isEmpty || storeId.isEmpty) return;

    if (!await _isUserAuthorizedForStore(storeId)) {
      debugPrint('⛔ Access denied: Current user is not authorized for store $storeId for incoming foreground push.');
      return;
    }

    OrderNotificationCoordinator.instance.notifyNewOrder(
      orderId: orderId,
      storeId: storeId,
    );
  }

  /// لا يُغلق الـ broadcast streams — الخدمة تبقى طوال عمر التطبيق.
  @Deprecated('Singleton مُدارة لعمر التطبيق')
  void dispose() {}
}
