# برومبت تنفيذ مركز المساعدة — تطبيق المناديب (بازار السويس)

> **هذا البرومبت موجه لـ Cursor AI لتنفيذ نظام مركز المساعدة داخل تطبيق المناديب.**
> المندوب يستطيع: إنشاء محادثات دعم — الإبلاغ عن عملاء/تجار — مشاكل تقنية — إرسال صور — استلام ردود الإدارة — إشعارات.

---

## السياق التقني

### ملاحظة مهمة

تطبيق المناديب مستقل عن التطبيق الرئيسي لكنه يشارك نفس مشروع Firebase.

يجب أن يستخدم **نفس Firestore collection** (`support_conversations`) ونفس الـ **structure** بالضبط لضمان التوافق مع التطبيق الرئيسي ولوحة الإدارة.

### التقنيات (متوقعة — تأكد من المشروع الفعلي)

| العنصر | التقنية |
|--------|---------|
| Framework | Flutter (Dart) |
| State Management | `Provider` + `ChangeNotifier` (أو ما يستخدمه التطبيق) |
| Firebase | `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_messaging` |
| Design | نفس `AppColors` أو مشابه — RTL افتراضي |
| Locale | `ar` — كل النصوص عربية |

---

## هيكل Firestore الموحد (نفس التطبيق الرئيسي بالضبط)

```
support_conversations/{conversationId}
├── id: string
├── userId: string
├── userName: string
├── userType: "driver"                      ← الفرق الوحيد
├── issueType: string
│   ├── "customer_issue"                    ← مشكلة خاصة بعميل
│   ├── "store_issue"                       ← مشكلة خاصة بمتجر
│   ├── "app_issue"                         ← مشكلة بالتطبيق
│   └── "general_inquiry"                   ← استفسار عام
├── relatedMerchantId: string?
├── relatedMerchantName: string?
├── relatedCraftsmanId: string?             ← لا يُستخدم (فارغ)
├── relatedCraftsmanName: string?           ← لا يُستخدم (فارغ)
├── relatedDriverId: string?               ← لا يُستخدم (فارغ — المندوب هو المستخدم)
├── relatedDriverName: string?             ← لا يُستخدم (فارغ)
├── relatedCustomerId: string?             ← العميل المرتبط
├── relatedCustomerName: string?           ← اسم العميل المرتبط
├── relatedOrderId: string?
├── status: string (open | in_progress | resolved | closed)
├── lastMessage: string
├── unreadAdminCount: number
├── unreadUserCount: number
├── createdAt: Timestamp
├── updatedAt: Timestamp
│
└── messages/{messageId}
    ├── id: string
    ├── senderId: string
    ├── senderType: string (user | admin | system)
    ├── text: string?
    ├── imageUrl: string?
    ├── isSystem: boolean
    ├── createdAt: Timestamp
```

> **ملاحظة:** المندوب عند إنشاء محادثة يكون `userType = "driver"` و `userId` = uid المندوب.
> عند الإبلاغ عن عميل: يُحفظ `relatedCustomerId` و `relatedCustomerName` (حقل إضافي).
> عند الإبلاغ عن متجر: يُحفظ `relatedMerchantId` و `relatedMerchantName`.

---

## هيكل المجلدات المطلوب

```
lib/support/
├── models/
│   ├── support_conversation.dart
│   └── support_message.dart
├── services/
│   ├── driver_support_service.dart
│   └── support_image_service.dart
├── viewmodels/
│   └── driver_support_viewmodel.dart
├── pages/
│   ├── driver_support_center_page.dart
│   ├── driver_create_support_page.dart
│   └── driver_support_chat_page.dart
└── widgets/
    ├── conversation_card.dart
    ├── conversation_status_badge.dart
    ├── chat_bubble.dart
    ├── chat_input_bar.dart
    ├── system_message_widget.dart
    ├── issue_type_selector.dart
    ├── customer_picker.dart
    └── merchant_picker.dart
```

---

## 1. Models

