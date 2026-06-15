import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get dashboard quick stats (optimized for minimal reads)
  Future<Map<String, dynamic>> getQuickStats() async {
    try {
      // Use count() queries for efficiency
      final craftsmenCountFuture = _firestore.collection('craftsmen').count().get();
      final storesCountFuture = _firestore.collection('markets').count().get();
      final couriersCountFuture =
          _firestore.collection('courier_requests').count().get();
      final pendingReportsCountFuture = _firestore
          .collection('user_reports')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      // Wait for all counts
      final results = await Future.wait([
        craftsmenCountFuture,
        storesCountFuture,
        couriersCountFuture,
        pendingReportsCountFuture,
      ]).timeout(Duration(seconds: 30));

      // Get craftsmen by profession (aggregated on-demand)
      final craftsmenByProfession = await _getCraftsmenByProfession();

      // Get top craftsmen by calls
      final topCraftsmen = await _getTopCraftsmen();

      // Get pending counts
      final pendingCraftsmen = await _getPendingCount('craftsmen');
      final pendingStores = await _getPendingCount('markets');
      final pendingCouriers = await _getPendingCount('courier_requests');

      return {
        'totalCraftsmen': results[0].count ?? 0,
        'totalStores': results[1].count ?? 0,
        'totalCouriers': results[2].count ?? 0,
        'pendingReports': results[3].count ?? 0,
        'pendingCraftsmen': pendingCraftsmen,
        'pendingStores': pendingStores,
        'pendingCouriers': pendingCouriers,
        'craftsmenByProfession': craftsmenByProfession,
        'topCraftsmen': topCraftsmen,
      };
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض الإحصائيات');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Get craftsmen count by profession
  Future<Map<String, int>> _getCraftsmenByProfession() async {
    try {
      final snapshot = await _firestore
          .collection('craftsmen')
          .where('adminStatus', isEqualTo: 'active')
          .get()
          .timeout(Duration(seconds: 30));

      final Map<String, int> counts = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final profession = data['profession'] ?? 'غير محدد';
        counts[profession] = (counts[profession] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      print('Error getting craftsmen by profession: $e');
      return {};
    }
  }

  /// Get top craftsmen by total calls
  Future<List<Map<String, dynamic>>> _getTopCraftsmen() async {
    try {
      final snapshot = await _firestore
          .collection('craftsmen')
          .where('adminStatus', isEqualTo: 'active')
          .orderBy('totalCalls', descending: true)
          .limit(10)
          .get()
          .timeout(Duration(seconds: 30));

      return snapshot.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['name'] ?? '',
          'profession': data['profession'] ?? '',
          'totalCalls': data['totalCalls'] ?? 0,
          'totalWhatsApp': data['totalWhatsApp'] ?? 0,
          'totalViews': data['totalViews'] ?? 0,
          'reportCount': data['reportCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error getting top craftsmen: $e');
      return [];
    }
  }

  /// Get pending count for a collection
  Future<int> _getPendingCount(String collection) async {
    try {
      final snapshot = await _firestore
          .collection(collection)
          .where('adminStatus', isEqualTo: 'pending')
          .count()
          .get()
          .timeout(Duration(seconds: 30));

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting pending count for $collection: $e');
      return 0;
    }
  }

  /// Get store statistics
  Future<Map<String, dynamic>> getStoreStats() async {
    try {
      // Get total stores
      final totalStoresSnapshot =
          await _firestore.collection('markets').count().get();

      // Get stores by category
      final storesByCategory = await _getStoresByCategory();

      // Get top stores by interactions
      final topStores = await _getTopStores();

      // Get pending stores
      final pendingStores = await _getPendingCount('markets');

      return {
        'totalStores': totalStoresSnapshot.count ?? 0,
        'pendingStores': pendingStores,
        'storesByCategory': storesByCategory,
        'topStores': topStores,
      };
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض إحصائيات المتاجر');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Get stores count by category
  Future<Map<String, int>> _getStoresByCategory() async {
    try {
      final snapshot = await _firestore
          .collection('markets')
          .where('adminStatus', isEqualTo: 'active')
          .get()
          .timeout(Duration(seconds: 30));

      final Map<String, int> counts = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'غير محدد';
        counts[category] = (counts[category] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      print('Error getting stores by category: $e');
      return {};
    }
  }

  /// Get top stores by interactions
  Future<List<Map<String, dynamic>>> _getTopStores() async {
    try {
      final snapshot = await _firestore
          .collection('markets')
          .where('adminStatus', isEqualTo: 'active')
          .orderBy('totalCalls', descending: true)
          .limit(10)
          .get()
          .timeout(Duration(seconds: 30));

      return snapshot.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'name': data['name'] ?? '',
          'category': data['category'] ?? '',
          'totalCalls': data['totalCalls'] ?? 0,
          'totalWhatsApp': data['totalWhatsApp'] ?? 0,
          'totalViews': data['totalViews'] ?? 0,
          'reportCount': data['reportCount'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error getting top stores: $e');
      return [];
    }
  }

  /// Get courier statistics
  Future<Map<String, dynamic>> getCourierStats() async {
    try {
      // Get total couriers
      final totalCouriersSnapshot =
          await _firestore.collection('courier_requests').count().get();

      // Get pending couriers
      final pendingCouriers = await _getPendingCount('courier_requests');

      return {
        'totalCouriers': totalCouriersSnapshot.count ?? 0,
        'pendingCouriers': pendingCouriers,
      };
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض إحصائيات الكوريرات');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      }
      rethrow;
    }
  }

  /// Get reports statistics
  Future<Map<String, dynamic>> getReportsStats() async {
    try {
      final pendingCount = await _firestore
          .collection('user_reports')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();

      final resolvedCount = await _firestore
          .collection('user_reports')
          .where('status', isEqualTo: 'resolved')
          .count()
          .get();

      final dismissedCount = await _firestore
          .collection('user_reports')
          .where('status', isEqualTo: 'dismissed')
          .count()
          .get();

      return {
        'pending': pendingCount.count ?? 0,
        'resolved': resolvedCount.count ?? 0,
        'dismissed': dismissedCount.count ?? 0,
        'total': (pendingCount.count ?? 0) +
            (resolvedCount.count ?? 0) +
            (dismissedCount.count ?? 0),
      };
    } catch (e) {
      print('Error getting reports stats: $e');
      return {
        'pending': 0,
        'resolved': 0,
        'dismissed': 0,
        'total': 0,
      };
    }
  }
}
