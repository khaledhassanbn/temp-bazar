# Design Document: Admin Management System (Cost-Optimized MVP)

## Overview

This design document specifies the technical architecture for the Admin Management System in Bazaar Suez, a Flutter/Firebase application. The system enables administrators to manage user reports, control accounts (craftsmen, stores, couriers), manage images, and view analytics dashboards.

**Key Principles:**
- Simple architecture: UI Pages → Services → Firestore (no Repository/ViewModel layers)
- Cost-optimized: Denormalized counters, efficient queries, minimal Cloud Functions
- Real-time updates: StreamBuilder for reactive UI
- One-week implementation timeline

## Architecture

```
┌─────────────────────────────────────────────┐
│ UI Pages (StatefulWidget + StreamBuilder)  │
├─────────────────────────────────────────────┤
│ Services Layer (Business Logic)            │
├─────────────────────────────────────────────┤
│ Firestore │ Firebase Auth │ Storage         │
├─────────────────────────────────────────────┤
│ Cloud Function: onReportCreated (1 only)   │
└─────────────────────────────────────────────┘
```

**Design Goals:**
- Minimal collections (1 new: user_reports)
- Denormalized counters (reportCount, totalCalls, totalWhatsApp, totalViews)
- FieldValue.increment to reduce read operations
- Soft delete pattern (adminStatus = 'deleted' + deletedAt + deletedBy)
- No separate analytics/stats collections

## Collections Structure

### Collection 1: user_reports (NEW)

```
user_reports/{reportId}
├── reporterId: string          // User who submitted the report
├── targetId: string            // ID of reported entity
├── targetType: string          // 'craftsman' | 'store' | 'courier'
├── reason: string              // Report reason/description
├── status: string              // 'pending' | 'resolved' | 'dismissed'
├── createdAt: timestamp        // Report submission time
├── resolvedAt: timestamp?      // Resolution time (optional)
├── resolvedBy: string?         // Admin ID who resolved (optional)
└── resolution: string?         // Resolution notes (optional)
```

**Validation Rules:**
- `reason` must be non-empty
- Duplicate prevention: Same reporterId + targetId within 24 hours
- `targetId` must exist in corresponding collection

### Collection 2: craftsmen (MODIFIED)

**New Admin Fields:**
```
+ adminStatus: string           // 'active' | 'pending' | 'suspended' | 'banned' | 'deleted'
+ reportCount: int              // Denormalized counter
+ totalCalls: int               // Denormalized call counter
+ totalWhatsApp: int            // Denormalized WhatsApp counter
+ totalViews: int               // Denormalized view counter
+ deletedAt: timestamp?         // Soft delete timestamp
+ deletedBy: string?            // Admin ID who deleted
+ lastAdminAction: map {        // Inline action log
    action: string,             // 'approved' | 'rejected' | 'suspended' | 'banned' | 'deleted' | 'restored'
    by: string,                 // adminId
    at: timestamp,
    reason: string
  }
```

### Collection 3: markets (MODIFIED)

Same new admin fields as `craftsmen`

### Collection 4: courier_requests (MODIFIED)

Same new admin fields as `craftsmen`

### Collection 5: users (MODIFIED)

**New Conversion Fields:**
```
+ previousAccountType: string?  // 'craftsman' | 'store_owner' (for restoration)
+ convertedAt: timestamp?       // Conversion timestamp
```

**Note:** No separate `report_statistics` collection - use reportCount in each document directly.

## Data Models

### Model 1: UserReport

```dart
class UserReport {
  final String id;
  final String reporterId;
  final String targetId;
  final String targetType; // 'craftsman' | 'store' | 'courier'
  final String reason;
  final String status; // 'pending' | 'resolved' | 'dismissed'
  final Timestamp createdAt;
  final Timestamp? resolvedAt;
  final String? resolvedBy;
  final String? resolution;

  UserReport({
    required this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
  });

  factory UserReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? 'craftsman',
      reason: data['reason'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      resolvedAt: data['resolvedAt'],
      resolvedBy: data['resolvedBy'],
      resolution: data['resolution'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'status': status,
      'createdAt': createdAt,
      if (resolvedAt != null) 'resolvedAt': resolvedAt,
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (resolution != null) 'resolution': resolution,
    };
  }
}
```

