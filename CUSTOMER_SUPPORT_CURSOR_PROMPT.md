# برومبت تنفيذ مركز المساعدة — التطبيق الرئيسي (بازار السويس)

> **هذا البرومبت موجه لـ Cursor AI لتنفيذ نظام مركز المساعدة داخل التطبيق الرئيسي.**
> التطبيق يخدم: العملاء — التجار — الصنايعية.
> المناديب لهم تطبيق مستقل.

---

## السياق التقني للمشروع

### التقنيات المستخدمة

| العنصر | التقنية |
|--------|---------|
| Framework | Flutter (Dart) |
| State Management | `Provider` + `ChangeNotifier` |
| Routing | `GoRouter` (modular: `routes_config/`) |
| Auth | `AuthGuard` (`ChangeNotifier`) — يحتوي `userStatus`, `isMarketOwner`, `currentUser` |
| Firebase | `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_messaging` |
| Design | `AppColors.mainColor = Color(0xFF4E99B4)` — خط `Tajawal` — RTL افتراضي |
| Locale | `ar` — كل النصوص عربية |
| Widgets | `PrimaryButton`, `AppTextField`, `AppSearchField` |
| Layout | `ShellRoute` → `UserLayout` (bottom nav) / `MarketLayout` |
| Images | `image_picker`, `firebase_storage`, `cached_network_image` |

### ملفات مهمة للرجوع إليها

```
lib/theme/app_color.dart                    → ألوان التطبيق
lib/authentication/guards/AuthGuard.dart    → حالة المستخدم
lib/router/router.dart                      → إعداد الـ router
lib/router/routes_config/shared_routes.dart → المسارات المشتركة
lib/main.dart                               → Providers
lib/widgets/primary_button.dart             → زر أساسي
lib/widgets/app_field.dart                  → حقل إدخال
lib/services/fcm_service.dart               → خدمة الإشعارات
lib/services/review_service.dart            → خدمة التقييمات
lib/models/review_model.dart                → نماذج التقييم
lib/shared/services/user_report_service.dart → خدمة البلاغات
firestore.rules                             → قواعد الأمان
```

### نمط الـ import

```dart
import 'package:bazar_suez/support/models/support_conversation.dart';
```

---

## هيكل المجلدات المطلوب

```
lib/support/
├── models/
│   ├── support_conversation.dart
│   └── support_message.dart
├── services/
│   ├── support_service.dart
│   └── support_image_service.dart
├── viewmodels/
│   └── support_viewmodel.dart
├── pages/
│   ├── support_center_page.dart
│   ├── create_support_request_page.dart
│   └── support_chat_page.dart
└── widgets/
    ├── conversation_card.dart
    ├── conversation_status_badge.dart
    ├── chat_bubble.dart
    ├── chat_input_bar.dart
    ├── system_message_widget.dart
    ├── issue_type_selector.dart
    ├── merchant_picker.dart
    ├── craftsman_picker.dart
    └── driver_picker.dart
```

---

## 1. Models

### `support_conversation.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum IssueType {
  storeIssue,      // مشكلة خاصة بمتجر
  craftsmanIssue,  // مشكلة خاصة بصنايعي
  driverIssue,     // مشكلة خاصة بمندوب
  appIssue,        // مشكلة بالتطبيق
  generalInquiry,  // استفسار عام
}

enum ConversationStatus {
  open,        // مفتوحة
  inProgress,  // جارى المتابعة
  resolved,    // تم الحل
  closed,      // مغلقة
}

class SupportConversation {
  final String id;
  final String userId;
  final String userName;
  final String userType; // customer | merchant | craftsman
  final IssueType issueType;
  final String? relatedMerchantId;
  final String? relatedMerchantName;
  final String? relatedCraftsmanId;
  final String? relatedCraftsmanName;
  final String? relatedDriverId;
  final String? relatedDriverName;
  final String? relatedOrderId;
  final ConversationStatus status;
  final String lastMessage;
  final int unreadAdminCount;
  final int unreadUserCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // constructor, fromFirestore, toFirestore, copyWith

  /// تحويل IssueType لنص عربي للعرض
  String get issueTypeDisplayName {
    switch (issueType) {
      case IssueType.storeIssue: return 'مشكلة خاصة بمتجر';
      case IssueType.craftsmanIssue: return 'مشكلة خاصة بصنايعي';
      case IssueType.driverIssue: return 'مشكلة خاصة بمندوب';
      case IssueType.appIssue: return 'مشكلة بالتطبيق';
      case IssueType.generalInquiry: return 'استفسار عام';
    }
  }

