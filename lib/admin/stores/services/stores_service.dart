import 'package:cloud_firestore/cloud_firestore.dart';

class StoresService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // تجديد الاشتراك - محلي باستخدام Firestore
  // موحد مع LicenseService - يحسب التاريخ بناءً على الاشتراك الحالي أو من الآن
  Future<Map<String, dynamic>> renewSubscription(
    String storeId,
    String packageId,
  ) async {
    try {
      // جلب بيانات الباقة
      final packageDoc =
          await _firestore.collection('packages').doc(packageId).get();
      if (!packageDoc.exists) {
        return {'success': false, 'message': 'الباقة غير موجودة'};
      }

      final packageData = packageDoc.data()!;
      final days = packageData['days'] as int? ?? 0;
      final packageName = packageData['name'] as String? ?? '';

      // جلب بيانات المتجر
      final storeDoc =
          await _firestore.collection('markets').doc(storeId).get();
      if (!storeDoc.exists) {
        return {'success': false, 'message': 'المتجر غير موجود'};
      }

      final storeData = storeDoc.data()!;
      final now = DateTime.now();
      final nowTimestamp = Timestamp.now();

      // قراءة تاريخ النهاية الحالي - نستخدم licenseEndAt كمصدر رئيسي
      DateTime? _readDate(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return null;
      }

      final currentEnd = _readDate(storeData['licenseEndAt']);
      
      // إذا كان الاشتراك الحالي نشط (لم ينتهِ بعد)، نضيف الأيام من تاريخ النهاية الحالي
      // وإلا نبدأ من الآن
      final base = (currentEnd != null && currentEnd.isAfter(now)) ? currentEnd : now;
      final newEnd = base.add(Duration(days: days));
      final newEndTimestamp = Timestamp.fromDate(newEnd);

      // تحديث بيانات المتجر - الحقول الرئيسية فقط: licenseStartAt و licenseEndAt
      await _firestore.collection('markets').doc(storeId).update({
        'licenseStartAt': nowTimestamp,
        'licenseEndAt': newEndTimestamp,
        'licenseDurationDays': days,
        'licenseAutoRenew': storeData['licenseAutoRenew'] ?? false,
        // معلومات الباقة
        'currentPackageId': packageId,
        'currentPackageName': packageName,
        // حالة المتجر
        'isActive': true,
        'canAddProducts': true,
        'canReceiveOrders': true,
        'status': 'active',
        'isVisible': true,
        'deactivatedAt': null,
      });

      return {
        'success': true,
        'message': 'تم التجديد بنجاح',
        'licenseEndAt': newEnd.toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ في التجديد: ${e.toString()}'};
    }
  }

  // إضافة/طرح أيام - محلي باستخدام Firestore
  // موحد - يستخدم licenseEndAt كمصدر رئيسي
  Future<Map<String, dynamic>> addDaysToSubscription(
    String storeId,
    int days,
  ) async {
    try {
      // جلب بيانات المتجر
      final storeDoc =
          await _firestore.collection('markets').doc(storeId).get();
      if (!storeDoc.exists) {
        return {'success': false, 'message': 'المتجر غير موجود'};
      }

      final storeData = storeDoc.data()!;
      final now = DateTime.now();

      // قراءة تاريخ النهاية الحالي - licenseEndAt هو المصدر الرئيسي
      DateTime? _readDate(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is DateTime) return v;
        return null;
      }

      final currentEnd = _readDate(storeData['licenseEndAt']) ?? now;
      
      // حساب تاريخ الانتهاء الجديد
      final newEnd = currentEnd.add(Duration(days: days));
      final newEndTimestamp = Timestamp.fromDate(newEnd);

      // التحقق من أن التاريخ الجديد في المستقبل
      final isActive = newEnd.isAfter(now);

      // تحديث بيانات المتجر - الحقل الرئيسي فقط: licenseEndAt
      await _firestore.collection('markets').doc(storeId).update({
        'licenseEndAt': newEndTimestamp,
        // حالة المتجر
        'isActive': isActive,
        'canAddProducts': isActive,
        'canReceiveOrders': isActive,
        'status': isActive ? 'active' : 'expired',
        'isVisible': isActive,
      });

      final action = days > 0 ? 'إضافة' : 'طرح';
      final daysAbs = days.abs();

      return {
        'success': true,
        'message': 'تم $action $daysAbs يوم بنجاح',
        'licenseEndAt': newEnd.toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ: ${e.toString()}'};
    }
  }

  // إيقاف الترخيص - محلي باستخدام Firestore
  Future<Map<String, dynamic>> suspendSubscription(String storeId) async {
    try {
      // جلب بيانات المتجر
      final storeDoc =
          await _firestore.collection('markets').doc(storeId).get();
      if (!storeDoc.exists) {
        return {'success': false, 'message': 'المتجر غير موجود'};
      }

      final now = Timestamp.now();

      // تحديث بيانات المتجر
      await _firestore.collection('markets').doc(storeId).update({
        'isActive': false,
        'canAddProducts': false,
        'canReceiveOrders': false,
        'status': 'suspended',
        'isVisible': false,
        'suspendedAt': now,
      });

      return {
        'success': true,
        'message': 'تم إيقاف ترخيص المتجر بنجاح',
      };
    } catch (e) {
      return {'success': false, 'message': 'خطأ: ${e.toString()}'};
    }
  }
}
