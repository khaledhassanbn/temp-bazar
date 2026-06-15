# 📋 الخطوات المتبقية لنظام إدارة الأدمن

## ⚠️ خطوة إلزامية واحدة فقط: تعديل التوجيه (Routing)

### المشكلة الحالية
الملف `lib/router/routes_config/admin_routes.dart` يحتوي على روابط تشير إلى صفحات قديمة في:
```
lib/admin/reports/pages/reports_pages.dart
```

بينما الصفحات الجديدة موجودة في:
```
lib/admin/pages/
```

---

## 🔧 الحل: تعديل ملف `admin_routes.dart`

### الخطوة 1: تعديل الـ imports
افتح الملف: `lib/router/routes_config/admin_routes.dart`

**احذف/علّق السطر:**
```dart
import 'package:bazar_suez/admin/reports/pages/reports_pages.dart';
```

**أضف السطر الجديد:**
```dart
import 'package:bazar_suez/admin/pages/pages.dart';
import 'package:bazar_suez/admin/models/models.dart'; // لاستخدام UserReport
```

---

### الخطوة 2: تعديل/إضافة Routes

**أضف/عدّل الروابط التالية في قائمة `adminRoutes`:**

```dart
final adminRoutes = [
  // ... الروابط الموجودة ...
  
  // لوحة التحكم الجديدة لنظام الإدارة
  GoRoute(
    path: '/admin/management',
    builder: (context, state) => const AdminDashboardPage(),
  ),
  
  // قائمة البلاغات (عدّل الموجود أو أضف جديد)
  GoRoute(
    path: '/admin/reports-new', // أو استخدم /admin/reports إذا أردت استبدال القديم
    builder: (context, state) => const ReportsListPage(),
  ),
  
  // تفاصيل البلاغ (عدّل الموجود)
  GoRoute(
    path: '/admin/reports-new/:reportId', // أو /admin/reports/:reportId
    builder: (context, state) {
      final report = state.extra as UserReport;
      return ReportDetailPage(report: report);
    },
  ),
  
  // قائمة المستخدمين مع التبويبات
  GoRoute(
    path: '/admin/users-management',
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>?;
      final initialTab = args?['tab'] ?? 0;
      return UsersListPage(initialTab: initialTab);
    },
  ),
  
  // تفاصيل المستخدم
  GoRoute(
    path: '/admin/user-management-detail',
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return UserDetailPage(
        userId: args['userId'],
        userType: args['userType'],
      );
    },
  ),
];
```

---

### الخطوة 3: تحديث القائمة الجانبية (اختياري)

إذا أردت إضافة روابط للصفحات الجديدة في القائمة الجانبية `AdminDrawer`، عدّل الملف:
```
lib/admin/widgets/admin_drawer.dart
```

**أضف عناصر قائمة جديدة:**
```dart
ListTile(
  leading: Icon(Icons.dashboard),
  title: Text('لوحة التحكم الإدارية'),
  selected: currentRoute == '/admin/management',
  onTap: () {
    Navigator.pushNamed(context, '/admin/management');
  },
),
ListTile(
  leading: Icon(Icons.report),
  title: Text('البلاغات الجديدة'),
  selected: currentRoute == '/admin/reports-new',
  onTap: () {
    Navigator.pushNamed(context, '/admin/reports-new');
  },
),
ListTile(
  leading: Icon(Icons.people),
  title: Text('إدارة المستخدمين'),
  selected: currentRoute == '/admin/users-management',
  onTap: () {
    Navigator.pushNamed(context, '/admin/users-management');
  },
),
```

---

## 🧪 الاختبار

بعد إجراء التعديلات، اختبر التالي:

### 1. التنقل الأساسي
```dart
// من أي صفحة أدمن
Navigator.pushNamed(context, '/admin/management');
```

### 2. التنقل مع معاملات
```dart
// فتح تبويب المتاجر
Navigator.pushNamed(
  context, 
  '/admin/users-management',
  arguments: {'tab': 1},
);

// فتح تفاصيل صنايعي
Navigator.pushNamed(
  context,
  '/admin/user-management-detail',
  arguments: {
    'userId': 'craftsman123',
    'userType': 'craftsman',
  },
);

// فتح تفاصيل بلاغ
Navigator.pushNamed(
  context,
  '/admin/reports-new/report123',
  arguments: userReportObject,
);
```

---

## 📦 خطوات اختيارية (غير إلزامية)