  /// تحويل الحالة لنص عربي
  String get statusDisplayName {
    switch (status) {
      case ConversationStatus.open: return 'مفتوحة';
      case ConversationStatus.inProgress: return 'جارى المتابعة';
      case ConversationStatus.resolved: return 'تم الحل';
      case ConversationStatus.closed: return 'مغلقة';
    }
  }

  /// لون الحالة
  // open → Colors.blue, inProgress → Colors.orange, resolved → Colors.green, closed → Colors.grey
}
```

**تعليمات:**
- استخدم `Timestamp` من Firestore للتحويل.
- `fromFirestore` يستقبل `DocumentSnapshot` أو `Map<String, dynamic>`.
- `toFirestore` يرجع `Map<String, dynamic>` مع `FieldValue.serverTimestamp()` لـ `createdAt` و `updatedAt`.
- أضف `copyWith` للتعديل.
- حول `issueType` و `status` بين `String` و `enum` عبر extension أو static methods.

### `support_message.dart`

```dart
class SupportMessage {
  final String id;
  final String senderId;
  final String senderType; // user | admin | system
  final String? text;
  final String? imageUrl;
  final bool isSystem;
  final DateTime createdAt;

  // constructor, fromFirestore, toFirestore

  bool get isFromUser => senderType == 'user';
  bool get isFromAdmin => senderType == 'admin';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}
