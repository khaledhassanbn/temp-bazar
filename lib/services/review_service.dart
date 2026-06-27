import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/models/review_model.dart';
import 'package:flutter/foundation.dart';

/// خدمة التعامل مع التقييمات
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// طباعة سجلات التصحيح بشكل محسن وملون
  void _logDebug(String message, {String type = 'INFO', Object? error}) {
    if (kDebugMode) {
      final String emoji;
      switch (type.toUpperCase()) {
        case 'ERROR':
          emoji = '❌ [ERROR]';
          break;
        case 'WARNING':
          emoji = '⚠️ [WARN]';
          break;
        case 'SUCCESS':
          emoji = '✅ [SUCCESS]';
          break;
        case 'BACKGROUND':
          emoji = '⚙️ [BG_TASK]';
          break;
        default:
          emoji = '⚡ [INFO]';
      }
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      print('$emoji [$timestamp] [ReviewService] $message');
      if (error != null) {
        print('   └─ Error Detail: $error');
      }
    }
  }

  /// إضافة تقييم للمتجر
  /// يتم حفظ التقييم في:
  /// 1. users/{userId}/orders/{orderId} → storeRating
  /// 2. markets/{storeId}/reviews/{reviewId} (للعرض في صفحة المتجر)
  /// 3. تحديث إحصائيات المتجر في markets/{storeId}/statistics
  Future<void> submitStoreRating({
    required String orderId,
    required String storeId,
    required int rating,
    String? comment,
    required List<String> tags,
    required String storeName,
  }) async {
    _logDebug('submitStoreRating: Starting process for storeId=$storeId, orderId=$orderId');
    final user = _auth.currentUser;
    if (user == null) {
      _logDebug('submitStoreRating failed: User not logged in', type: 'ERROR');
      throw Exception('يجب تسجيل الدخول');
    }

    final now = DateTime.now();
    final storeRating = StoreRatingInOrder(
      rating: rating,
      comment: comment,
      tags: tags,
      createdAt: now,
    );

    final reviewRef = _firestore
        .collection('markets')
        .doc(storeId)
        .collection('reviews')
        .doc();

    _logDebug('submitStoreRating: Initiating primary writes in parallel (Order rating update & Market review record)');
    final stopwatch = Stopwatch()..start();

    try {
      // 1 & 2: حفظ التقييم والريفيو بالتوازي باستخدام Future.wait
      await Future.wait([
        // 1. حفظ في document الطلب
        _firestore
            .collection('orders')
            .doc(orderId)
            .update({
          'storeRating': storeRating.toMap(),
        }),
        // 2. حفظ في markets/{storeId}/reviews collection
        reviewRef.set({
          'orderId': orderId,
          'userId': user.uid,
          'userName': user.displayName ?? 'مستخدم',
          'userPhoto': user.photoURL,
          'rating': rating,
          'comment': comment,
          'tags': tags,
          'createdAt': Timestamp.fromDate(now),
        }),
      ]);

      stopwatch.stop();
      _logDebug('submitStoreRating: Primary writes completed successfully in ${stopwatch.elapsedMilliseconds}ms', type: 'SUCCESS');

      // 3. تحديث إحصائيات المتجر في الخلفية (دون حجب واجهة المستخدم)
      _logDebug('submitStoreRating: Dispatching statistics update to background', type: 'BACKGROUND');
      _updateStoreRatingStatistics(storeId, rating).then((_) {
        _logDebug('submitStoreRating: Background statistics update completed for storeId=$storeId', type: 'SUCCESS');
      }).catchError((error) {
        _logDebug('submitStoreRating: Failed to update store statistics in background', type: 'ERROR', error: error);
      });

    } catch (e) {
      _logDebug('submitStoreRating: Primary writes failed', type: 'ERROR', error: e);
      rethrow;
    }
  }

  /// إضافة تقييم لشركة الشحن
  /// يتم حفظه في users/{userId}/orders/{orderId}/deliveryRating والـ courier_ratings
  Future<void> submitDeliveryRating({
    required String orderId,
    required int rating,
    String? comment,
    String? courierId,
    String? courierName,
  }) async {
    _logDebug('submitDeliveryRating: Starting process for orderId=$orderId');
    final user = _auth.currentUser;
    if (user == null) {
      _logDebug('submitDeliveryRating failed: User not logged in', type: 'ERROR');
      throw Exception('يجب تسجيل الدخول');
    }

    String resolvedCourierId = courierId ?? '';
    String resolvedCourierName = courierName ?? '';

    // لو المندوب مش مبعوث، نقرأ من الطلب
    if (resolvedCourierId.isEmpty || resolvedCourierName.isEmpty) {
      _logDebug('submitDeliveryRating: courier info not supplied. Fetching order document...', type: 'WARNING');
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      final orderData = orderDoc.data() ?? <String, dynamic>{};

      final deliveryRequest =
          (orderData['deliveryRequest'] is Map<String, dynamic>)
              ? orderData['deliveryRequest'] as Map<String, dynamic>
              : (orderData['deliveryRequest'] is Map
                  ? Map<String, dynamic>.from(orderData['deliveryRequest'] as Map)
                  : <String, dynamic>{});
      if (resolvedCourierId.isEmpty) {
        resolvedCourierId = (orderData['assignedCourierId'] ??
                deliveryRequest['courierId'] ??
                deliveryRequest['driverId'] ??
                deliveryRequest['assignedDriverId'] ??
                '')
            .toString();
      }
      if (resolvedCourierName.isEmpty) {
        resolvedCourierName = (deliveryRequest['assignedDriverName'] ??
                deliveryRequest['driverName'] ??
                orderData['assignedDriverName'] ??
                '')
            .toString();
      }
    }

    _logDebug('submitDeliveryRating: courierId=$resolvedCourierId, courierName=$resolvedCourierName');

    final deliveryRating = DeliveryRatingModel(
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    _logDebug('submitDeliveryRating: Initiating primary writes in parallel (Order delivery rating & Courier central ratings)');
    final stopwatch = Stopwatch()..start();

    try {
      // 1 & 2: تحديث الطلب وإضافة السجل المركزي بالتوازي باستخدام Future.wait
      await Future.wait([
        // 1. تحديث التقييم في الطلب
        _firestore
            .collection('orders')
            .doc(orderId)
            .update({
          'deliveryRating': {
            ...deliveryRating.toMap(),
            'courierId': resolvedCourierId,
            'courierName': resolvedCourierName,
            'ratedByUserId': user.uid,
          },
        }),
        // 2. سجل مركزي لتطبيق المناديب: query مباشر بـ courierId
        if (resolvedCourierId.isNotEmpty)
          _firestore.collection('courier_ratings').add({
            'orderId': orderId,
            'courierId': resolvedCourierId,
            'courierName': resolvedCourierName,
            'rating': rating,
            'comment': comment,
            'raterType': 'customer',
            'userId': user.uid,
            'userName': user.displayName ?? 'مستخدم',
            'createdAt': Timestamp.now(),
          })
        else
          Future.value(null),
      ]);

      stopwatch.stop();
      _logDebug('submitDeliveryRating: Primary writes completed successfully in ${stopwatch.elapsedMilliseconds}ms', type: 'SUCCESS');

      // 3. تحديث متوسط تقييم المندوب الموحد في courier_requests في الخلفية
      if (resolvedCourierId.isNotEmpty) {
        _logDebug('submitDeliveryRating: Dispatching courier average rating update to background', type: 'BACKGROUND');
        _updateCourierRatingAverage(resolvedCourierId, rating).then((_) {
          _logDebug('submitDeliveryRating: Background courier average update completed for courierId=$resolvedCourierId', type: 'SUCCESS');
        }).catchError((error) {
          _logDebug('submitDeliveryRating: Failed to update courier average rating in background', type: 'ERROR', error: error);
        });
      }

    } catch (e) {
      _logDebug('submitDeliveryRating: Primary writes failed', type: 'ERROR', error: e);
      rethrow;
    }
  }

  /// تحديث إحصائيات تقييم المتجر
  Future<void> _updateStoreRatingStatistics(String storeId, int newRating) async {
    _logDebug('_updateStoreRatingStatistics: Initiating transaction for storeId=$storeId', type: 'BACKGROUND');
    final statsRef = _firestore
        .collection('markets')
        .doc(storeId)
        .collection('statistics')
        .doc('rating');

    await _firestore.runTransaction((transaction) async {
      final statsDoc = await transaction.get(statsRef);

      Map<String, dynamic> currentData = {};
      if (statsDoc.exists) {
        currentData = statsDoc.data() ?? {};
      }

      final currentAverage = (currentData['averageRating'] ?? 0.0).toDouble();
      final currentTotal = (currentData['totalReviews'] ?? 0) as int;
      
      final distribution = Map<String, int>.from(
        currentData['ratingDistribution'] ?? {
          '5': 0, '4': 0, '3': 0, '2': 0, '1': 0
        },
      );

      // تحديث التوزيع
      final key = newRating.toString();
      distribution[key] = (distribution[key] ?? 0) + 1;

      // حساب المتوسط الجديد
      final newTotal = currentTotal + 1;
      final newAverage = ((currentAverage * currentTotal) + newRating) / newTotal;

      transaction.set(statsRef, {
        'averageRating': newAverage,
        'totalReviews': newTotal,
        'ratingDistribution': distribution,
        'lastUpdated': Timestamp.now(),
      }, SetOptions(merge: true));

      // 🔹 تحديث الوثيقة الرئيسية للمتجر لسهولة العرض في الرئيسية والبحث
      transaction.update(_firestore.collection('markets').doc(storeId), {
        'averageRating': newAverage,
        'totalReviews': newTotal,
      });
    });
  }

  /// جلب تقييمات متجر معين من markets/{storeId}/reviews
  Stream<List<ReviewModel>> getStoreReviews(String storeId) {
    return _firestore
        .collection('markets')
        .doc(storeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// جلب إحصائيات تقييم المتجر من markets/{storeId}/statistics/rating
  Future<RatingStatistics> getStoreRatingStatistics(String storeId) async {
    final statsDoc = await _firestore
        .collection('markets')
        .doc(storeId)
        .collection('statistics')
        .doc('rating')
        .get();
    
    if (!statsDoc.exists) {
      return RatingStatistics(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    return RatingStatistics.fromMap(statsDoc.data());
  }

  /// التحقق من وجود تقييم سابق للطلب
  Future<bool> hasOrderBeenRated(String userId, String orderId) async {
    final orderDoc = await _firestore
        .collection('orders')
        .doc(orderId)
        .get();

    if (!orderDoc.exists) return false;

    final data = orderDoc.data();
    return data?['storeRating'] != null;
  }

  /// جلب تقييم الطلب (إن وجد)
  Future<StoreRatingInOrder?> getOrderStoreRating(String userId, String orderId) async {
    final orderDoc = await _firestore
        .collection('orders')
        .doc(orderId)
        .get();

    if (!orderDoc.exists) return null;

    final storeRatingData = orderDoc.data()?['storeRating'] as Map<String, dynamic>?;
    if (storeRatingData == null) return null;

    return StoreRatingInOrder.fromMap(storeRatingData);
  }

  /// جلب تقييم الشحن للطلب (للاستخدام في تطبيق الشحن)
  Future<DeliveryRatingModel?> getOrderDeliveryRating(String userId, String orderId) async {
    final orderDoc = await _firestore
        .collection('orders')
        .doc(orderId)
        .get();

    if (!orderDoc.exists) return null;

    final deliveryRatingData = orderDoc.data()?['deliveryRating'] as Map<String, dynamic>?;
    if (deliveryRatingData == null) return null;

    return DeliveryRatingModel.fromMap(deliveryRatingData);
  }

  /// تقييم التاجر للمندوب بعد استلامه الطلب
  /// يُحفظ في:
  /// 1. orders/{orderId} → merchantCourierRating
  /// 2. courier_ratings collection → سجل مركزي مع raterType = 'merchant'
  /// 3. تحديث متوسط rating المندوب في courier_requests/{courierUid}
  Future<void> submitMerchantCourierRating({
    required String orderId,
    required String courierId,
    required String courierName,
    required String marketId,
    required int rating,
    String? comment,
  }) async {
    _logDebug('submitMerchantCourierRating: Starting process for orderId=$orderId, courierId=$courierId');
    final now = Timestamp.now();
    final stopwatch = Stopwatch()..start();

    try {
      // 1 & 2: تحديث الطلب وإضافة السجل المركزي بالتوازي باستخدام Future.wait
      await Future.wait([
        // 1. حفظ في document الطلب
        _firestore.collection('orders').doc(orderId).update({
          'merchantCourierRating': {
            'rating': rating,
            'comment': comment,
            'courierId': courierId,
            'courierName': courierName,
            'marketId': marketId,
            'createdAt': now,
          },
        }),
        // 2. سجل مركزي في courier_ratings
        _firestore.collection('courier_ratings').add({
          'orderId': orderId,
          'courierId': courierId,
          'courierName': courierName,
          'rating': rating,
          'comment': comment,
          'raterType': 'merchant',
          'marketId': marketId,
          'createdAt': now,
        }),
      ]);

      stopwatch.stop();
      _logDebug('submitMerchantCourierRating: Primary writes completed successfully in ${stopwatch.elapsedMilliseconds}ms', type: 'SUCCESS');

      // 3. تحديث متوسط تقييم المندوب في الخلفية
      _logDebug('submitMerchantCourierRating: Dispatching courier average rating update to background', type: 'BACKGROUND');
      _updateCourierRatingAverage(courierId, rating).then((_) {
        _logDebug('submitMerchantCourierRating: Background courier average update completed for courierId=$courierId', type: 'SUCCESS');
      }).catchError((error) {
        _logDebug('submitMerchantCourierRating: Failed to update courier average rating in background', type: 'ERROR', error: error);
      });

    } catch (e) {
      _logDebug('submitMerchantCourierRating: Primary writes failed', type: 'ERROR', error: e);
      rethrow;
    }
  }

  /// تحديث متوسط تقييم المندوب في courier_requests/{courierId}
  Future<void> _updateCourierRatingAverage(String courierId, int newRating) async {
    _logDebug('_updateCourierRatingAverage: Finding courier request doc for courierId=$courierId', type: 'BACKGROUND');
    // البحث عن document المندوب في courier_requests بالـ courierUid
    final query = await _firestore
        .collection('courier_requests')
        .where('courierUid', isEqualTo: courierId)
        .limit(1)
        .get();

    // لو ما فيش نتيجة جرب بـ uid
    final docs = query.docs.isNotEmpty
        ? query.docs
        : (await _firestore
                .collection('courier_requests')
                .where('uid', isEqualTo: courierId)
                .limit(1)
                .get())
            .docs;

    if (docs.isEmpty) {
      _logDebug('_updateCourierRatingAverage: Courier request doc not found for courierId=$courierId', type: 'WARNING');
      return;
    }

    final docRef = docs.first.reference;
    _logDebug('_updateCourierRatingAverage: Found doc. Running transaction for courierId=$courierId', type: 'BACKGROUND');

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final currentRating = (data['rating'] ?? data['rate'] ?? 0.0) is num
          ? (data['rating'] ?? data['rate'] ?? 0.0).toDouble()
          : 0.0;
      final totalRatings = (data['totalRatings'] ?? 0) as int;

      final newTotal = totalRatings + 1;
      final newAverage = ((currentRating * totalRatings) + newRating) / newTotal;

      transaction.update(docRef, {
        'rating': double.parse(newAverage.toStringAsFixed(2)),
        'totalRatings': newTotal,
      });
    });
  }
}