### Model 2: AdminAction (Inline Map)

```dart
class AdminAction {
  final String action; // 'approved' | 'rejected' | 'suspended' | 'banned' | 'deleted' | 'restored'
  final String by; // adminId
  final Timestamp at;
  final String reason;

  AdminAction({
    required this.action,
    required this.by,
    required this.at,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'by': by,
      'at': at,
      'reason': reason,
    };
  }

  factory AdminAction.fromMap(Map<String, dynamic> map) {
    return AdminAction(
      action: map['action'] ?? '',
      by: map['by'] ?? '',
      at: map['at'] ?? Timestamp.now(),
      reason: map['reason'] ?? '',
    );
  }
}
```

## Services Layer

### Service 1: ReportService

```dart
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new report with duplicate validation
  Future<String> createReport({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
  }) async {
    // 1. Check for duplicate reports (same reporterId + targetId within 24 hours)
    final existing = await _firestore
        .collection('user_reports')
        .where('reporterId', isEqualTo: reporterId)
        .where('targetId', isEqualTo: targetId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(Duration(hours: 24))
        ))
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('لقد أبلغت عن هذا المستخدم مؤخراً');
    }

    // 2. Create report
    final doc = await _firestore.collection('user_reports').add({
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// Watch pending reports in real-time
  Stream<List<UserReport>> watchPendingReports() {
    return _firestore
        .collection('user_reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserReport.fromFirestore(doc))
            .toList());
  }

  /// Get all reports for a specific target
  Future<List<UserReport>> getReportsByTarget(String targetId) async {
    final snapshot = await _firestore
        .collection('user_reports')
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => UserReport.fromFirestore(doc))
        .toList();
  }

  /// Resolve a report
  Future<void> resolveReport({
    required String reportId,
    required String adminId,
    required String resolution,
  }) async {
    await _firestore.collection('user_reports').doc(reportId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': adminId,
      'resolution': resolution,
    });
  }

  /// Dismiss a report
  Future<void> dismissReport({
    required String reportId,
    required String adminId,
    required String reason,
  }) async {
    await _firestore.collection('user_reports').doc(reportId).update({
      'status': 'dismissed',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': adminId,
      'resolution': reason,
    });
  }
}
```

### Service 2: AdminAccountService