```

---

## 2. Services

### `support_service.dart`

```dart
class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'support_conversations';
  static const String _messagesSubcollection = 'messages';

  /// جلب محادثات المستخدم الحالي (Stream)
  Stream<List<SupportConversation>> getUserConversations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportConversation.fromFirestore(doc))
            .toList());
  }

  /// إنشاء محادثة جديدة
  Future<String> createConversation({
    required IssueType issueType,
    required String initialMessage,
    String? imageUrl,
    String? relatedMerchantId,
    String? relatedMerchantName,
    String? relatedCraftsmanId,
    String? relatedCraftsmanName,
    String? relatedDriverId,
    String? relatedDriverName,
    String? relatedOrderId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول');

    // تحديد نوع المستخدم من AuthGuard أو user document
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final userStatus = userData['status'] ?? 'user';
    
    String userType;
    if (userStatus == 'market_owner') {
      userType = 'merchant';
    } else {
      // تحقق هل هو صنايعي
      final craftsmanDoc = await _firestore.collection('craftsmen').doc(user.uid).get();
      userType = craftsmanDoc.exists ? 'craftsman' : 'customer';
    }

    final conversationRef = _firestore.collection(_collection).doc();
    final conversationId = conversationRef.id;

    final conversationData = {
      'id': conversationId,
      'userId': user.uid,
      'userName': user.displayName ?? 'مستخدم',
      'userType': userType,
      'issueType': issueType.name, // storeIssue, craftsmanIssue, etc.
      'relatedMerchantId': relatedMerchantId ?? '',
      'relatedMerchantName': relatedMerchantName ?? '',
      'relatedCraftsmanId': relatedCraftsmanId ?? '',
      'relatedCraftsmanName': relatedCraftsmanName ?? '',
      'relatedDriverId': relatedDriverId ?? '',
      'relatedDriverName': relatedDriverName ?? '',
      'relatedOrderId': relatedOrderId ?? '',
      'status': 'open',
      'lastMessage': initialMessage,
      'unreadAdminCount': 1,
      'unreadUserCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1. إنشاء المحادثة
    await conversationRef.set(conversationData);

    // 2. إرسال الرسالة الأولى من المستخدم
    await _sendMessage(
      conversationId: conversationId,
      text: initialMessage,
      imageUrl: imageUrl,
      senderType: 'user',
    );

    // 3. إرسال رسالة النظام التلقائية
    await _sendMessage(
      conversationId: conversationId,
      text: 'شكراً لتواصلك مع بازار السويس.\n\nتم استلام رسالتك وسيتم مراجعتها والرد عليك فى أقرب وقت ممكن.',
      senderType: 'system',
      isSystem: true,
    );

    return conversationId;
  }

  /// إرسال رسالة
  Future<void> sendMessage({
    required String conversationId,
    String? text,
    String? imageUrl,
  }) async {
    await _sendMessage(
      conversationId: conversationId,
      text: text,
      imageUrl: imageUrl,
      senderType: 'user',
    );

    // تحديث آخر رسالة + عداد غير المقروءة
    await _firestore.collection(_collection).doc(conversationId).update({
      'lastMessage': text ?? '📷 صورة',
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadAdminCount': FieldValue.increment(1),
    });
  }

  Future<void> _sendMessage({
    required String conversationId,
    String? text,
    String? imageUrl,
    required String senderType,
    bool isSystem = false,
  }) async {
    final user = _auth.currentUser;
    final messageRef = _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': isSystem ? 'system' : (user?.uid ?? ''),
      'senderType': senderType,
      'text': text ?? '',
      'imageUrl': imageUrl ?? '',
      'isSystem': isSystem,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// جلب رسائل محادثة (Stream)
  Stream<List<SupportMessage>> getMessages(String conversationId) {
    return _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportMessage.fromFirestore(doc))
            .toList());
  }

  /// تصفير عداد غير المقروءة للمستخدم
  Future<void> markAsRead(String conversationId) async {
    await _firestore.collection(_collection).doc(conversationId).update({
      'unreadUserCount': 0,
    });
  }

  /// جلب آخر المتاجر التى تعامل معها المستخدم
  Future<List<Map<String, dynamic>>> getRecentMerchants() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final ordersSnap = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final seen = <String>{};
    final merchants = <Map<String, dynamic>>[];

    for (final doc in ordersSnap.docs) {
      final data = doc.data();
      final storeId = data['storeId']?.toString() ?? '';
      final storeName = data['storeName']?.toString() ?? '';
      if (storeId.isNotEmpty && !seen.contains(storeId)) {
        seen.add(storeId);
        // جلب صورة المتجر
        String? storeImage;
        try {
          final marketDoc = await _firestore.collection('markets').doc(storeId).get();
          storeImage = marketDoc.data()?['imageUrl']?.toString();
        } catch (_) {}
        merchants.add({
          'id': storeId,
          'name': storeName,
          'imageUrl': storeImage ?? '',
        });
      }
      if (merchants.length >= 10) break;
    }

    return merchants;
  }

  /// جلب آخر المناديب المرتبطين بطلبات المستخدم
  Future<List<Map<String, dynamic>>> getRecentDrivers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final ordersSnap = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();

    final seen = <String>{};
    final drivers = <Map<String, dynamic>>[];

    for (final doc in ordersSnap.docs) {
      final data = doc.data();
      final deliveryRequest = data['deliveryRequest'] as Map<String, dynamic>?;
      final driverId = (data['assignedCourierId'] ??
              deliveryRequest?['courierId'] ??
              deliveryRequest?['driverId'] ??
              '')
          .toString();
      final driverName = (deliveryRequest?['assignedDriverName'] ??
              deliveryRequest?['driverName'] ??
              data['assignedDriverName'] ??
              '')
          .toString();

      if (driverId.isNotEmpty && driverName.isNotEmpty && !seen.contains(driverId)) {
        seen.add(driverId);
        drivers.add({
          'id': driverId,
          'name': driverName,
        });
      }
      if (drivers.length >= 10) break;
    }

    return drivers;
  }

  /// بحث في الصنايعية
  Future<List<Map<String, dynamic>>> searchCraftsmen(String query) async {
    if (query.trim().isEmpty) return [];

    final snap = await _firestore
        .collection('craftsmen')
        .where('visibility', isEqualTo: 'public')
        .limit(20)
        .get();

    // فلتر محلي بالاسم أو المهنة
    return snap.docs
        .where((doc) {
          final data = doc.data();
          final name = (data['name'] ?? '').toString().toLowerCase();
          final profession = (data['professionName'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || profession.contains(q);
        })
        .map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? '',
            'professionName': data['professionName'] ?? '',
            'imageUrl': data['profileImageUrl'] ?? data['imageUrl'] ?? '',
          };
        })
        .toList();
  }
}
```

### `support_image_service.dart`

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class SupportImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// اختيار صورة من المعرض
  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// اختيار صورة من الكاميرا
  Future<File?> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// رفع صورة إلى Firebase Storage
  Future<String> uploadImage(File file, String conversationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref('support_images/$conversationId/$fileName');
    
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    
    return await uploadTask.ref.getDownloadURL();
  }
}
```

