import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CraftsmanReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitReview({
    required String craftsmanId,
    required int rating,
    String? comment,
    String? contactEventId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول');
    if (rating < 1 || rating > 5) throw Exception('التقييم غير صالح');

    final now = DateTime.now();
    await _firestore
        .collection('craftsmen')
        .doc(craftsmanId)
        .collection('reviews')
        .add({
      'userId': user.uid,
      'userName': user.displayName ?? 'مستخدم',
      'userPhoto': user.photoURL,
      'rating': rating,
      'comment': comment,
      'contactEventId': contactEventId,
      'createdAt': Timestamp.fromDate(now),
    });

    await _updateRatingStats(craftsmanId, rating);
  }

  Future<void> submitFollowUp({
    required String contactEventId,
    required String craftsmanId,
    required bool responded,
    required bool serviceCompleted,
  }) async {
    await _firestore
        .collection('craftsmen')
        .doc(craftsmanId)
        .collection('contact_events')
        .doc(contactEventId)
        .update({
      'responded': responded,
      'serviceCompleted': serviceCompleted,
    });

    await _recalculateResponseRate(craftsmanId);

    if (serviceCompleted) {
      await _firestore.collection('craftsmen').doc(craftsmanId).update({
        'completedJobsCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> _recalculateResponseRate(String craftsmanId) async {
    final events = await _firestore
        .collection('craftsmen')
        .doc(craftsmanId)
        .collection('contact_events')
        .where('responded', isNotEqualTo: null)
        .get();

    if (events.docs.isEmpty) return;

    var responded = 0;
    for (final d in events.docs) {
      if (d.data()['responded'] == true) responded++;
    }
    final rate = responded / events.docs.length;

    await _firestore.collection('craftsmen').doc(craftsmanId).update({
      'responseRate': rate,
      if (rate >= 0.8 && responded >= 5)
        'badges': FieldValue.arrayUnion(['fast_response']),
    });
  }

  Future<void> _updateRatingStats(String craftsmanId, int newRating) async {
    final ref = _firestore.collection('craftsmen').doc(craftsmanId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final oldAvg = (data['averageRating'] is num)
        ? (data['averageRating'] as num).toDouble()
        : 0.0;
    final oldCount = (data['totalReviews'] ?? 0) as int;
    final newCount = oldCount + 1;
    final newAvg = ((oldAvg * oldCount) + newRating) / newCount;

    final updates = <String, dynamic>{
      'averageRating': newAvg,
      'totalReviews': newCount,
    };

    if (newCount >= 100 && newAvg >= 4.9) {
      updates['badges'] = FieldValue.arrayUnion(['recommended']);
    }

    await ref.update(updates);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> reviewsStream(String craftsmanId) {
    return _firestore
        .collection('craftsmen')
        .doc(craftsmanId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }
}