```dart
class AdminAccountService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _collection(String type) =>
      type == 'craftsman' ? 'craftsmen' : type == 'store' ? 'markets' : 'courier_requests';

  /// Approve user account
  Future<void> approveUser({
    required String accountId,
    required String accountType,
    required String adminId,
  }) async {
    final collection = _collection(accountType);
    await _firestore.collection(collection).doc(accountId).update({
      'adminStatus': 'active',
      'lastAdminAction': {
        'action': 'approved',
        'by': adminId,
        'at': FieldValue.serverTimestamp(),
        'reason': '',
      },
    });
  }

  /// Reject user account
  Future<void> rejectUser({
    required String accountId,
    required String accountType,
    required String adminId,
    required String reason,
  }) async {
    final collection = _collection(accountType);
    await _firestore.collection(collection).doc(accountId).update({
      'adminStatus': 'rejected',
      'lastAdminAction': {
        'action': 'rejected',
        'by': adminId,
        'at': FieldValue.serverTimestamp(),
        'reason': reason,
      },
    });
  }

  /// Suspend user account
  Future<void> suspendAccount({
    required String accountId,
    required String accountType,
    required String adminId,
    required String reason,
  }) async {
    final collection = _collection(accountType);
    await _firestore.collection(collection).doc(accountId).update({
      'adminStatus': 'suspended',
      'lastAdminAction': {
        'action': 'suspended',
        'by': adminId,
        'at': FieldValue.serverTimestamp(),
        'reason': reason,
      },
    });
  }

  /// Ban user account permanently
  Future<void> banAccount({
    required String accountId,
    required String accountType,
    required String adminId,
    required String reason,
  }) async {
    final collection = _collection(accountType);
    await _firestore.collection(collection).doc(accountId).update({
      'adminStatus': 'banned',
      'lastAdminAction': {
        'action': 'banned',
        'by': adminId,
        'at': FieldValue.serverTimestamp(),
        'reason': reason,
      },
    });
  }

  /// Delete account (soft delete) and convert to regular user
  Future<void> deleteAccount({
    required String accountId,
    required String accountType,
    required String adminId,
    required String reason,
  }) async {
    final collection = _collection(accountType);
    final batch = _firestore.batch();

    // 1. Soft delete in craftsmen/markets/courier_requests
    final accountRef = _firestore.collection(collection).doc(accountId);
    batch.update(accountRef, {
      'adminStatus': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': adminId,
      'lastAdminAction': {
        'action': 'deleted',
        'by': adminId,
        'at': FieldValue.serverTimestamp(),
        'reason': reason,
      },
    });

    // 2. Convert role in users collection
    final userRef = _firestore.collection('users').doc(accountId);
    batch.update(userRef, {
      'role': 'user',
      'previousAccountType': accountType == 'craftsman' ? 'craftsman' : 'store_owner',
      'convertedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Restore deleted account
  Future<void> restoreAccount({
    required String accountId,
    required String accountType,
    required String adminId,
  }) async {
    final collection = _collection(accountType);
    final batch = _firestore.batch();

    // 1. Restore account status
    final accountRef = _firestore.collection(collection).doc(accountId);
    batch.update(accountRef, {
      'adminStatus': 'active',
      'deletedAt': FieldValue.delete(),
      'deletedBy': FieldValue.delete(),
      'lastAdminAction': {
        'action': 'restored',
        'by': adminId,
        'at': FieldValue.serverTimestamp(),
        'reason': 'تم استعادة الحساب',
      },
    });

    // 2. Restore role in users collection
    final userDoc = await _firestore.collection('users').doc(accountId).get();
    final previousType = userDoc.data()?['previousAccountType'];
    
    final userRef = _firestore.collection('users').doc(accountId);
    batch.update(userRef, {
      'role': previousType == 'craftsman' ? 'craftsman' : 'store_owner',
      'previousAccountType': FieldValue.delete(),
      'convertedAt': FieldValue.delete(),
    });

    await batch.commit();
  }

  /// Watch accounts by status
  Stream<List<Map<String, dynamic>>> watchAccountsByStatus({
    required String accountType,
    required String status,
  }) {
    final collection = _collection(accountType);
    return _firestore
        .collection(collection)
        .where('adminStatus', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => {
          'id': d.id,
          ...d.data(),
        }).toList());
  }
}
```

### Service 3: DashboardService

```dart
class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard quick stats (optimized for minimal reads)
  Future<Map<String, dynamic>> getQuickStats() async {
    // Use count() queries for efficiency
    final craftsmenCount = await _firestore.collection('craftsmen').count().get();
    final storesCount = await _firestore.collection('markets').count().get();
    final pendingReportsCount = await _firestore
        .collection('user_reports')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    // Get craftsmen by profession (aggregated on-demand)
    final craftsmenByProfession = await _getCraftsmenByProfession();

    // Get top craftsmen by calls
    final topCraftsmen = await _firestore
        .collection('craftsmen')
        .where('adminStatus', isEqualTo: 'active')
        .orderBy('totalCalls', descending: true)
        .limit(10)
        .get();

    return {
      'totalCraftsmen': craftsmenCount.count ?? 0,
      'totalStores': storesCount.count ?? 0,
      'pendingReports': pendingReportsCount.count ?? 0,
      'craftsmenByProfession': craftsmenByProfession,
      'topCraftsmen': topCraftsmen.docs.map((d) => {
        'id': d.id,
        'name': d.data()['name'] ?? '',
        'profession': d.data()['profession'] ?? '',
        'totalCalls': d.data()['totalCalls'] ?? 0,
        'totalWhatsApp': d.data()['totalWhatsApp'] ?? 0,
      }).toList(),
    };
  }

  Future<Map<String, int>> _getCraftsmenByProfession() async {
    final snapshot = await _firestore
        .collection('craftsmen')
        .where('adminStatus', isEqualTo: 'active')
        .get();

    final Map<String, int> counts = {};
    for (final doc in snapshot.docs) {
      final profession = doc.data()['profession'] ?? 'غير محدد';
      counts[profession] = (counts[profession] ?? 0) + 1;
    }
    return counts;
  }
}
```