---

## 3. ViewModel

### `support_viewmodel.dart`

```dart
import 'package:flutter/material.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';
import 'package:bazar_suez/support/services/support_service.dart';

class SupportViewModel extends ChangeNotifier {
  final SupportService _service = SupportService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// إنشاء محادثة دعم جديدة
  Future<String?> createConversation({
    required IssueType issueType,
    required String message,
    String? imageUrl,
    String? relatedMerchantId,
    String? relatedMerchantName,
    String? relatedCraftsmanId,
    String? relatedCraftsmanName,
    String? relatedDriverId,
    String? relatedDriverName,
    String? relatedOrderId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _service.createConversation(
        issueType: issueType,
        initialMessage: message,
        imageUrl: imageUrl,
        relatedMerchantId: relatedMerchantId,
        relatedMerchantName: relatedMerchantName,
        relatedCraftsmanId: relatedCraftsmanId,
        relatedCraftsmanName: relatedCraftsmanName,
        relatedDriverId: relatedDriverId,
        relatedDriverName: relatedDriverName,
        relatedOrderId: relatedOrderId,
      );
      return id;
    } catch (e) {
      _error = 'حدث خطأ أثناء إنشاء المحادثة';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**سجّل الـ ViewModel في `main.dart`:**

```dart
ChangeNotifierProvider(create: (_) => SupportViewModel()),
```

---

## 4. الشاشات (Pages)

### `support_center_page.dart` — شاشة مركز المساعدة

**التصميم:**
- `Directionality(textDirection: TextDirection.rtl, ...)`
- `AppBar` مع عنوان "مركز المساعدة" وخلفية بيضاء
- `StreamBuilder` لعرض المحادثات
- لكل محادثة: `ConversationCard` يعرض:
  - نوع المشكلة (أيقونة + نص)
  - آخر رسالة
  - تاريخ آخر تحديث (منذ ...)
  - حالة المحادثة (badge ملون)
  - عدد الرسائل غير المقروءة
- إذا لا توجد محادثات: عرض حالة فارغة (أيقونة + نص)
- `FloatingActionButton` أو زر كبير: "إنشاء طلب دعم جديد"

**الألوان:**
- `AppColors.mainColor` للعناصر الأساسية
- خلفية: `Color(0xFFF5F6FA)`
- كروت: بيضاء مع ظل خفيف وزوايا مستديرة 16

**عند الضغط على محادثة:** الانتقال لـ `SupportChatPage`
**عند الضغط على "إنشاء طلب":** الانتقال لـ `CreateSupportRequestPage`

---

### `create_support_request_page.dart` — إنشاء طلب دعم

**التدفق:**

#### المرحلة 1: اختيار نوع المشكلة

عرض `IssueTypeSelector` — قائمة أنواع المشاكل:

```
مشكلة خاصة بمتجر        → Icons.store_outlined
مشكلة خاصة بصنايعي      → Icons.construction_outlined
مشكلة خاصة بمندوب       → Icons.delivery_dining_outlined
مشكلة بالتطبيق           → Icons.phone_android_outlined
استفسار عام              → Icons.help_outline
```

كل نوع يظهر في كارت قابل للضغط (ليس dropdown) بتصميم أنيق.

#### المرحلة 2: حسب النوع

**مشكلة خاصة بمتجر:**
1. جلب `getRecentMerchants()` وعرضها كـ horizontal list
   - صورة المتجر (دائرية)
   - اسم المتجر
   - عند الاختيار يتم تحديده بحدود `AppColors.mainColor`
2. بعد الاختيار:
   - حقل "وصف المشكلة" (multiline, required)
   - زر "إرفاق صورة" (اختياري)
   - زر "إرسال"

**مشكلة خاصة بصنايعي:**
1. مربع بحث (debounce 500ms)
2. أثناء الكتابة: عرض النتائج
   - صورة الصنايعي
   - اسم الصنايعي
   - المهنة
3. بعد الاختيار: نفس حقول الوصف + صورة

**مشكلة خاصة بمندوب:**
1. جلب `getRecentDrivers()` وعرضهم
   - اسم المندوب
   - أيقونة delivery_dining
2. بعد الاختيار: وصف المشكلة + إرسال

**مشكلة بالتطبيق:**
- وصف المشكلة (required)
- صورة اختيارية
- إرسال

**استفسار عام:**
- نص الرسالة فقط (required)
- إرسال

#### بعد الإرسال بنجاح:
- عرض `SnackBar`: "تم إرسال طلب الدعم بنجاح"
- الانتقال مباشرة لشاشة المحادثة `SupportChatPage`

---

### `support_chat_page.dart` — شاشة المحادثة

**التصميم مشابه لتطبيقات المراسلة (WhatsApp style):**

**AppBar:**
- عنوان: نوع المشكلة
- subtitle: حالة المحادثة (badge)
- إذا كان هناك related entity: عرض اسمه

**Body:**
- `StreamBuilder` لرسائل المحادثة
- `ListView.builder` (reversed) لعرض الرسائل
- كل رسالة: `ChatBubble`

**أنواع الفقاعات:**

1. **رسالة المستخدم** (يمين — لأن RTL):
   - خلفية: `AppColors.mainColor`
   - نص أبيض
   - وقت الإرسال أسفل

2. **رسالة الإدارة** (يسار):
   - خلفية: `Color(0xFFE8E8E8)`
   - نص أسود
   - label "الإدارة" أعلى الفقاعة
   - وقت الإرسال أسفل

3. **رسالة النظام** (وسط):
   - خلفية: `Color(0xFFFFF3CD)` أو شفافة
   - نص بحجم أصغر
   - أيقونة info

4. **صورة:**
   - عرض الصورة بحجم مناسب داخل الفقاعة
   - عند الضغط: فتح الصورة بحجم كامل (Dialog أو page)

**شريط الإدخال (Bottom):**
- `TextField` مع `maxLines: 5`
- زر إرفاق صورة (📎)
  - عند الضغط: `showModalBottomSheet` → الكاميرا أو المعرض
- زر إرسال (▶️) — يظهر فقط عند وجود نص أو صورة
- إذا المحادثة `closed` أو `resolved`: عرض رسالة "تم إغلاق هذه المحادثة"

**عند فتح الشاشة:**
- استدعاء `markAsRead(conversationId)` لتصفير عداد غير المقروءة

---

## 5. Widgets

### `conversation_card.dart`

```
┌─────────────────────────────────────┐
│ 🏪 مشكلة خاصة بمتجر         مفتوحة│
│ متجر أبو على                       │
│ ─────────────────────────────────── │
│ المشكلة إن المنتج وصل تالف...      │
│                        منذ ساعتين  │
│                               ● 2  │
└─────────────────────────────────────┘
```

- أيقونة حسب `issueType`
- اسم الـ related entity (إن وجد)
- آخر رسالة (سطر واحد مع `overflow: ellipsis`)
- الوقت النسبي ("منذ 5 دقائق", "منذ ساعتين", "أمس")
- badge عدد الرسائل غير المقروءة (`unreadUserCount > 0`)
- `ConversationStatusBadge` (ملون)

### `conversation_status_badge.dart`

حالة المحادثة في chip ملون:
- مفتوحة → أزرق
- جارى المتابعة → برتقالي
- تم الحل → أخضر
- مغلقة → رمادي

### `chat_bubble.dart`

فقاعة رسالة واحدة مع:
- `Align` حسب `senderType`
- `Container` مع `borderRadius` مخصص (زاوية واحدة مختلفة)
- عرض النص + الوقت
- عرض الصورة إذا وجدت
- خاص بـ system messages: تصميم مختلف

### `chat_input_bar.dart`

شريط الإدخال أسفل الشاشة:
- `Container` مع ظل علوي
- `Row` → أيقونة صورة + TextField + زر إرسال
- يدعم إرفاق صورة (preview قبل الإرسال)

### `issue_type_selector.dart`

Grid أو ListView من كروت الأنواع (2 في الصف):
```
┌──────────┐  ┌──────────┐
│  🏪      │  │  🔧      │
│ مشكلة    │  │ مشكلة    │
│ بمتجر    │  │ بصنايعي  │
└──────────┘  └──────────┘
```

### `merchant_picker.dart`

Horizontal scrollable list:
- `CircleAvatar` مع صورة المتجر
- اسم المتجر تحته
- حدود `AppColors.mainColor` عند الاختيار

### `craftsman_picker.dart`

- حقل بحث أعلى
- أسفله: قائمة النتائج
- كل نتيجة: صورة + اسم + مهنة

### `driver_picker.dart`

- قائمة المناديب (vertical list)
- كل عنصر: أيقونة + اسم المندوب
- حدود عند الاختيار

---

## 6. التوجيه (Routes)

### إضافة في `shared_routes.dart`:

```dart
import 'package:bazar_suez/support/pages/support_center_page.dart';
import 'package:bazar_suez/support/pages/create_support_request_page.dart';
import 'package:bazar_suez/support/pages/support_chat_page.dart';

