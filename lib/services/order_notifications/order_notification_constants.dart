/// أسماء الحقول وقيم الحالات لمسار `orders` (مستوى جذر Firestore).
abstract class OrderNotificationFields {
  static const id = 'id';
  static const storeId = 'storeId';
  static const userId = 'userId';
  static const status = 'status';
  static const createdAt = 'createdAt';
  static const respondedAt = 'respondedAt';
}

/// حالات سجل الإشعارات — `new` تُستخدَم لاستعلام الاستماع المباشر.
abstract class OrderIndexStatus {
  static const newOrder = 'new';
  static const accepted = 'accepted';
  static const rejected = 'rejected';
}

/// مفاتيح بيانات FCM (قيم نصية فقط في الـ data map).
abstract class FcmOrderDataKeys {
  static const type = 'type';
  static const newOrder = 'NEW_ORDER';
  static const orderId = 'orderId';
  static const storeId = 'storeId';
  static const title = 'title';
  static const body = 'body';
}

/// ملف الصوت داخل [pubspec] — `assets/sounds/notification.mp3`.
const String kOrderAlertAssetPath = 'sounds/notification.mp3';

/// قناة Android لإشعارات الطلبات (تتطابق مع Cloud Function `channelId: "orders"`).
const String kAndroidOrderChannelId = 'orders';
