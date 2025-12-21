# Flutter Integration Guide - Store Subscription System

Complete guide for integrating the subscription system into your Flutter app.

## 📋 Table of Contents

- [Overview](#overview)
- [Setup](#setup)
- [Checking Store Status](#checking-store-status)
- [Hiding Expired Stores](#hiding-expired-stores)
- [Blocking Restricted Actions](#blocking-restricted-actions)
- [Showing Renewal Messages](#showing-renewal-messages)
- [Redirecting to Pricing Page](#redirecting-to-pricing-page)
- [Complete Examples](#complete-examples)

---

## 🎯 Overview

This guide shows you how to:

1. ✅ Check if a store's subscription is active
2. ✅ Hide expired stores from `FoodHomePage`
3. ✅ Block adding products when subscription expired
4. ✅ Block receiving orders when subscription expired
5. ✅ Show "subscription expired" messages
6. ✅ Redirect users to pricing page automatically

---

## 🚀 Setup

### 1. Add Dependencies

Ensure you have these packages in `pubspec.yaml`:

```yaml
dependencies:
  cloud_firestore: ^latest
  cloud_functions: ^latest
  firebase_core: ^latest
```

### 2. Initialize Firebase

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

---

## 🔍 Checking Store Status

### Basic Status Check

```dart
import 'package:cloud_functions/cloud_functions.dart';

class SubscriptionService {
  static Future<Map<String, dynamic>?> checkStoreStatus(String storeId) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('checkStoreStatusCallable')
          .call({'storeId': storeId});

      return result.data as Map<String, dynamic>;
    } catch (e) {
      print('Error checking store status: $e');
      return null;
    }
  }
}
```

### Response Structure

```dart
{
  'isActive': bool,           // Is subscription active?
  'needsRenewal': bool,       // Needs renewal (expired or < 7 days)
  'expiryDate': String?,      // ISO date string or null
  'remainingDays': int,       // Days until expiry
  'subscription': {
    'packageName': String?,
    'startDate': String?,
    'endDate': String?,
    'durationDays': int?
  }
}
```

### Usage Example

```dart
final status = await SubscriptionService.checkStoreStatus('storeId123');

if (status != null) {
  print('Is Active: ${status['isActive']}');
  print('Remaining Days: ${status['remainingDays']}');
  print('Package: ${status['subscription']['packageName']}');
}
```

---

## 👁️ Hiding Expired Stores

### Method 1: Filter in Query (Recommended)

**Update `FoodHomePage` to filter expired stores:**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Only fetch active, visible stores
      stream: FirebaseFirestore.instance
          .collection('markets')
          .where('isVisible', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final stores = snapshot.data!.docs;

        return ListView.builder(
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index].data() as Map<String, dynamic>;
            return StoreCard(store: store);
          },
        );
      },
    );
  }
}
```

### Method 2: Client-Side Filtering

If you need to fetch all stores and filter client-side:

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('markets')
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }

    // Filter expired stores
    final activeStores = snapshot.data!.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isVisible'] == true && 
             data['isActive'] == true;
    }).toList();

    return ListView.builder(
      itemCount: activeStores.length,
      itemBuilder: (context, index) {
        final store = activeStores[index].data() as Map<String, dynamic>;
        return StoreCard(store: store);
      },
    );
  },
)
```

### Firestore Index Required

Create this composite index in Firestore Console:

```
Collection: markets
Fields:
  - isVisible (Ascending)
  - isActive (Ascending)
```

Or use Firebase CLI:

```bash
firebase firestore:indexes
```

Add to `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "markets",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isVisible", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## 🚫 Blocking Restricted Actions

### Block Adding Products

**In your `AddProductPage` or `AddProductViewModel`:**

```dart
import 'package:flutter/material.dart';

class AddProductPage extends StatefulWidget {
  final String storeId;

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  bool _canAddProducts = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() => _isChecking = true);

    final status = await SubscriptionService.checkStoreStatus(widget.storeId);

    if (status != null) {
      setState(() {
        _canAddProducts = status['isActive'] == true && 
                         status['canAddProducts'] == true;
        _isChecking = false;
      });

      // Show message if expired
      if (!_canAddProducts) {
        _showExpiredDialog();
      }
    } else {
      setState(() {
        _canAddProducts = false;
        _isChecking = false;
      });
    }
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('اشتراكك منتهي'),
        content: Text('انتهت صلاحية اشتراكك. يرجى التجديد للمتابعة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to pricing page
              Navigator.pushNamed(context, '/pricing');
            },
            child: Text('تجديد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        appBar: AppBar(title: Text('إضافة منتج')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canAddProducts) {
      return Scaffold(
        appBar: AppBar(title: Text('إضافة منتج')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'اشتراكك منتهي',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('انتهت صلاحية اشتراكك. يرجى التجديد للمتابعة.'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/pricing'),
                child: Text('تجديد الاشتراك'),
              ),
            ],
          ),
        ),
      );
    }

    // Normal add product UI
    return Scaffold(
      appBar: AppBar(title: Text('إضافة منتج')),
      body: YourAddProductForm(),
    );
  }
}
```

### Block Receiving Orders

**In your `OrdersPage` or order processing logic:**

```dart
Future<bool> canReceiveOrders(String storeId) async {
  final status = await SubscriptionService.checkStoreStatus(storeId);
  
  if (status == null) return false;
  
  return status['isActive'] == true && 
         status['canReceiveOrders'] == true;
}