### `support_conversation.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum DriverIssueType {
  customerIssue,    // مشكلة خاصة بعميل
  storeIssue,       // مشكلة خاصة بمتجر
  appIssue,         // مشكلة بالتطبيق
  generalInquiry,   // استفسار عام
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
  final String userType; // دائماً "driver"
  final DriverIssueType issueType;
  final String? relatedMerchantId;
  final String? relatedMerchantName;
  final String? relatedCustomerId;
  final String? relatedCustomerName;
  final String? relatedOrderId;
  final ConversationStatus status;
  final String lastMessage;
  final int unreadAdminCount;
  final int unreadUserCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // constructor, fromFirestore, toFirestore, copyWith

  String get issueTypeDisplayName {
    switch (issueType) {
      case DriverIssueType.customerIssue: return 'مشكلة خاصة بعميل';
      case DriverIssueType.storeIssue: return 'مشكلة خاصة بمتجر';
      case DriverIssueType.appIssue: return 'مشكلة بالتطبيق';
      case DriverIssueType.generalInquiry: return 'استفسار عام';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ConversationStatus.open: return 'مفتوحة';
      case ConversationStatus.inProgress: return 'جارى المتابعة';
      case ConversationStatus.resolved: return 'تم الحل';
      case ConversationStatus.closed: return 'مغلقة';
    }
  }
}
```

**تعليمات:**
- `fromFirestore`: تحويل `issueType` من string إلى enum مع fallback
- `toFirestore`: تحويل enum لـ string (`customerIssue` → `"customer_issue"`)
- عند القراءة من Firestore: تعامل مع القيم null بأمان

### `support_message.dart`

نفس model التطبيق الرئيسي بالضبط:

```dart
class SupportMessage {
  final String id;
  final String senderId;
  final String senderType; // user | admin | system
  final String? text;
  final String? imageUrl;
  final bool isSystem;
  final DateTime createdAt;

  bool get isFromUser => senderType == 'user';
  bool get isFromAdmin => senderType == 'admin';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}