// أضف داخل sharedRoutes:
GoRoute(
  path: '/support',
  builder: (_, __) => const SupportCenterPage(),
),
GoRoute(
  path: '/support/create',
  builder: (context, state) {
    // يمكن تمرير issueType و relatedId مسبقاً (للإبلاغ من التقييم)
    final issueType = state.uri.queryParameters['issueType'];
    final relatedId = state.uri.queryParameters['relatedId'];
    final relatedName = state.uri.queryParameters['relatedName'];
    return CreateSupportRequestPage(
      preselectedIssueType: issueType,
      preselectedRelatedId: relatedId,
      preselectedRelatedName: relatedName,
    );
  },
),
GoRoute(
  path: '/support/chat/:conversationId',
  builder: (context, state) {
    return SupportChatPage(
      conversationId: state.pathParameters['conversationId']!,
    );
  },
),
```

### إضافة في `router.dart` — المسارات المحمية:

```dart
// أضف '/support' للمسارات المحمية:
const protectedPaths = [
  // ... الموجودة حالياً
  '/support',
];
```

---

## 7. التقييم والإبلاغ

### دمج مع نظام التقييم الحالي

في dialog تقييم المتجر (الموجود حالياً في `user_order_card.dart` أو ما يعادله):

**أضف زر "الإبلاغ عن المتجر"** أسفل التقييم:

```dart
TextButton.icon(
  onPressed: () {
    Navigator.pop(context); // إغلاق dialog التقييم
    context.push(
      '/support/create?issueType=storeIssue&relatedId=$storeId&relatedName=$storeName',
    );
  },
  icon: const Icon(Icons.flag_outlined, color: Colors.red),
  label: const Text('الإبلاغ عن المتجر', style: TextStyle(color: Colors.red)),
),
```

في dialog تقييم المندوب:

**أضف زر "الإبلاغ عن المندوب":**

```dart
TextButton.icon(
  onPressed: () {
    Navigator.pop(context);
    context.push(
      '/support/create?issueType=driverIssue&relatedId=$driverId&relatedName=$driverName',
    );
  },
  icon: const Icon(Icons.flag_outlined, color: Colors.red),
  label: const Text('الإبلاغ عن المندوب', style: TextStyle(color: Colors.red)),
),
```

---

## 8. الوصول لمركز المساعدة

### من صفحة الحساب (`AccountPage`):

أضف عنصر في قائمة الحساب:

```dart
ListTile(
  leading: Icon(Icons.support_agent, color: AppColors.mainColor),
  title: const Text('مركز المساعدة'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => context.push('/support'),
),
```

---

## 9. قواعد Firestore

**أضف في `firestore.rules` قبل `match /{document=**}`:**

```javascript
// ============================================================================
// SUPPORT CONVERSATIONS
// ============================================================================

match /support_conversations/{conversationId} {
  // القراءة: صاحب المحادثة أو الإدارة
  allow read: if isAuthenticated() && (
    resource.data.userId == request.auth.uid || isAdmin()
  );
  
  // الإنشاء: مستخدم مسجل — userId يساوي المستخدم الحالي
  allow create: if isAuthenticated() && 
    request.resource.data.userId == request.auth.uid;
  
  // التحديث: صاحب المحادثة (لتصفير unreadUserCount) أو الإدارة
  allow update: if isAuthenticated() && (
    resource.data.userId == request.auth.uid || isAdmin()
  );
  
  // الحذف: super admin فقط
  allow delete: if isSuperAdmin();
  
  // الرسائل
  match /messages/{messageId} {
    allow read: if isAuthenticated() && (
      get(/databases/$(database)/documents/support_conversations/$(conversationId)).data.userId == request.auth.uid ||
      isAdmin()
    );
    
    allow create: if isAuthenticated() && (
      get(/databases/$(database)/documents/support_conversations/$(conversationId)).data.userId == request.auth.uid ||
      isAdmin()
    );
    
    allow update, delete: if false;
  }
}
```

---

## 10. Firestore Indexes

**أضف في `firestore.indexes.json`:**

```json
{
  "collectionGroup": "support_conversations",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```

---

## 11. Cloud Function — إشعار رد الإدارة

**أنشئ `functions/src/notifications/sendSupportNotification.ts`:**

```typescript
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

/**
 * عند إضافة رسالة جديدة من الإدارة في محادثة دعم
 * يتم إرسال إشعار FCM للمستخدم
 */
export const sendSupportReplyNotification = onDocumentCreated(
  {
    document: "support_conversations/{conversationId}/messages/{messageId}",
    region: "europe-west1",
  },
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    // فقط رسائل الإدارة
    if (messageData.senderType !== "admin") return;

    const conversationId = event.params.conversationId;
    const db = getFirestore();
    
    // جلب بيانات المحادثة
    const conversationDoc = await db
      .collection("support_conversations")
      .doc(conversationId)
      .get();
    
    if (!conversationDoc.exists) return;
    
    const conversationData = conversationDoc.data()!;
    const userId = conversationData.userId;

    // جلب FCM token للمستخدم
    const userDoc = await db.collection("users").doc(userId).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return;
    }

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: {
          title: "بازار السويس - الدعم",
          body: "تم الرد على طلب الدعم الخاص بك.",
        },
        data: {
          type: "support_reply",
          conversationId: conversationId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "support_channel",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });
      console.log(`✅ Support notification sent to user ${userId}`);
    } catch (error) {
      console.error(`❌ Error sending support notification:`, error);
    }
  }
);
```

**أضف في `functions/src/index.ts`:**

```typescript
import { sendSupportReplyNotification } from "./notifications/sendSupportNotification";

