# برومبت تنفيذ لوحة إدارة الدعم — بازار السويس (bazar_admin)

> **هذا البرومبت موجه لـ Cursor AI لتنفيذ لوحة إدارة الدعم الكاملة داخل مشروع `bazaar_admin`.**
> لوحة الإدارة تدير جميع محادثات الدعم الواردة من: العملاء — التجار — الصنايعية — المناديب.

---

## السياق التقني للمشروع

### مشروع الإدارة: `bazaar_admin`

```
d:\project\bazaar_admin\bazaar_admin\
```

### التقنيات المستخدمة

| العنصر | التقنية |
|--------|---------|
| Framework | Flutter (Dart) |
| State Management | `Provider` + `ChangeNotifier` |
| Routing | `GoRouter` |
| Auth | Firebase Auth + Custom Claims (`role: admin`) |
| Firebase | `cloud_firestore`, `firebase_auth`, `firebase_storage`, `firebase_messaging` |
| Design | `AppColors.mainColor = Color(0xFF4E99B4)` — نفس التطبيق الرئيسي |
| Admin Check | `isAdmin()` عبر custom claim أو `admin_roles` collection |
| Locale | `ar` — RTL |

### هيكل مشروع الإدارة الحالي

```
lib/
├── account/
├── activity_logs/
├── ads/
├── authentication/
├── categories/
├── courier_requests/
├── craftsmen/
├── dashboard/
├── delivery_fee/
├── layouts/
├── models/
├── offices/
├── orders/
├── packages/
├── pages/
├── reports/
├── router/
├── security/
├── services/
├── stores/
├── theme/
├── upload/
├── widgets/
├── firebase_options.dart
└── main.dart
```

---

## هيكل Firestore الموحد (نفس التطبيقات الأخرى بالضبط)

```
support_conversations/{conversationId}
├── id: string
├── userId: string
├── userName: string
├── userType: string (customer | merchant | craftsman | driver)
├── issueType: string
│   ├── "store_issue"          ← من العملاء
│   ├── "craftsman_issue"      ← من العملاء
│   ├── "driver_issue"         ← من العملاء
│   ├── "app_issue"            ← من الجميع
│   ├── "general_inquiry"      ← من الجميع
│   ├── "customer_issue"       ← من المناديب
│   └── "store_issue"          ← من المناديب
├── relatedMerchantId: string?
├── relatedMerchantName: string?
├── relatedCraftsmanId: string?
├── relatedCraftsmanName: string?
├── relatedDriverId: string?
├── relatedDriverName: string?
├── relatedCustomerId: string?
├── relatedCustomerName: string?
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

---

## هيكل المجلدات المطلوب

```
lib/support/
├── models/
│   ├── support_conversation.dart
│   └── support_message.dart
├── services/
│   ├── admin_support_service.dart
│   └── support_image_service.dart
├── viewmodels/
│   └── admin_support_viewmodel.dart
├── pages/
│   ├── support_dashboard_page.dart
│   ├── support_conversations_page.dart
│   └── admin_chat_page.dart
└── widgets/
    ├── support_stats_card.dart
    ├── conversation_list_tile.dart
    ├── conversation_status_badge.dart
    ├── conversation_filters.dart
    ├── admin_chat_bubble.dart
    ├── admin_chat_input_bar.dart
    ├── linked_entity_card.dart
    └── image_viewer_dialog.dart