```

---

## 2. Services

### `driver_support_service.dart`

```dart
class DriverSupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'support_conversations';
  static const String _messagesSubcollection = 'messages';

  /// جلب محادثات المندوب الحالي (Stream)
  Stream<List<SupportConversation>> getDriverConversations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .where('userType', isEqualTo: 'driver')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportConversation.fromFirestore(doc))
            .toList());
  }

  /// إنشاء محادثة جديدة
  Future<String> createConversation({
    required DriverIssueType issueType,
    required String initialMessage,
    String? imageUrl,
    String? relatedMerchantId,
    String? relatedMerchantName,
    String? relatedCustomerId,
    String? relatedCustomerName,
    String? relatedOrderId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول');

    // جلب اسم المندوب
    String driverName = user.displayName ?? '';
    if (driverName.isEmpty) {
      // جلب من courier_requests
      final courierDoc = await _firestore
          .collection('courier_requests')
          .doc(user.uid)
          .get();
      driverName = courierDoc.data()?['name'] ?? 'مندوب';
    }

    final conversationRef = _firestore.collection(_collection).doc();
    final conversationId = conversationRef.id;

    // تحويل issueType لـ string
    String issueTypeStr;
    switch (issueType) {
      case DriverIssueType.customerIssue: issueTypeStr = 'customer_issue'; break;
      case DriverIssueType.storeIssue: issueTypeStr = 'store_issue'; break;
      case DriverIssueType.appIssue: issueTypeStr = 'app_issue'; break;
      case DriverIssueType.generalInquiry: issueTypeStr = 'general_inquiry'; break;
    }

    final conversationData = {
      'id': conversationId,
      'userId': user.uid,
      'userName': driverName,
      'userType': 'driver',
      'issueType': issueTypeStr,
      'relatedMerchantId': relatedMerchantId ?? '',
      'relatedMerchantName': relatedMerchantName ?? '',
      'relatedCraftsmanId': '',
      'relatedCraftsmanName': '',
      'relatedDriverId': '',
      'relatedDriverName': '',
      'relatedCustomerId': relatedCustomerId ?? '',
      'relatedCustomerName': relatedCustomerName ?? '',
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

    // 2. إرسال الرسالة الأولى
    await _sendMessage(
      conversationId: conversationId,
      text: initialMessage,
      imageUrl: imageUrl,
      senderType: 'user',
    );

    // 3. رسالة النظام التلقائية
    await _sendMessage(
      conversationId: conversationId,
      text: 'شكراً لتواصلك مع بازار السويس.\n\nتم استلام رسالتك وسيتم مراجعتها والرد عليك فى أقرب وقت ممكن.',
      senderType: 'system',
      isSystem: true,
    );

    return conversationId;
  }

  /// إرسال رسالة في محادثة موجودة
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

  /// تصفير عداد غير المقروءة
  Future<void> markAsRead(String conversationId) async {
    await _firestore.collection(_collection).doc(conversationId).update({
      'unreadUserCount': 0,
    });
  }

  /// جلب آخر العملاء من طلبات المندوب
  Future<List<Map<String, dynamic>>> getRecentCustomers() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    // البحث في الطلبات المرتبطة بالمندوب
    final ordersSnap = await _firestore
        .collection('orders')
        .where('assignedCourierId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final seen = <String>{};
    final customers = <Map<String, dynamic>>[];

    for (final doc in ordersSnap.docs) {
      final data = doc.data();
      final customerId = data['userId']?.toString() ?? '';
      final customerName = data['userName']?.toString() ?? 
                           data['customerName']?.toString() ?? '';
      
      if (customerId.isNotEmpty && customerName.isNotEmpty && !seen.contains(customerId)) {
        seen.add(customerId);
        customers.add({
          'id': customerId,
          'name': customerName,
        });
      }
      if (customers.length >= 10) break;
    }

    // لو ما لقينا بـ assignedCourierId، نجرب بـ deliveryRequest.courierId
    if (customers.isEmpty) {
      final altSnap = await _firestore
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      for (final doc in altSnap.docs) {
        final data = doc.data();
        final deliveryRequest = data['deliveryRequest'] as Map<String, dynamic>?;
        final courierId = (deliveryRequest?['courierId'] ?? 
                          deliveryRequest?['driverId'] ?? '').toString();
        
        if (courierId == uid) {
          final customerId = data['userId']?.toString() ?? '';
          final customerName = data['userName']?.toString() ?? '';
          
          if (customerId.isNotEmpty && !seen.contains(customerId)) {
            seen.add(customerId);
            customers.add({
              'id': customerId,
              'name': customerName,
            });
          }
        }
        if (customers.length >= 10) break;
      }
    }

    return customers;
  }

  /// جلب آخر المتاجر من طلبات المندوب
  Future<List<Map<String, dynamic>>> getRecentMerchants() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final ordersSnap = await _firestore
        .collection('orders')
        .where('assignedCourierId', isEqualTo: uid)
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
}
```

### `support_image_service.dart`

نفس خدمة التطبيق الرئيسي بالضبط:

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class SupportImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024, maxHeight: 1024, imageQuality: 75,
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<File?> takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024, maxHeight: 1024, imageQuality: 75,
    );
    return picked != null ? File(picked.path) : null;
  }

  Future<String> uploadImage(File file, String conversationId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref('support_images/$conversationId/$fileName');
    final uploadTask = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }
}
```

---

## 3. ViewModel

### `driver_support_viewmodel.dart`

```dart
import 'package:flutter/material.dart';

class DriverSupportViewModel extends ChangeNotifier {
  final DriverSupportService _service = DriverSupportService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<String?> createConversation({
    required DriverIssueType issueType,
    required String message,
    String? imageUrl,
    String? relatedMerchantId,
    String? relatedMerchantName,
    String? relatedCustomerId,
    String? relatedCustomerName,
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
        relatedCustomerId: relatedCustomerId,
        relatedCustomerName: relatedCustomerName,
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

**سجّل في `main.dart` الخاص بتطبيق المناديب:**

```dart
ChangeNotifierProvider(create: (_) => DriverSupportViewModel()),
```

---

## 4. الشاشات

### `driver_support_center_page.dart` — الشاشة الرئيسية

**نفس تصميم التطبيق الرئيسي:**
- `AppBar`: "مركز المساعدة"
- `StreamBuilder` → قائمة المحادثات
- كل محادثة: `ConversationCard`
- حالة فارغة إذا لا توجد محادثات
- زر "إنشاء طلب دعم جديد"

**ألوان وتصميم:**
- استخدم نفس Design System الخاص بتطبيق المناديب
- RTL مع `Directionality`
- خلفية فاتحة، كروت بيضاء، ظل خفيف

---

### `driver_create_support_page.dart` — إنشاء طلب دعم

**المرحلة 1: اختيار نوع المشكلة**

```
مشكلة خاصة بعميل      → Icons.person_outlined
مشكلة خاصة بمتجر      → Icons.store_outlined
مشكلة بالتطبيق        → Icons.phone_android_outlined
استفسار عام            → Icons.help_outline
```

**المرحلة 2: حسب النوع**

**مشكلة خاصة بعميل:**
1. جلب `getRecentCustomers()` → عرض قائمة العملاء
   - أيقونة + اسم العميل
   - عند الاختيار: تحديد بحدود ملونة
2. وصف المشكلة (required)
3. صورة اختيارية
4. إرسال → يحفظ `relatedCustomerId` + `relatedCustomerName`

**مشكلة خاصة بمتجر:**
1. جلب `getRecentMerchants()` → عرض المتاجر
   - صورة المتجر + اسم المتجر
2. وصف المشكلة
3. صورة اختيارية
4. إرسال → يحفظ `relatedMerchantId` + `relatedMerchantName`

**مشكلة بالتطبيق:**
- وصف المشكلة
- صورة اختيارية
- إرسال

**استفسار عام:**
- نص الرسالة فقط
- إرسال

---

### `driver_support_chat_page.dart` — شاشة المحادثة

**نفس تصميم التطبيق الرئيسي بالضبط:**
- فقاعات الرسائل (يمين للمندوب / يسار للإدارة / وسط للنظام)
- شريط الإدخال (نص + صورة + إرسال)
- `markAsRead` عند فتح الشاشة
- عرض حالة المحادثة في AppBar
- إذا المحادثة مغلقة: رسالة "تم إغلاق هذه المحادثة"

---

## 5. Widgets

### نفس widgets التطبيق الرئيسي مع تعديلات طفيفة:

- `conversation_card.dart` — نفس التصميم
- `conversation_status_badge.dart` — نفس الألوان
- `chat_bubble.dart` — نفس التصميم (استخدم ألوان تطبيق المناديب)
- `chat_input_bar.dart` — نفس التصميم
- `system_message_widget.dart` — نفس التصميم
- `issue_type_selector.dart` — الأنواع الخاصة بالمندوب
- `customer_picker.dart` — قائمة العملاء
- `merchant_picker.dart` — قائمة المتاجر

### `customer_picker.dart` (جديد)

```
┌─────────────────────────────────┐
│ 👤 أحمد محمد                    │
├─────────────────────────────────┤
│ 👤 خالد سعيد                    │
├─────────────────────────────────┤
│ 👤 محمود أحمد                   │
└─────────────────────────────────┘
```

- قائمة vertical
- كل عنصر: أيقونة `person` + اسم العميل
- حدود ملونة عند الاختيار

---

## 6. التوجيه (Routes)

أضف في نظام الـ routing الخاص بتطبيق المناديب:

```dart
GoRoute(
  path: '/support',
  builder: (_, __) => const DriverSupportCenterPage(),
),
GoRoute(
  path: '/support/create',
  builder: (_, __) => const DriverCreateSupportPage(),
),
GoRoute(
  path: '/support/chat/:conversationId',
  builder: (context, state) {
    return DriverSupportChatPage(
      conversationId: state.pathParameters['conversationId']!,
    );
  },
),
```

### الوصول

أضف في الـ drawer أو صفحة الحساب الخاصة بالمندوب:

```dart
ListTile(
  leading: Icon(Icons.support_agent, color: AppColors.mainColor),
  title: const Text('مركز المساعدة'),
  onTap: () => context.push('/support'),
),
```

---

## 7. الإشعارات

### استقبال إشعارات رد الإدارة

Cloud Function الخاصة بالإشعارات (موجودة في التطبيق الرئيسي) ترسل إشعار لأي مستخدم عند رد الإدارة — بما فيهم المناديب.

**تأكد أن تطبيق المناديب:**
1. يحفظ FCM token في `users/{uid}/fcmToken` أو `courier_requests/{uid}/fcmToken`
2. يتعامل مع data payload من الإشعار:

```dart
// في FCM service الخاص بتطبيق المناديب
void _handleSupportNotification(Map<String, dynamic> data) {
  if (data['type'] == 'support_reply') {
    final conversationId = data['conversationId'];
    // الانتقال لشاشة المحادثة
    if (conversationId != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => DriverSupportChatPage(conversationId: conversationId),
        ),
      );
    }
  }
}
```

---

## 8. قواعد Firestore

**نفس قواعد التطبيق الرئيسي — لا حاجة لتعديلات إضافية.**

القواعد تتحقق من `resource.data.userId == request.auth.uid` وهذا يشمل المناديب تلقائياً.

**لكن تأكد أن المندوب لديه custom claim `role: 'driver'` أو أن القواعد لا تمنعه من الكتابة.**

إذا لزم الأمر، أضف:

```javascript
// في support_conversations rules
allow create: if isAuthenticated() && 
  request.resource.data.userId == request.auth.uid;
  // لا يتحقق من نوع المستخدم — مسموح لأي مستخدم مسجل