// Usage
void _processOrder(String storeId) async {
  if (!await canReceiveOrders(storeId)) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('لا يمكن استقبال الطلبات'),
        content: Text('انتهت صلاحية اشتراكك. يرجى التجديد.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/pricing');
            },
            child: Text('تجديد'),
          ),
        ],
      ),
    );
    return;
  }

  // Process order normally
}
```

### Block Editing Store Details

**In your `EditStorePage`:**

```dart
class EditStorePage extends StatefulWidget {
  final String storeId;

  @override
  _EditStorePageState createState() => _EditStorePageState();
}

class _EditStorePageState extends State<EditStorePage> {
  bool _canEdit = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    final status = await SubscriptionService.checkStoreStatus(widget.storeId);
    
    setState(() {
      _canEdit = status?['isActive'] == true;
      _isChecking = false;
    });

    if (!_canEdit) {
      _showExpiredMessage();
    }
  }

  void _showExpiredMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('انتهت صلاحية اشتراكك. يرجى التجديد.'),
          action: SnackBarAction(
            label: 'تجديد',
            onPressed: () => Navigator.pushNamed(context, '/pricing'),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        appBar: AppBar(title: Text('تعديل المتجر')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canEdit) {
      return Scaffold(
        appBar: AppBar(title: Text('تعديل المتجر')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('لا يمكن التعديل'),
              Text('انتهت صلاحية اشتراكك'),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/pricing'),
                child: Text('تجديد الاشتراك'),
              ),
            ],
          ),
        ),
      );
    }

    // Normal edit store UI
    return Scaffold(
      appBar: AppBar(title: Text('تعديل المتجر')),
      body: YourEditStoreForm(),
    );
  }
}
```

---

## 💬 Showing Renewal Messages

### Automatic Renewal Dialog

**Create a reusable widget:**

```dart
class RenewalDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onRenew;

  const RenewalDialog({
    Key? key,
    required this.message,
    this.onRenew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('تجديد الاشتراك'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('لاحقاً'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            if (onRenew != null) {
              onRenew!();
            } else {
              Navigator.pushNamed(context, '/pricing');
            }
          },
          child: Text('تجديد الآن'),
        ),
      ],
    );
  }
}
```

### Usage in Pages

```dart
void _checkAndShowRenewalDialog(String storeId) async {
  final status = await SubscriptionService.checkStoreStatus(storeId);
  
  if (status != null && status['needsRenewal'] == true) {
    final remainingDays = status['remainingDays'] as int;
    String message;
    
    if (remainingDays == 0) {
      message = 'انتهت صلاحية اشتراكك. يرجى التجديد للمتابعة.';
    } else {
      message = 'سينتهي اشتراكك خلال $remainingDays يوم. يرجى التجديد.';
    }
    
    showDialog(
      context: context,
      builder: (context) => RenewalDialog(
        message: message,
        onRenew: () => Navigator.pushNamed(context, '/pricing'),
      ),
    );
  }
}
```

---

## 🔄 Redirecting to Pricing Page

### Automatic Redirect on Expiry

**Create a guard/middleware:**

```dart
class SubscriptionGuard extends StatelessWidget {
  final String storeId;
  final Widget child;

  const SubscriptionGuard({
    Key? key,
    required this.storeId,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SubscriptionService.checkStoreStatus(storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final status = snapshot.data;
        
        if (status != null && status['isActive'] != true) {
          // Redirect to pricing page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/pricing');
          });
          
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جارٍ التحقق من الاشتراك...'),
                ],
              ),
            ),
          );
        }

        return child;
      },
    );
  }
}
```

### Usage

```dart
SubscriptionGuard(
  storeId: 'storeId123',
  child: YourProtectedPage(),
)
```

---

## 📝 Complete Examples

### Example 1: Store Dashboard with Status

```dart
class StoreDashboard extends StatefulWidget {
  final String storeId;

  @override
  _StoreDashboardState createState() => _StoreDashboardState();
}

class _StoreDashboardState extends State<StoreDashboard> {
  Map<String, dynamic>? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await SubscriptionService.checkStoreStatus(widget.storeId);
    setState(() {
      _status = status;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isActive = _status?['isActive'] == true;
    final remainingDays = _status?['remainingDays'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text('لوحة التحكم')),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.check_circle : Icons.error,
                        color: isActive ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        isActive ? 'اشتراك نشط' : 'اشتراك منتهي',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('الأيام المتبقية: $remainingDays'),
                  if (!isActive) ...[
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/pricing'),
                      child: Text('تجديد الاشتراك'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Rest of dashboard
        ],
      ),
    );
  }
}
```

### Example 2: Protected Add Product Button

```dart
class AddProductButton extends StatelessWidget {
  final String storeId;

  const AddProductButton({Key? key, required this.storeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: SubscriptionService.checkStoreStatus(storeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final status = snapshot.data;
        final canAdd = status?['isActive'] == true && 
                      status?['canAddProducts'] == true;

        if (!canAdd) {
          return ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => RenewalDialog(
                  message: 'انتهت صلاحية اشتراكك. يرجى التجديد.',
                ),
              );
            },
            icon: Icon(Icons.lock),
            label: Text('إضافة منتج (مقفل)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
          );
        }

        return ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/add-product'),
          icon: Icon(Icons.add),
          label: Text('إضافة منتج'),
        );
      },
    );
  }
}
```

---

## 🎯 Best Practices

1. **Always check status before critical actions**
2. **Cache status results to reduce API calls**
3. **Show loading states while checking**
4. **Provide clear error messages**
5. **Make renewal process easy (one tap)**
6. **Use Firestore queries to filter expired stores server-side**

---

## 🔗 Related Documentation

- [Functions README](./README.md)
- [Firestore Security Rules](../firestore.rules)
- [Deployment Guide](./DEPLOYMENT.md)

---

## 📞 Support

For issues or questions, contact the development team.

