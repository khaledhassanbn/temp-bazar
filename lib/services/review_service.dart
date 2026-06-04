import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/models/review_model.dart';

/// خدمة التعامل مع التقييمات
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final now = DateTime.now();
    final storeRating = StoreRatingInOrder(
      rating: rating,
      comment: comment,
      tags: tags,
      createdAt: now,
    );

    // 1. حفظ في document الطلب (في مسار المجموعه الموحده)
    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({
      'storeRating': storeRating.toMap(),
    });

    // 2. حفظ في markets/{storeId}/reviews collection
    final reviewRef = _firestore
        .collection('markets')
        .doc(storeId)
        .collection('reviews')
        .doc();
    
    await reviewRef.set({
      'orderId': orderId,
      'userId': user.uid,
      'userName': user.displayName ?? 'مستخدم',
      'userPhoto': user.photoURL,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(now),
    });

    // 3. تحديث إحصائيات المتجر في markets/{storeId}/statistics
    await _updateStoreRatingStatistics(storeId, rating);
  }

  /// إضافة تقييم لشركة الشحن
  /// يتم حفظه فقط في users/{userId}/orders/{orderId}/deliveryRating
  Future<void> submitDeliveryRating({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    final orderData = orderDoc.data() ?? <String, dynamic>{};

    final deliveryRequest =
        (orderData['deliveryRequest'] is Map<String, dynamic>)
            ? orderData['deliveryRequest'] as Map<String, dynamic>
            : (orderData['deliveryRequest'] is Map
                ? Map<String, dynamic>.from(orderData['deliveryRequest'] as Map)
                : <String, dynamic>{});
    final courierId = (orderData['assignedCourierId'] ??
            deliveryRequest['courierId'] ??
            deliveryRequest['driverId'] ??
            deliveryRequest['assignedDriverId'] ??
            '')
        .toString();
    final courierName = (deliveryRequest['assignedDriverName'] ??
            deliveryRequest['driverName'] ??
            orderData['assignedDriverName'] ??
            '')
        .toString();

    final deliveryRating = DeliveryRatingModel(
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({
      'deliveryRating': {
        ...deliveryRating.toMap(),
        'courierId': courierId,
        'courierName': courierName,
        'ratedByUserId': user.uid,
      },
    });

    // سجل مركزي لتطبيق المناديب: query مباشر بـ courierId
    if (courierId.isNotEmpty) {
      await _firestore.collection('courier_ratings').add({
        'orderId': orderId,
        'courierId': courierId,
        'courierName': courierName,
        'rating': rating,
        'comment': comment,
        'raterType': 'customer',
        'userId': user.uid,
        'userName': user.displayName ?? 'مستخدم',
        'createdAt': Timestamp.now(),
      });

      // تحديث متوسط تقييم المندوب الموحد في courier_requests
      await _updateCourierRatingAverage(courierId, rating);
    }
  }

  /// تحديث إحصائيات تقييم المتجر
  Future<void> _updateStoreRatingStatistics(String storeId, int newRating) async {
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
    final now = Timestamp.now();

    // 1. حفظ في document الطلب
    await _firestore.collection('orders').doc(orderId).update({
      'merchantCourierRating': {
        'rating': rating,
        'comment': comment,
        'courierId': courierId,
        'courierName': courierName,
        'marketId': marketId,
        'createdAt': now,
      },
    });

    // 2. سجل مركزي في courier_ratings
    await _firestore.collection('courier_ratings').add({
      'orderId': orderId,
      'courierId': courierId,
      'courierName': courierName,
      'rating': rating,
      'comment': comment,
      'raterType': 'merchant',
      'marketId': marketId,
      'createdAt': now,
    });

    // 3. تحديث متوسط تقييم المندوب في courier_requests
    await _updateCourierRatingAverage(courierId, rating);
  }

  /// تحديث متوسط تقييم المندوب في courier_requests/{courierId}
  Future<void> _updateCourierRatingAverage(String courierId, int newRating) async {
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

    if (docs.isEmpty) return;

    final docRef = docs.first.reference;

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