## Cloud Functions

### Function: onReportCreated

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.onReportCreated = functions.firestore
  .document('user_reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const { targetId, targetType } = report;

    const collection = targetType === 'craftsman' ? 'craftsmen' :
                      targetType === 'store' ? 'markets' : 'courier_requests';

    // 1. Increment reportCount on target entity
    await admin.firestore().collection(collection).doc(targetId).update({
      reportCount: admin.firestore.FieldValue.increment(1)
    });

    // 2. Send FCM notification to admins only
    await admin.messaging().send({
      topic: 'admin_notifications',
      notification: {
        title: 'بلاغ جديد',
        body: `تم الإبلاغ عن ${targetType === 'craftsman' ? 'صنايعي' : 'متجر'}`
      },
      data: {
        reportId: context.params.reportId,
        targetId: targetId,
        type: 'new_report'
      }
    });

    return null;
  });
```

## Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isAdmin() {
      return isAuthenticated() &&
             request.auth.token.role == 'admin';
    }

    function isModerator() {
      return isAuthenticated() &&
             (request.auth.token.role == 'admin' || request.auth.token.role == 'moderator');
    }

    // ============= USER REPORTS =============
    match /user_reports/{reportId} {
      // Users can read their own reports
      allow read: if isAuthenticated() &&
                    resource.data.reporterId == request.auth.uid;

      // Users can create reports
      allow create: if isAuthenticated() &&
                      request.resource.data.reporterId == request.auth.uid;

      // Only admins and moderators can manage reports
      allow read, update: if isModerator();
    }

    // ============= CRAFTSMEN =============
    match /craftsmen/{craftsmanId} {
      // Public read
      allow read: if true;

      // Only admins can update admin fields
      allow update: if isAdmin() &&
                      request.resource.data.diff(resource.data)
                        .affectedKeys()
                        .hasOnly(['adminStatus', 'deletedAt', 'deletedBy',
                                 'reportCount', 'totalCalls', 'totalWhatsApp',
                                 'totalViews', 'lastAdminAction']);
    }

    // ============= MARKETS =============
    match /markets/{marketId} {
      allow read: if true;
      allow update: if isAdmin() &&
                      request.resource.data.diff(resource.data)
                        .affectedKeys()
                        .hasOnly(['adminStatus', 'deletedAt', 'deletedBy',
                                 'reportCount', 'totalCalls', 'totalWhatsApp',
                                 'totalViews', 'lastAdminAction']);
    }

    // ============= COURIER REQUESTS =============
    match /courier_requests/{courierId} {
      allow read: if true;
      allow update: if isAdmin() &&
                      request.resource.data.diff(resource.data)
                        .affectedKeys()
                        .hasOnly(['adminStatus', 'deletedAt', 'deletedBy',
                                 'reportCount', 'lastAdminAction']);
    }

    // ============= USERS =============
    match /users/{userId} {
      allow read: if isAuthenticated() &&
                    (request.auth.uid == userId || isAdmin());

      // Only admins can update role and conversion fields
      allow update: if isAdmin() &&
                      request.resource.data.diff(resource.data)
                        .affectedKeys()
                        .hasOnly(['role', 'previousAccountType', 'convertedAt']);
    }
  }
}
```

## Composite Indexes

```json
{
  "indexes": [
    {
      "collectionGroup": "user_reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "user_reports",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "targetId", "order": "ASCENDING" },
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
      "collectionGroup": "craftsmen",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "adminStatus", "order": "ASCENDING" },
        { "fieldPath": "totalCalls", "order": "DESCENDING" }
      ]
    }
  ]
}
```

## UI Pages Structure

### Page 1: AdminDashboardPage

