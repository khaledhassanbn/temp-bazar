import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseDebugHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// تشخيص حالة Firebase
  static Future<Map<String, dynamic>> diagnoseFirebase() async {
    final Map<String, dynamic> diagnosis = {
      'timestamp': DateTime.now().toIso8601String(),
      'firebase_connected': false,
      'user_authenticated': false,
      'user_email': null,
      'user_stores': [],
      'errors': [],
    };

    try {
      // 1. التحقق من اتصال Firebase
      await _firestore.collection('test').limit(1).get();
      diagnosis['firebase_connected'] = true;
    } catch (e) {
      diagnosis['errors'].add('Firebase connection error: $e');
    }

    try {
      // 2. التحقق من تسجيل الدخول
      final user = _auth.currentUser;
      if (user != null) {
        diagnosis['user_authenticated'] = true;
        diagnosis['user_email'] = user.email;

        // 3. جلب متاجر المستخدم
        if (user.email != null) {
          final storesQuery = await _firestore
              .collection('markets')
              .where('email', isEqualTo: user.email)
              .get();

          diagnosis['user_stores'] = storesQuery.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  'name': doc.data()['name'] ?? 'غير محدد',
                  'link': doc.data()['link'] ?? 'غير محدد',
                },
              )
              .toList();
        }
      }
    } catch (e) {
      diagnosis['errors'].add('User authentication error: $e');
    }

    return diagnosis;
  }

  /// تشخيص متجر محدد
  static Future<Map<String, dynamic>> diagnoseStore(String storeId) async {
    final Map<String, dynamic> diagnosis = {
      'store_id': storeId,
      'store_exists': false,
      'store_data': null,
      'categories_exist': false,
      'categories_count': 0,
      'categories': [],
      'errors': [],
    };

    try {
      // 1. التحقق من وجود المتجر
      final storeDoc = await _firestore
          .collection('markets')
          .doc(storeId)
          .get();
      if (storeDoc.exists) {
        diagnosis['store_exists'] = true;
        diagnosis['store_data'] = storeDoc.data();

        // 2. التحقق من وجود الفئات
        final categoriesQuery = await _firestore
            .collection('markets')
            .doc(storeId)
            .collection('products')
            .get();

        diagnosis['categories_exist'] = categoriesQuery.docs.isNotEmpty;
        diagnosis['categories_count'] = categoriesQuery.docs.length;
        diagnosis['categories'] = categoriesQuery.docs
            .map(
              (doc) => {
                'id': doc.id,
                'name': doc.data()['name'] ?? 'غير محدد',
                'order': doc.data()['order'] ?? 0,
              },
            )
            .toList();
      }
    } catch (e) {
      diagnosis['errors'].add('Store diagnosis error: $e');
    }

    return diagnosis;
  }

  /// إنشاء فئات افتراضية لمتجر
  static Future<bool> createDefaultCategories(String storeId) async {
    try {
      // فئة "الأكثر مبيعاً"
      await _firestore
          .collection('markets')
          .doc(storeId)
          .collection('products')
          .doc('الأكثر مبيعاً')
          .set({'name': 'الأكثر مبيعاً', 'order': 1});

      // فئة "العروض"
      await _firestore
          .collection('markets')
          .doc(storeId)
          .collection('products')
          .doc('العروض')
          .set({'name': 'العروض', 'order': 2});

      return true;
    } catch (e) {
      print('خطأ في إنشاء الفئات الافتراضية: $e');
      return false;
    }
  }

  /// طباعة تقرير التشخيص
  static void printDiagnosis(Map<String, dynamic> diagnosis) {
    print('=== Firebase Diagnosis Report ===');
    print('Timestamp: ${diagnosis['timestamp']}');
    print('Firebase Connected: ${diagnosis['firebase_connected']}');
    print('User Authenticated: ${diagnosis['user_authenticated']}');
    print('User Email: ${diagnosis['user_email']}');
    print('User Stores Count: ${(diagnosis['user_stores'] as List).length}');

    if (diagnosis['errors'].isNotEmpty) {
      print('Errors:');
      for (final error in diagnosis['errors']) {
        print('  - $error');
      }
    }

    print('===============================');
  }
}
