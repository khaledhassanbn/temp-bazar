import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StoresService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'europe-west1',
  );

  // الحصول على stream للمتاجر
  Stream<QuerySnapshot> getStoresStream() {
    return _firestore.collection('markets').snapshots();
  }

  // الحصول على بيانات المستخدم حسب marketId
  Future<Map<String, dynamic>?> getUserDataByMarketId(String marketId) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('market_id', isEqualTo: marketId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return doc.data()..['uid'] = doc.id;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }

  // الحصول على عدد المنتجات
  Future<int> getProductCount(
    String marketId,
    Map<String, dynamic> storeData,
  ) async {
    try {
      if (storeData['totalProducts'] != null) {
        return storeData['totalProducts'] as int;
      }

      int totalCount = 0;
      final categories = await _firestore
          .collection('markets')
          .doc(marketId)
          .collection('products')
          .get();

      for (var category in categories.docs) {
        final count = category.data()['numberOfProducts'] as int? ?? 0;
        totalCount += count;
      }

      await _firestore.collection('markets').doc(marketId).update({
        'totalProducts': totalCount,
      });

      return totalCount;
    } catch (e) {
      print('Error counting products: $e');
      return storeData['totalProducts'] as int? ?? 0;
    }
  }

  // الحصول على قائمة الباقات
  Future<QuerySnapshot> getPackages() async {
    return await _firestore.collection('packages').orderBy('orderIndex').get();
  }

  // تجديد الاشتراك
  Future<Map<String, dynamic>> renewSubscription(
    String storeId,
    String packageId,
  ) async {
    try {
      final result = await _functions
          .httpsCallable('renewStoreSubscriptionCallable')
          .call({'storeId': storeId, 'packageId': packageId});

      return {
        'success': true,
        'message': result.data['message'] ?? 'تم التجديد بنجاح',
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في التجديد: ${e.toString()}'};
    }
  }

  // إضافة/طرح أيام
  Future<Map<String, dynamic>> addDaysToSubscription(
    String storeId,
    int days,
  ) async {
    try {
      final result = await _functions
          .httpsCallable('addDaysToStoreSubscriptionCallable')
          .call({'storeId': storeId, 'days': days});

      return {
        'success': true,
        'message':
            result.data['message'] ??
            (days > 0
                ? 'تم إضافة $days يوم بنجاح'
                : 'تم طرح ${days.abs()} يوم بنجاح'),
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ: ${e.toString()}'};
    }
  }

  // إيقاف الترخيص
  Future<Map<String, dynamic>> suspendSubscription(String storeId) async {
    try {
      final result = await _functions
          .httpsCallable('suspendStoreSubscriptionCallable')
          .call({'storeId': storeId});

      return {
        'success': true,
        'message': result.data['message'] ?? 'تم إيقاف الترخيص بنجاح',
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ: ${e.toString()}'};
    }
  }
}
