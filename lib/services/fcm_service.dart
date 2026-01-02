import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Background message handler - يجب أن يكون top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📬 Background message received: ${message.notification?.title}');
}

/// خدمة إدارة FCM للإشعارات
/// تتعامل مع التوكنات والإشعارات للتاجر والعميل
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentToken;
  String? get currentToken => _currentToken;

  // StreamControllers للتعامل مع الإشعارات في أماكن أخرى من التطبيق
  static final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  static final StreamController<RemoteMessage> _messageOpenedController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream للرسائل في المقدمة
  Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundMessageController.stream;

  /// Stream للضغط على الإشعارات
  Stream<RemoteMessage> get onMessageOpened => _messageOpenedController.stream;

  /// تهيئة خدمة FCM
  Future<void> initialize() async {
    try {
      // تسجيل معالج الرسائل في الخلفية
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // طلب صلاحيات الإشعارات
      await _requestPermission();

      // الحصول على التوكن وحفظه
      _currentToken = await _messaging.getToken();
      debugPrint('🔔 FCM Token: $_currentToken');

      // الاستماع لتغيير التوكن (يحدث عند إعادة تثبيت التطبيق أو مسح البيانات)
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // التعامل مع الرسائل في المقدمة
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // التعامل مع الضغط على الإشعار (التطبيق كان في الخلفية)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // التحقق من وجود إشعار أولي (التطبيق كان مغلقاً)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      debugPrint('✅ FCM Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
    }
  }

  /// طلب صلاحيات الإشعارات
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

  /// معالجة تغيير التوكن
  void _onTokenRefresh(String newToken) {
    debugPrint('🔄 FCM Token refreshed: $newToken');
    _currentToken = newToken;
    
    // تحديث التوكن في قاعدة البيانات للمتجر والمستخدم الحالي
    _updateStoredTokens(newToken);
  }

  /// تحديث التوكنات المخزنة في قاعدة البيانات
  Future<void> _updateStoredTokens(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // تحديث توكن المستخدم
      await saveTokenForUser(user.uid);

      // البحث عن المتاجر المملوكة لهذا المستخدم وتحديث توكناتها
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

  /// حفظ التوكن لمتجر معين
  Future<void> saveTokenForStore(String storeId) async {
    _currentToken ??= await _messaging.getToken();

    if (_currentToken == null) {
      debugPrint('⚠️ Could not get FCM token for store $storeId');
      return;
    }

    try {
      await _firestore.collection('markets').doc(storeId).update({
        'fcmToken': _currentToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ FCM token saved for store: $storeId');
    } catch (e) {
      debugPrint('❌ Error saving token for store $storeId: $e');
    }
  }

  /// حفظ التوكن للمستخدم الحالي
  Future<void> saveTokenForUser(String userId) async {
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

  /// حفظ التوكن للمستخدم الحالي تلقائياً
  Future<void> saveTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await saveTokenForUser(user.uid);
    }
  }

  /// معالجة الرسائل في المقدمة (التطبيق مفتوح)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground message received:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // إرسال الرسالة للـ Stream ليتم التعامل معها في أماكن أخرى
    _foregroundMessageController.add(message);
  }

  /// معالجة الضغط على الإشعار
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 Message opened app:');
    debugPrint('   Data: ${message.data}');

    final type = message.data['type'];
    final orderId = message.data['orderId'];
    final storeId = message.data['storeId'];

    debugPrint('   Type: $type, OrderId: $orderId, StoreId: $storeId');

    // إرسال الرسالة للـ Stream ليتم التعامل معها في أماكن أخرى
    _messageOpenedController.add(message);
  }

  /// إغلاق الـ Streams
  void dispose() {
    _foregroundMessageController.close();
    _messageOpenedController.close();
  }
}