```

---

## 9. Firestore Indexes

**نفس التطبيق الرئيسي. إذا كان تطبيق المناديب يستخدم query مختلف، أضف:**

```json
{
  "collectionGroup": "support_conversations",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "userId", "order": "ASCENDING" },
    { "fieldPath": "userType", "order": "ASCENDING" },
    { "fieldPath": "updatedAt", "order": "DESCENDING" }
  ]
}
```

---

## 10. خارطة التنفيذ

### المرحلة 1: Models + Services
1. ✅ إنشاء `models/support_conversation.dart`
2. ✅ إنشاء `models/support_message.dart`
3. ✅ إنشاء `services/driver_support_service.dart`
4. ✅ إنشاء `services/support_image_service.dart`

### المرحلة 2: ViewModel
5. ✅ إنشاء `viewmodels/driver_support_viewmodel.dart`
6. ✅ تسجيل في `main.dart`

### المرحلة 3: الشاشات
7. ✅ إنشاء `driver_support_center_page.dart`
8. ✅ إنشاء `driver_create_support_page.dart`
9. ✅ إنشاء `driver_support_chat_page.dart`

### المرحلة 4: Widgets
10. ✅ إنشاء `conversation_card.dart`
11. ✅ إنشاء `chat_bubble.dart` + `chat_input_bar.dart`
12. ✅ إنشاء `issue_type_selector.dart`
13. ✅ إنشاء `customer_picker.dart` + `merchant_picker.dart`

### المرحلة 5: الربط
14. ✅ إضافة Routes
15. ✅ إضافة رابط في drawer/حساب المندوب
16. ✅ ربط إشعارات FCM

---

## ملاحظات تصميمية

1. **RTL**: كل الشاشات بالعربية و RTL
2. **التصميم**: استخدم نفس Design System لتطبيق المناديب (ألوان + خطوط)
3. **التوافق**: Firestore structure مطابق 100% للتطبيق الرئيسي
4. **الأمان**: المندوب لا يستطيع قراءة محادثات غيره
5. **Empty States**: أيقونة + نص "لا توجد محادثات بعد"
6. **Error Handling**: رسائل عربية واضحة
7. **Loading**: `CircularProgressIndicator` مع لون التطبيق