```dart
class AdminDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('لوحة التحكم')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: DashboardService().getQuickStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Quick stats cards
                Row(
                  children: [
                    _StatCard(
                      title: 'الصنايعية',
                      value: stats['totalCraftsmen'].toString(),
                      icon: Icons.construction,
                    ),
                    SizedBox(width: 12),
                    _StatCard(
                      title: 'المتاجر',
                      value: stats['totalStores'].toString(),
                      icon: Icons.store,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _StatCard(
                  title: 'البلاغات المعلقة',
                  value: stats['pendingReports'].toString(),
                  icon: Icons.report_problem,
                  color: Colors.orange,
                ),
                
                // Craftsmen by profession
                SizedBox(height: 24),
                _SectionTitle('الصنايعية حسب المهنة'),
                ...stats['craftsmenByProfession'].entries.map((e) =>
                  ListTile(
                    title: Text(e.key),
                    trailing: Text('${e.value}'),
                  )
                ).toList(),

                // Top craftsmen
                SizedBox(height: 24),
                _SectionTitle('أكثر الصنايعية تفاعلاً'),
                ...stats['topCraftsmen'].map((c) => ListTile(
                  leading: CircleAvatar(child: Text('${c['totalCalls']}')),
                  title: Text(c['name']),
                  subtitle: Text(c['profession']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, size: 16),
                      Text('${c['totalCalls']}'),
                      SizedBox(width: 8),
                      Icon(Icons.message, size: 16),
                      Text('${c['totalWhatsApp']}'),
                    ],
                  ),
                )).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### Page 2: ReportsListPage

```dart
class ReportsListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('البلاغات')),
      body: StreamBuilder<List<UserReport>>(
        stream: ReportService().watchPendingReports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return Center(child: Text('لا توجد بلاغات معلقة'));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: Icon(Icons.report, color: Colors.red),
                  ),
                  title: Text('بلاغ عن ${report.targetType == 'craftsman' ? 'صنايعي' : 'متجر'}'),
                  subtitle: Text(
                    report.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: TextButton(
                    child: Text('التفاصيل'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailPage(report: report),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

## Error Handling

### Pattern 1: User Not Found

```dart
try {
  await AdminAccountService().deleteAccount(
    accountId: accountId,
    accountType: 'craftsman',
    adminId: adminId,
    reason: reason,
  );
} catch (e) {
  if (e.toString().contains('not-found')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('المستخدم غير موجود')),
    );
    Navigator.pop(context);
  }
}
```

### Pattern 2: Permission Denied

```dart
try {
  final reports = await ReportService().watchPendingReports().first;
} catch (e) {
  if (e.toString().contains('permission-denied')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ليس لديك صلاحيات')),
    );
    Navigator.pushReplacementNamed(context, '/home');
  }
}
```

### Pattern 3: Network Failure

```dart
try {
  await ReportService().resolveReport(
    reportId: reportId,
    adminId: adminId,
    resolution: resolution,
  );
} catch (e) {
  if (e.toString().contains('network') || e.toString().contains('timeout')) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خطأ في الاتصال'),
        content: Text('حدث خطأ، حاول مرة أخرى'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
```

## Cost Optimization Summary

### Firestore Costs (per 100k operations)

| Operation | Cost Estimate |
|-----------|---------------|
| Dashboard load | ~$0.01 (count queries + 1 aggregation) |
| Report creation | ~$0.02 (1 write + Cloud Function) |
| Account delete | ~$0.01 (batch: 2 writes) |
| List 100 craftsmen | ~$0.03 (100 reads) |

**Monthly Estimate (10k reports, 1k accounts, 100k reads):** ~$5-10

**Avoided Costs:**
- No separate stats collection (would add $50-100/month)
- No user FCM notifications (would add $5-10/month)
- No verification system (would add $20-30/month)

## Implementation Timeline

| Day | Tasks |
|-----|-------|
| Day 1 | Data models + ReportService + user_reports collection |
| Day 2 | AdminAccountService (approve, reject, suspend, ban, delete, restore) |
| Day 3 | DashboardService + AdminDashboardPage |
| Day 4 | ReportsListPage + ReportDetailPage |
| Day 5 | UsersListPage + UserDetailPage (with tabs) |
| Day 6 | Image management + portfolio deletion |
| Day 7 | Cloud Function + Security Rules + Testing |

**Total: 1 week (7 days)**
