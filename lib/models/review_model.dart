import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج تقييم المتجر
class ReviewModel {
  final String id;
  final String storeId;
  final String orderId;
  final String userId;
  final String userName;
  final String? userPhoto;
  final int rating;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.storeId,
    required this.orderId,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    this.comment,
    required this.tags,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      storeId: map['storeId'] ?? '',
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'],
      rating: map['rating'] ?? 0,
      comment: map['comment'],
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// نموذج إحصائيات التقييم للمتجر
class RatingStatistics {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  RatingStatistics({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory RatingStatistics.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return RatingStatistics(
        averageRating: 0.0,
        totalReviews: 0,
        ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    final distribution = <int, int>{};
    final distMap = map['ratingDistribution'] as Map<String, dynamic>? ?? {};
    for (int i = 1; i <= 5; i++) {
      distribution[i] = distMap['$i'] ?? distMap[i.toString()] ?? 0;
    }

    return RatingStatistics(
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      ratingDistribution: distribution,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  /// حساب النسبة المئوية لكل نجمة
  double getPercentage(int stars) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[stars] ?? 0) / totalReviews * 100;
  }
}

/// نموذج تقييم شركة الشحن (يُحفظ في نفس document الطلب)
class DeliveryRatingModel {
  final int rating;
  final String? comment;
  final DateTime createdAt;

  DeliveryRatingModel({
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory DeliveryRatingModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return DeliveryRatingModel(
        rating: 0,
        comment: null,
        createdAt: DateTime.now(),
      );
    }
    return DeliveryRatingModel(
      rating: map['rating'] ?? 0,
      comment: map['comment'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// نموذج تقييم المتجر المحفوظ في الطلب
class StoreRatingInOrder {
  final int rating;
  final String? comment;
  final List<String> tags;
  final DateTime createdAt;

  StoreRatingInOrder({
    required this.rating,
    this.comment,
    required this.tags,
    required this.createdAt,
  });

  factory StoreRatingInOrder.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return StoreRatingInOrder(
        rating: 0,
        comment: null,
        tags: [],
        createdAt: DateTime.now(),
      );
    }
    return StoreRatingInOrder(
      rating: map['rating'] ?? 0,
      comment: map['comment'],
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
