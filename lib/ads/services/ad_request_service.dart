import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad_request_model.dart';
import '../models/ad_model.dart';
import '../../markets/wallet/services/wallet_service.dart';

class AdRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WalletService _walletService = WalletService();

  Future<Map<String, dynamic>> createAdRequest({
    required File? imageFile,
    required String? storeId,
    required String? storeName,
    required int days,
    required String phoneNumber,
    String ownerType = AdRequestOwnerType.merchant,
    String? craftsmanId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'المستخدم غير مسجل دخول'};
      }

      final double totalPrice = days * 70.0;

      final balance = await _walletService.getWalletBalance(user.uid);
      if (balance < totalPrice) {
        return {
          'success': false,
          'error': 'رصيدك غير كافٍ',
          'insufficientBalance': true,
        };
      }

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadAdImage(imageFile);
        if (imageUrl == null) {
          return {'success': false, 'error': 'فشل رفع الصورة'};
        }
      }

      final deducted = await _walletService.deductFromWallet(
        user.uid,
        totalPrice,
      );
      if (!deducted) {
        if (imageUrl != null) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            print('خطأ في حذف الصورة بعد فشل الخصم: $e');
          }
        }
        return {
          'success': false,
          'error': 'رصيدك غير كافٍ',
          'insufficientBalance': true,
        };
      }

      final adRequest = AdRequestModel(
        id: '',
        imageUrl: imageUrl,
        storeId: storeId,
        storeName: storeName,
        days: days,
        totalPrice: totalPrice,
        phoneNumber: phoneNumber,
        ownerEmail: user.email ?? '',
        ownerUid: user.uid,
        createdAt: DateTime.now(),
        status: 'pending',
        ownerType: ownerType,
        craftsmanId: craftsmanId,
      );

      try {
        await _firestore.collection('ad_requests').add(adRequest.toMap());
        return {'success': true};
      } catch (e) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'walletBalance': FieldValue.increment(totalPrice),
          });
        } catch (refundError) {
          print('خطأ في إعادة المبلغ: $refundError');
        }

        if (imageUrl != null) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (deleteError) {
            print('خطأ في حذف الصورة: $deleteError');
          }
        }

        return {'success': false, 'error': 'فشل حفظ الطلب: ${e.toString()}'};
      }
    } catch (e) {
      print('خطأ في إنشاء طلب الإعلان: $e');
      return {'success': false, 'error': 'فشل إرسال الطلب: ${e.toString()}'};
    }
  }

  Future<String?> _uploadAdImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final fileName =
          'ad_request_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('ad_requests/$fileName');

      final snapshot = await ref.putFile(imageFile);
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  Future<List<AdRequestModel>> fetchUserAdRequests(String ownerUid) async {
    try {
      final snapshot = await _firestore
          .collection('ad_requests')
          .where('ownerUid', isEqualTo: ownerUid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AdRequestModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('خطأ في جلب طلبات الإعلانات: $e');
      return [];
    }
  }

  Future<List<AdModel>> fetchMyAds(String ownerUid) async {
    try {
      final doc = await _firestore
          .collection('app_settings')
          .doc('home_ads')
          .get();

      if (!doc.exists || doc.data()?['ads'] == null) return [];

      final adsData = doc.data()!['ads'];
      if (adsData is! List) return [];

      return adsData
          .map((ad) {
            if (ad is Map<String, dynamic>) {
              return AdModel.fromMap(ad);
            }
            return null;
          })
          .whereType<AdModel>()
          .where((ad) => ad.ownerUid == ownerUid)
          .toList()
        ..sort((a, b) => b.startTime?.compareTo(a.startTime ?? DateTime(1970)) ?? 0);
    } catch (e) {
      print('خطأ في جلب إعلاناتي: $e');
      return [];
    }
  }

  Future<List<AdModel>> fetchMyActiveAds(String ownerUid) async {
    final ads = await fetchMyAds(ownerUid);
    return ads.where((ad) => ad.isValid).toList();
  }

  Future<bool> changeAdImage(int slotId, File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final imageUrl = await _uploadAdImage(imageFile);
      if (imageUrl == null) return false;

      final doc = await _firestore
          .collection('app_settings')
          .doc('home_ads')
          .get();

      if (!doc.exists || doc.data()?['ads'] == null) return false;

      final adsData = doc.data()!['ads'];
      if (adsData is! List) return false;

      final ads = adsData
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final index = ads.indexWhere((a) => a['slotId'] == slotId);
      if (index == -1) return false;

      if (ads[index]['ownerUid'] != user.uid) return false;

      final oldUrl = ads[index]['imageUrl'] as String?;
      ads[index]['imageUrl'] = imageUrl;

      await _firestore.collection('app_settings').doc('home_ads').set({
        'ads': ads,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (oldUrl != null && oldUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(oldUrl).delete();
        } catch (_) {}
      }

      return true;
    } catch (e) {
      print('خطأ في تغيير صورة الإعلان: $e');
      return false;
    }
  }

  Future<bool> deleteUserAd(int slotId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('app_settings')
          .doc('home_ads')
          .get();

      if (!doc.exists || doc.data()?['ads'] == null) return false;

      final adsData = doc.data()!['ads'];
      if (adsData is! List) return false;

      final ads = adsData
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final index = ads.indexWhere((a) => a['slotId'] == slotId);
      if (index == -1) return false;
      if (ads[index]['ownerUid'] != user.uid) return false;

      final imageUrl = ads[index]['imageUrl'] as String?;
      ads.removeAt(index);

      await _firestore.collection('app_settings').doc('home_ads').set({
        'ads': ads,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (_) {}
      }

      return true;
    } catch (e) {
      print('خطأ في حذف الإعلان: $e');
      return false;
    }
  }
}