// بعد exports الموجودة:
export { sendSupportReplyNotification };
```

---

## 12. خارطة التنفيذ (Roadmap)

### المرحلة 1: الأساسيات
1. ✅ إنشاء مجلد `lib/support/`
2. ✅ إنشاء `models/` — `SupportConversation` + `SupportMessage`
3. ✅ إنشاء `services/support_service.dart`
4. ✅ إنشاء `services/support_image_service.dart`
5. ✅ إنشاء `viewmodels/support_viewmodel.dart`

### المرحلة 2: الشاشات
6. ✅ إنشاء `support_center_page.dart`
7. ✅ إنشاء `create_support_request_page.dart` (مع كل أنواع المشاكل)
8. ✅ إنشاء `support_chat_page.dart`

### المرحلة 3: Widgets
9. ✅ إنشاء `conversation_card.dart`
10. ✅ إنشاء `chat_bubble.dart` + `chat_input_bar.dart`
11. ✅ إنشاء `issue_type_selector.dart`
12. ✅ إنشاء `merchant_picker.dart`, `craftsman_picker.dart`, `driver_picker.dart`

### المرحلة 4: الربط
13. ✅ إضافة Routes في `shared_routes.dart`
14. ✅ تسجيل ViewModel في `main.dart`
15. ✅ إضافة رابط في `AccountPage`
16. ✅ إضافة أزرار الإبلاغ في dialogs التقييم

### المرحلة 5: Firebase
17. ✅ تحديث `firestore.rules`
18. ✅ إضافة Firestore indexes
19. ✅ إنشاء Cloud Function للإشعارات

---

## ملاحظات تصميمية مهمة

1. **RTL**: كل الشاشات ملفوفة بـ `Directionality(textDirection: TextDirection.rtl)`
2. **الألوان**: استخدم `AppColors.mainColor` كلون أساسي — لا تستخدم ألوان random
3. **الخطوط**: `fontFamily: 'Tajawal'` أو `GoogleFonts.cairo()` حسب النمط الموجود
4. **Loading**: استخدم `CircularProgressIndicator(color: AppColors.mainColor)`
5. **Empty States**: أيقونة كبيرة + نص وصفي (نفس نمط `UserOrdersPage`)
6. **Error Handling**: `try/catch` مع رسائل عربية واضحة
7. **Spacing**: `EdgeInsets.all(16)` أو `fromLTRB(14, 0, 14, 32)` حسب النمط
8. **Cards**: `BoxDecoration(borderRadius: 16, boxShadow: subtle, color: white)`
9. **الأزرار**: استخدم `PrimaryButton` الموجود للأزرار الرئيسية
10. **الحقول**: استخدم `AppTextField` الموجود لحقول الإدخال