### 1. قواعد الأمان (Firestore Security Rules)
إذا أردت حماية البيانات، أنشئ ملف `firestore.rules` في جذر المشروع:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // قاعدة عامة: منع الوصول افتراضياً
    match /{document=**} {
      allow read, write: if false;
    }
    
    // user_reports: الكل يقدر يقرأ ويكتب بلاغاته، الأدمن يقدر يشوف كل شي
    match /user_reports/{reportId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null && 
        (resource.data.reporterId == request.auth.uid || isAdmin());
      allow update, delete: if isAdmin();
    }
    
    // craftsmen: الكل يقدر يقرأ، الصنايعي يعدل بياناته، الأدمن يعدل كل شي
    match /craftsmen/{craftsmanId} {
      allow read: if true; // عام
      allow create, update: if request.auth != null && 
        (request.auth.uid == craftsmanId || isAdmin());
      allow delete: if false; // ما ننصح بالحذف
    }
    
    // markets: نفس النمط
    match /markets/{marketId} {
      allow read: if true;
      allow create, update: if request.auth != null && 
        (request.auth.uid == marketId || isAdmin());
      allow delete: if false;
    }
    
    // courier_requests
    match /courier_requests/{courierId} {
      allow read: if true;
      allow create, update: if request.auth != null && 
        (request.auth.uid == courierId || isAdmin());
      allow delete: if false;
    }
    
    // دالة مساعدة: التحقق من أن المستخدم أدمن
    function isAdmin() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

---

### 2. الفهارس المركبة (Composite Indexes)
أنشئ ملف `firestore.indexes.json` في جذر المشروع:

```json
{
  "indexes": [
    {
      "collectionGroup": "user_reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "targetId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "user_reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "craftsmen",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "adminStatus", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "markets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "adminStatus", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "courier_requests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "adminStatus", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**نشر الفهارس:**
```bash
firebase deploy --only firestore:indexes
```

---

### 3. سكريبت الهجرة (Migration Script)
إذا كان لديك بيانات موجودة بدون الحقول الجديدة، أنشئ سكريبت Node.js:

```javascript
// migration_script.js
const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

async function migrateCollection(collectionName) {
  console.log(`Migrating ${collectionName}...`);
  const snapshot = await db.collection(collectionName).get();
  
  const batch = db.batch();
  let count = 0;
  
  snapshot.docs.forEach(doc => {
    const data = doc.data();
    
    // إضافة الحقول فقط إذا لم تكن موجودة
    const updates = {};
    if (!data.adminStatus) updates.adminStatus = 'active';
    if (!data.reportCount) updates.reportCount = 0;
    if (!data.totalCalls) updates.totalCalls = 0;
    if (!data.totalWhatsApp) updates.totalWhatsApp = 0;
    if (!data.totalViews) updates.totalViews = 0;
    
    if (Object.keys(updates).length > 0) {
      batch.update(doc.ref, updates);
      count++;
    }
  });
  
  if (count > 0) {
    await batch.commit();
    console.log(`✅ Updated ${count} documents in ${collectionName}`);
  } else {
    console.log(`✅ No updates needed for ${collectionName}`);
  }
}

async function main() {
  await migrateCollection('craftsmen');
  await migrateCollection('markets');
  await migrateCollection('courier_requests');
  console.log('✅ Migration completed!');
}

main().catch(console.error);
```

**تشغيل السكريبت:**
```bash
node migration_script.js
```

---

## ✅ قائمة التحقق النهائية

- [ ] تعديل imports في `admin_routes.dart`
- [ ] إضافة/تعديل routes للصفحات الجديدة
- [ ] تحديث القائمة الجانبية (اختياري)
- [ ] اختبار التنقل بين الصفحات
- [ ] نشر قواعد الأمان (اختياري)
- [ ] نشر الفهارس المركبة (اختياري)
- [ ] تشغيل سكريبت الهجرة (اختياري)

---

## 🎉 بعد الانتهاء

نظام إدارة الأدمن سيكون جاهزاً بالكامل! يمكنك:
- إدارة البلاغات (عرض، حل، رفض، حذف)
- إدارة المستخدمين (قبول، رفض، تعليق، حظر، حذف، استعادة)
- عرض الإحصائيات والتحليلات
- إدارة معارض الأعمال للصنايعية

---

**ملاحظة**: الخطوة الإلزامية الوحيدة هي تعديل التوجيه (Routing). باقي الخطوات اختيارية وتُضاف حسب الحاجة.