```

---

## 1. Models

### `support_conversation.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String userType; // customer | merchant | craftsman | driver
  final String issueType;
  final String? relatedMerchantId;
  final String? relatedMerchantName;
  final String? relatedCraftsmanId;
  final String? relatedCraftsmanName;
  final String? relatedDriverId;
  final String? relatedDriverName;
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

  /// نوع المستخدم بالعربية
  String get userTypeDisplayName {
    switch (userType) {
      case 'customer': return 'عميل';
      case 'merchant': return 'تاجر';
      case 'craftsman': return 'صنايعي';
      case 'driver': return 'مندوب';
      default: return userType;
    }
  }

  /// نوع المشكلة بالعربية
  String get issueTypeDisplayName {
    switch (issueType) {
      case 'store_issue': return 'مشكلة بمتجر';
      case 'craftsman_issue': return 'مشكلة بصنايعي';
      case 'driver_issue': return 'مشكلة بمندوب';
      case 'customer_issue': return 'مشكلة بعميل';
      case 'app_issue': return 'مشكلة بالتطبيق';
      case 'general_inquiry': return 'استفسار عام';
      default: return issueType;
    }
  }

  /// حالة المحادثة بالعربية
  String get statusDisplayName {
    switch (status) {
      case ConversationStatus.open: return 'مفتوحة';
      case ConversationStatus.inProgress: return 'جارى المتابعة';
      case ConversationStatus.resolved: return 'تم الحل';
      case ConversationStatus.closed: return 'مغلقة';
    }
  }

  /// لون حالة المحادثة
  // open → blue, inProgress → orange, resolved → green, closed → grey

  /// هل يوجد كيان مرتبط
  bool get hasRelatedEntity =>
    (relatedMerchantId != null && relatedMerchantId!.isNotEmpty) ||
    (relatedCraftsmanId != null && relatedCraftsmanId!.isNotEmpty) ||
    (relatedDriverId != null && relatedDriverId!.isNotEmpty) ||
    (relatedCustomerId != null && relatedCustomerId!.isNotEmpty);

  /// اسم الكيان المرتبط
  String get relatedEntityName {
    if (relatedMerchantName != null && relatedMerchantName!.isNotEmpty) return relatedMerchantName!;
    if (relatedCraftsmanName != null && relatedCraftsmanName!.isNotEmpty) return relatedCraftsmanName!;
    if (relatedDriverName != null && relatedDriverName!.isNotEmpty) return relatedDriverName!;
    if (relatedCustomerName != null && relatedCustomerName!.isNotEmpty) return relatedCustomerName!;
    return '';
  }
}
```

### `support_message.dart`

نفس model التطبيقات الأخرى:

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

### `admin_support_service.dart`

```dart
class AdminSupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'support_conversations';
  static const String _messagesSubcollection = 'messages';

  // ═══════════════════════════════════════════════════════════════
  // DASHBOARD STATS
  // ═══════════════════════════════════════════════════════════════

  /// إحصائيات Dashboard (Stream)
  Stream<Map<String, int>> getDashboardStats() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snap) {
      int open = 0, inProgress = 0, resolved = 0, closed = 0, unreadTotal = 0;
      
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'open';
        final unread = (data['unreadAdminCount'] ?? 0) as int;
        
        switch (status) {
          case 'open': open++; break;
          case 'in_progress': inProgress++; break;
          case 'resolved': resolved++; break;
          case 'closed': closed++; break;
        }
        unreadTotal += unread;
      }
      
      return {
        'open': open,
        'inProgress': inProgress,
        'resolved': resolved,
        'closed': closed,
        'total': snap.docs.length,
        'unreadTotal': unreadTotal,
      };
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════

  /// جلب جميع المحادثات (Stream) مع فلاتر
  Stream<List<SupportConversation>> getAllConversations({
    String? statusFilter,       // open, in_progress, resolved, closed
    String? userTypeFilter,     // customer, merchant, craftsman, driver
    String? issueTypeFilter,    // store_issue, craftsman_issue, etc.
  }) {
    Query query = _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true);

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    if (userTypeFilter != null && userTypeFilter.isNotEmpty) {
      query = query.where('userType', isEqualTo: userTypeFilter);
    }

    return query.snapshots().map((snap) {
      var conversations = snap.docs
          .map((doc) => SupportConversation.fromFirestore(doc))
          .toList();

      // فلتر issueType محلياً (Firestore لا يدعم أكثر من equality filter)
      if (issueTypeFilter != null && issueTypeFilter.isNotEmpty) {
        conversations = conversations
            .where((c) => c.issueType == issueTypeFilter)
            .toList();
      }

      return conversations;
    });
  }

  /// بحث في المحادثات بالاسم
  Future<List<SupportConversation>> searchConversations(String query) async {
    if (query.trim().isEmpty) return [];

    // بحث محلي — جلب كل المحادثات ثم فلتر
    final snap = await _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .limit(100)
        .get();

    final q = query.toLowerCase();
    return snap.docs
        .map((doc) => SupportConversation.fromFirestore(doc))
        .where((c) =>
            c.userName.toLowerCase().contains(q) ||
            c.relatedEntityName.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════

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

  /// إرسال رد من الإدارة
  Future<void> sendAdminReply({
    required String conversationId,
    String? text,
    String? imageUrl,
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw Exception('يجب تسجيل الدخول كمسؤول');

    final messageRef = _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': admin.uid,
      'senderType': 'admin',
      'text': text ?? '',
      'imageUrl': imageUrl ?? '',
      'isSystem': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // تحديث المحادثة
    await _firestore.collection(_collection).doc(conversationId).update({
      'lastMessage': text ?? '📷 صورة',
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadUserCount': FieldValue.increment(1),
      'unreadAdminCount': 0, // تصفير — الإدارة قرأت وردت
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS MANAGEMENT
  // ═══════════════════════════════════════════════════════════════

  /// تغيير حالة المحادثة
  Future<void> updateStatus(String conversationId, ConversationStatus newStatus) async {
    String statusStr;
    switch (newStatus) {
      case ConversationStatus.open: statusStr = 'open'; break;
      case ConversationStatus.inProgress: statusStr = 'in_progress'; break;
      case ConversationStatus.resolved: statusStr = 'resolved'; break;
      case ConversationStatus.closed: statusStr = 'closed'; break;
    }

    await _firestore.collection(_collection).doc(conversationId).update({
      'status': statusStr,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // إرسال رسالة نظام عند تغيير الحالة
    String statusMessage;
    switch (newStatus) {
      case ConversationStatus.inProgress:
        statusMessage = 'تم تحويل حالة المحادثة إلى: جارى المتابعة';
        break;
      case ConversationStatus.resolved:
        statusMessage = 'تم حل المشكلة. إذا كنت تحتاج مساعدة أخرى، يرجى فتح محادثة جديدة.';
        break;
      case ConversationStatus.closed:
        statusMessage = 'تم إغلاق المحادثة.';
        break;
      default:
        statusMessage = 'تم تحديث حالة المحادثة.';
    }

    final messageRef = _firestore
        .collection(_collection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': 'system',
      'senderType': 'system',
      'text': statusMessage,
      'imageUrl': '',
      'isSystem': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// تصفير عداد غير المقروءة للإدارة
  Future<void> markAsReadByAdmin(String conversationId) async {
    await _firestore.collection(_collection).doc(conversationId).update({
      'unreadAdminCount': 0,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // LINKED ENTITIES
  // ═══════════════════════════════════════════════════════════════

  /// جلب بيانات المتجر المرتبط
  Future<Map<String, dynamic>?> getMerchantDetails(String merchantId) async {
    if (merchantId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('markets').doc(merchantId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  /// جلب بيانات الصنايعي المرتبط
  Future<Map<String, dynamic>?> getCraftsmanDetails(String craftsmanId) async {
    if (craftsmanId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('craftsmen').doc(craftsmanId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  /// جلب بيانات المندوب المرتبط
  Future<Map<String, dynamic>?> getDriverDetails(String driverId) async {
    if (driverId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('courier_requests').doc(driverId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  /// جلب بيانات الطلب المرتبط
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    if (orderId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  /// جلب بيانات المستخدم
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════

  /// آخر المحادثات المحدثة (للـ Dashboard)
  Stream<List<SupportConversation>> getRecentActivity({int limit = 5}) {
    return _firestore
        .collection(_collection)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SupportConversation.fromFirestore(doc))
            .toList());
  }
}
```

### `support_image_service.dart`

```dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<String> uploadImage(File file, String conversationId) async {
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref('support_images/$conversationId/$fileName');
    final uploadTask = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }
}
```

---

## 3. ViewModel

### `admin_support_viewmodel.dart`

```dart
import 'package:flutter/material.dart';

class AdminSupportViewModel extends ChangeNotifier {
  final AdminSupportService _service = AdminSupportService();

  // فلاتر
  String? _statusFilter;
  String? _userTypeFilter;
  String? _issueTypeFilter;
  String? _searchQuery;

  String? get statusFilter => _statusFilter;
  String? get userTypeFilter => _userTypeFilter;
  String? get issueTypeFilter => _issueTypeFilter;
  String? get searchQuery => _searchQuery;

  void setStatusFilter(String? value) {
    _statusFilter = value;
    notifyListeners();
  }

  void setUserTypeFilter(String? value) {
    _userTypeFilter = value;
    notifyListeners();
  }

  void setIssueTypeFilter(String? value) {
    _issueTypeFilter = value;
    notifyListeners();
  }

  void setSearchQuery(String? value) {
    _searchQuery = value;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _userTypeFilter = null;
    _issueTypeFilter = null;
    _searchQuery = null;
    notifyListeners();
  }

  /// Stream المحادثات مع الفلاتر
  Stream<List<SupportConversation>> get filteredConversations {
    return _service.getAllConversations(
      statusFilter: _statusFilter,
      userTypeFilter: _userTypeFilter,
      issueTypeFilter: _issueTypeFilter,
    );
  }

  /// تغيير الحالة
  Future<void> updateStatus(String conversationId, ConversationStatus newStatus) async {
    await _service.updateStatus(conversationId, newStatus);
  }

  /// إرسال رد
  Future<void> sendReply({
    required String conversationId,
    String? text,
    String? imageUrl,
  }) async {
    await _service.sendAdminReply(
      conversationId: conversationId,
      text: text,
      imageUrl: imageUrl,
    );
  }
}
```

**سجّل في `main.dart` الخاص بـ `bazaar_admin`:**

```dart
ChangeNotifierProvider(create: (_) => AdminSupportViewModel()),
```

---

## 4. الشاشات

### `support_dashboard_page.dart` — لوحة التحكم

**التصميم:**

```
┌──────────────────────────────────────────────┐
│                 مركز الدعم                    │
├──────────────────────────────────────────────┤
│                                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐     │
│  │   12    │  │    5    │  │    8    │     │
│  │ مفتوحة  │  │ جارية   │  │ تم الحل │     │
│  └─────────┘  └─────────┘  └─────────┘     │
│                                              │
│  ┌─────────┐  ┌──────────────────────┐      │
│  │   25    │  │     3 رسائل         │      │
│  │  الكل   │  │    غير مقروءة       │      │
│  └─────────┘  └──────────────────────┘      │
│                                              │
│  ─── آخر النشاطات ──────────────────────     │
│                                              │
│  ┌────────────────────────────────────┐      │
│  │ 👤 أحمد محمد — عميل              │      │
│  │ مشكلة بمتجر • متجر أبو على       │      │
│  │ "المنتج وصل تالف..."     منذ 5 د │      │
│  └────────────────────────────────────┘      │
│  ┌────────────────────────────────────┐      │
│  │ 🚗 خالد سعيد — مندوب             │      │
│  │ مشكلة بعميل                       │      │
│  │ "العميل رفض يستلم..."   منذ ساعة │      │
│  └────────────────────────────────────┘      │
│                                              │
│  ── [عرض جميع المحادثات] ──                  │
└──────────────────────────────────────────────┘
```

**المكونات:**

1. **إحصائيات** — `StreamBuilder` → `getDashboardStats()`
   - 4 كروت صغيرة (open, inProgress, resolved, total)
   - كل كارت قابل للضغط → ينتقل لقائمة المحادثات مع الفلتر المناسب
   - كارت عدد الرسائل غير المقروءة (لون أحمر إذا > 0)

2. **آخر النشاطات** — `StreamBuilder` → `getRecentActivity(limit: 5)`
   - قائمة مختصرة لآخر 5 محادثات
   - كل عنصر يعرض: نوع المستخدم + اسمه + نوع المشكلة + آخر رسالة + الوقت

3. **زر "عرض جميع المحادثات"** → ينتقل لـ `SupportConversationsPage`

**تصميم الكروت:**
- خلفية بيضاء، ظل خفيف، زوايا مستديرة 16
- رقم كبير (fontSize: 28, bold)
- label تحته (fontSize: 12, grey)
- لون الرقم حسب الحالة:
  - مفتوحة: أزرق `Color(0xFF3B82F6)`
  - جارية: برتقالي `Color(0xFFF59E0B)`
  - تم الحل: أخضر `Color(0xFF10B981)`
  - مغلقة: رمادي `Color(0xFF6B7280)`

---

### `support_conversations_page.dart` — قائمة المحادثات

**التصميم:**

```
┌──────────────────────────────────────────────┐
│  ←  إدارة المحادثات                          │
├──────────────────────────────────────────────┤
│  🔍 [بحث باسم المستخدم أو المشكلة...]       │
│                                              │
│  [الكل] [مفتوحة] [جارية] [تم الحل] [مغلقة]  │  ← TabBar/Chips
│                                              │
│  فلتر حسب المستخدم: [الكل ▼]                │  ← Dropdown
│  فلتر حسب النوع:    [الكل ▼]                │  ← Dropdown
│                                              │
│  ┌────────────────────────────────────┐      │
│  │ 👤 أحمد محمد — عميل    ● مفتوحة  │      │
│  │ مشكلة بمتجر • متجر أبو على       │      │
│  │ "المنتج وصل تالف وأنا عايز..."   │      │
│  │                     منذ 5 دقائق ●3│      │
│  └────────────────────────────────────┘      │
│  ┌────────────────────────────────────┐      │
│  │ 🏪 سوبر ماركت — تاجر   ● جارية   │      │
│  │ مشكلة بالتطبيق                     │      │
│  │ "مش قادر أضيف منتجات جديدة..."    │      │
│  │                       منذ ساعة    │      │
│  └────────────────────────────────────┘      │
└──────────────────────────────────────────────┘
```

**المكونات:**

1. **شريط البحث** — `TextField` مع debounce 500ms
   - يبحث في `userName`, `relatedEntityName`, `lastMessage`

2. **فلتر الحالة** — `TabBar` أو `FilterChip` أفقي:
   ```
   الكل | مفتوحة | جارى المتابعة | تم الحل | مغلقة
   ```

3. **فلاتر إضافية** — `DropdownButton`:
   - نوع المستخدم: `الكل | عميل | تاجر | صنايعي | مندوب`
   - نوع المشكلة: `الكل | مشكلة بمتجر | مشكلة بصنايعي | ...`

4. **قائمة المحادثات** — `StreamBuilder` → `filteredConversations`

**كل محادثة (`ConversationListTile`) تعرض:**
- أيقونة نوع المستخدم (👤 عميل, 🏪 تاجر, 🔧 صنايعي, 🚗 مندوب)
- اسم المستخدم + نوعه
- `ConversationStatusBadge` (حالة ملونة)
- نوع المشكلة + اسم الكيان المرتبط (إن وجد)
- آخر رسالة (سطر واحد, overflow ellipsis)
- الوقت النسبي
- عدد الرسائل غير المقروءة (badge أحمر)

**عند الضغط على محادثة:** ينتقل لـ `AdminChatPage`

---

### `admin_chat_page.dart` — شاشة رد الإدارة

**التصميم:**

```
┌──────────────────────────────────────────────┐
│  ←  أحمد محمد — عميل                         │
│     مشكلة بمتجر • مفتوحة                     │
├──────────────────────────────────────────────┤
│                                              │
│  ┌ بيانات مرتبطة ──────────────────────┐    │
│  │ 🏪 متجر أبو على         [فتح ↗]    │    │
│  │ 📦 طلب #12345            [فتح ↗]    │    │
│  └──────────────────────────────────────┘    │
│                                              │
│  ──── تاريخ اليوم ─────                      │
│                                              │
│         ┌────────────────────────┐           │
│         │ المنتج وصل تالف       │ ← المستخدم│
│         │ وعايز أرجعه            │           │
│         │               2:30 م  │           │
│         └────────────────────────┘           │
│                                              │
│  ┌────────────────────────────────────┐      │
│  │ 📷 [صورة المنتج]                   │      │
│  │               2:31 م              │      │
│  └────────────────────────────────────┘      │
│                                              │
│     ┌─── رسالة النظام ───┐                   │
│     │ شكراً لتواصلك...    │                   │
│     └────────────────────┘                   │
│                                              │
│  ┌────────────────────────────────┐          │
│  │ سيتم التواصل مع المتجر      │ ← الإدارة │
│  │ لحل المشكلة                   │          │
│  │               3:15 م          │          │
│  └────────────────────────────────┘          │
│                                              │
├──────────────────────────────────────────────┤
│  [📎] [اكتب ردك هنا...               ] [▶️] │
├──────────────────────────────────────────────┤
│  تغيير الحالة: [مفتوحة ▼]                    │
└──────────────────────────────────────────────┘
```

**المكونات:**

1. **AppBar:**
   - اسم المستخدم + نوعه
   - نوع المشكلة + حالة المحادثة

2. **بيانات مرتبطة** (أعلى الرسائل — `LinkedEntityCard`):
   - إذا `relatedMerchantId` ≠ فارغ: عرض اسم المتجر + زر "فتح" → يفتح صفحة المتجر في admin
   - إذا `relatedCraftsmanId` ≠ فارغ: عرض اسم الصنايعي + زر "فتح"
   - إذا `relatedDriverId` ≠ فارغ: عرض اسم المندوب + زر "فتح"
   - إذا `relatedOrderId` ≠ فارغ: عرض رقم الطلب + زر "فتح"
   - زر "فتح" ينتقل للصفحة المناسبة في لوحة الإدارة

3. **قائمة الرسائل** — `StreamBuilder` → `getMessages(conversationId)`
   - فقاعات مختلفة:
     - **رسالة المستخدم** (يمين): خلفية فاتحة، label "المستخدم"
     - **رسالة الإدارة** (يسار): خلفية `AppColors.mainColor` مع نص أبيض
     - **رسالة النظام** (وسط): خلفية شفافة، نص صغير
   - الصور: عرض مصغر + عند الضغط: `ImageViewerDialog` بحجم كامل

4. **شريط الإدخال** (Bottom):
   - `TextField` + زر صورة + زر إرسال
   - يرسل رسالة بـ `senderType: 'admin'`

5. **تغيير الحالة** (أسفل شريط الإدخال):
   - `DropdownButton` لتغيير حالة المحادثة
   - الخيارات: مفتوحة | جارى المتابعة | تم الحل | مغلقة
   - عند التغيير: استدعاء `updateStatus()` → يرسل رسالة نظام تلقائياً

**عند فتح الشاشة:**
- `markAsReadByAdmin(conversationId)` لتصفير العداد

---

## 5. Widgets

### `support_stats_card.dart`

كارت إحصائية واحدة:
- رقم كبير + label
- لون حسب النوع
- أيقونة
- `onTap` → ينتقل للمحادثات مع فلتر

### `conversation_list_tile.dart`

```dart
// عنصر واحد في قائمة المحادثات
// يعرض: أيقونة المستخدم + اسمه + نوعه + نوع المشكلة + آخر رسالة + الوقت + badge
```

### `conversation_status_badge.dart`

```dart
// Chip ملون حسب حالة المحادثة
// نفس التصميم من التطبيقات الأخرى
```

### `conversation_filters.dart`

```dart
// Row من FilterChips أو TabBar للحالات
// + DropdownButtons لفلاتر إضافية
```

### `admin_chat_bubble.dart`

فقاعة رسالة مع:
- تمييز واضح بين رسالة المستخدم والإدارة والنظام
- عرض الصور
- الوقت

### `admin_chat_input_bar.dart`

شريط الإدخال + تغيير الحالة.

### `linked_entity_card.dart`

```dart
// كارت صغير يعرض الكيان المرتبط
// مع زر "فتح" للانتقال لصفحته في الإدارة
```

### `image_viewer_dialog.dart`

```dart
// Dialog بحجم الشاشة لعرض صورة مكبرة
// مع زر إغلاق وإمكانية zoom
```

---

## 6. التوجيه (Routes)

أضف في نظام routing الخاص بـ `bazaar_admin`:

```dart
GoRoute(
  path: '/support',
  builder: (_, __) => const SupportDashboardPage(),
),
GoRoute(
  path: '/support/conversations',
  builder: (context, state) {
    final statusFilter = state.uri.queryParameters['status'];
    return SupportConversationsPage(initialStatusFilter: statusFilter);
  },
),
GoRoute(
  path: '/support/chat/:conversationId',
  builder: (context, state) {
    return AdminChatPage(
      conversationId: state.pathParameters['conversationId']!,
    );
  },
),
```

### الوصول

أضف في sidebar/drawer الخاص بلوحة الإدارة:

```dart
ListTile(
  leading: Icon(Icons.support_agent, color: AppColors.mainColor),
  title: const Text('مركز الدعم'),
  // أضف badge لعدد الرسائل غير المقروءة
  trailing: StreamBuilder<Map<String, int>>(
    stream: AdminSupportService().getDashboardStats(),
    builder: (_, snap) {
      final unread = snap.data?['unreadTotal'] ?? 0;
      if (unread == 0) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 12)),
      );
    },
  ),
  onTap: () => context.push('/support'),
),
```

---

## 7. الربط مع صفحات الإدارة الموجودة

### فتح صفحة المتجر من المحادثة:

```dart
// في LinkedEntityCard عند الضغط على "فتح المتجر"
context.push('/stores/$merchantId'); // أو المسار المناسب في admin
```

### فتح صفحة الصنايعي:

```dart
context.push('/craftsmen/$craftsmanId');
```

### فتح صفحة المندوب:

```dart
context.push('/courier-requests/$driverId');
```

### فتح صفحة الطلب:

```dart
context.push('/orders/$orderId');
```

> **ملاحظة:** تأكد من المسارات الفعلية في router الخاص بـ bazaar_admin واستخدمها.

---

## 8. قواعد Firestore

**نفس القواعد المذكورة في CUSTOMER_SUPPORT_CURSOR_PROMPT.md.**

الإدارة تستخدم `isAdmin()` function الموجودة في `firestore.rules` والتي تتحقق من custom claims.

**القواعد تسمح للإدارة بـ:**
- ✅ قراءة جميع المحادثات
- ✅ تحديث أي محادثة (حالة + عدادات)
- ✅ إنشاء رسائل في أي محادثة
- ❌ حذف المحادثات (super admin فقط)

---

## 9. الإشعارات

### استقبال الإشعارات في لوحة الإدارة

لوحة الإدارة لا تحتاج push notifications (عادة تكون web app أو تطبيق يعمل بشكل دائم).

**بدلاً من ذلك:**
- عداد الرسائل غير المقروءة في sidebar (real-time عبر Stream)
- صوت تنبيه عند وصول محادثة جديدة (اختياري)

### إرسال الإشعارات

عند رد الإدارة على محادثة → Cloud Function تتكفل بإرسال FCM للمستخدم تلقائياً.

---

## 10. خارطة التنفيذ

### المرحلة 1: Models + Services
1. ✅ إنشاء `models/support_conversation.dart`
2. ✅ إنشاء `models/support_message.dart`
3. ✅ إنشاء `services/admin_support_service.dart`
4. ✅ إنشاء `services/support_image_service.dart`

### المرحلة 2: ViewModel
5. ✅ إنشاء `viewmodels/admin_support_viewmodel.dart`
6. ✅ تسجيل في `main.dart`

### المرحلة 3: Dashboard
7. ✅ إنشاء `support_dashboard_page.dart`
8. ✅ إنشاء `support_stats_card.dart`

### المرحلة 4: المحادثات
9. ✅ إنشاء `support_conversations_page.dart`
10. ✅ إنشاء `conversation_list_tile.dart`
11. ✅ إنشاء `conversation_filters.dart`

### المرحلة 5: شاشة الرد
12. ✅ إنشاء `admin_chat_page.dart`
13. ✅ إنشاء `admin_chat_bubble.dart` + `admin_chat_input_bar.dart`
14. ✅ إنشاء `linked_entity_card.dart`
15. ✅ إنشاء `image_viewer_dialog.dart`

### المرحلة 6: الربط
16. ✅ إضافة Routes
17. ✅ إضافة في sidebar مع badge
18. ✅ ربط مع صفحات الكيانات الموجودة

---

## ملاحظات تصميمية

1. **RTL**: كل الشاشات عربية و RTL
2. **الألوان**: نفس `AppColors.mainColor` — تصميم متناسق مع بقية الإدارة
3. **Real-time**: استخدم `StreamBuilder` لكل البيانات الحية
4. **الأداء**: استخدم `limit` في الاستعلامات — لا تجلب كل المحادثات دفعة واحدة
5. **Filters**: الفلاتر تعمل server-side قدر الإمكان
6. **الأمان**: كل العمليات محمية بـ `isAdmin()` في Firestore rules
7. **Empty States**: رسائل واضحة عند عدم وجود بيانات
8. **Error Handling**: `try/catch` مع رسائل عربية
9. **Loading**: مؤشرات تحميل مناسبة
10. **تغيير الحالة**: يرسل رسالة نظام تلقائياً للمستخدم
