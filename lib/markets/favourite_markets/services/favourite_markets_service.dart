import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/favourite_market_model.dart';

/// Service لإدارة المتاجر المفضلة
class FavouriteMarketsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// الحصول على reference لـ collection المتاجر المفضلة
  CollectionReference<Map<String, dynamic>> _favouritesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favourite_markets');
  }

  /// إضافة متجر للمفضلة
  Future<bool> addFavouriteMarket(String marketId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // التحقق من وجود المتجر في المفضلة
      final existing = await _favouritesRef(user.uid)
          .where('marketId', isEqualTo: marketId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return true; // موجود بالفعل
      }

      // إضافة المتجر
      await _favouritesRef(user.uid).add({
        'marketId': marketId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('خطأ في إضافة المتجر للمفضلة: $e');
      return false;
    }
  }

  /// إزالة متجر من المفضلة
  Future<bool> removeFavouriteMarket(String marketId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final query = await _favouritesRef(user.uid)
          .where('marketId', isEqualTo: marketId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;

      await query.docs.first.reference.delete();
      return true;
    } catch (e) {
      print('خطأ في إزالة المتجر من المفضلة: $e');
      return false;
    }
  }

  /// التحقق من وجود متجر في المفضلة
  Future<bool> isFavouriteMarket(String marketId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final query = await _favouritesRef(user.uid)
          .where('marketId', isEqualTo: marketId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('خطأ في التحقق من المتجر المفضل: $e');
      return false;
    }
  }

  /// جلب جميع المتاجر المفضلة
  Future<List<FavouriteMarketModel>> getFavouriteMarkets() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _favouritesRef(user.uid)
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FavouriteMarketModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('خطأ في جلب المتاجر المفضلة: $e');
      return [];
    }
  }

  /// Stream للمتاجر المفضلة
  Stream<List<FavouriteMarketModel>> favouriteMarketsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _favouritesRef(user.uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FavouriteMarketModel.fromFirestore(doc))
            .toList());
  }
}


