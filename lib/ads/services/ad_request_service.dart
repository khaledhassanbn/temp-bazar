import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ad_request_model.dart';
import '../../markets/wallet/services/wallet_service.dart';

class AdRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WalletService _walletService = WalletService();

  // حفظ طلب إعلان جديد
  Future<Map<String, dynamic>> createAdRequest({
    required File? imageFile,
    required String? storeId,
    required String? storeName,
    required int days,
    required String phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'المستخدم غير مسجل دخول'};
      }

      // حساب السعر النهائي
      final double totalPrice = days * 70.0;

      // فحص الرصيد أولاً
      final balance = await _walletService.getWalletBalance(user.uid);
      if (balance < totalPrice) {
        return {
          'success': false,
          'error': 'رصيدك غير كافٍ',
          'insufficientBalance': true,
        };
      }

      // رفع الصورة إذا كانت موجودة
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadAdImage(imageFile);
        if (imageUrl == null) {
          return {'success': false, 'error': 'فشل رفع الصورة'};
        }
      }

      // خصم المبلغ من المحفظة بعد رفع الصورة بنجاح
      final deducted = await _walletService.deductFromWallet(
        user.uid,
        totalPrice,
      );
      if (!deducted) {
        // إذا فشل الخصم، نحاول حذف الصورة المرفوعة
        if (imageUrl != null) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
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

      // إنشاء الطلب
      final adRequest = AdRequestModel(
        id: '', // سيتم تعيينه تلقائياً من Firestore
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
      );

      try {
        // حفظ في Firestore
        await _firestore.collection('ad_requests').add(adRequest.toMap());
        return {'success': true};
      } catch (e) {
        // إذا فشل حفظ الطلب، نعيد المبلغ للمستخدم
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'walletBalance': FieldValue.increment(totalPrice),
          });
        } catch (refundError) {
          print('خطأ في إعادة المبلغ: $refundError');
        }

        // حذف الصورة المرفوعة
        if (imageUrl != null) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
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

  // رفع صورة الإعلان
  Future<String?> _uploadAdImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final String fileName =
          'ad_request_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('ad_requests/$fileName');

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;

      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  // جلب جميع طلبات الإعلانات (للإدمن)
  Future<List<AdRequestModel>> fetchAllAdRequests() async {
    try {
      final snapshot = await _firestore
          .collection('ad_requests')
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

  // جلب طلبات الإعلانات الخاصة بتاجر معين
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

  // تحديث حالة الطلب (للإدمن)
  Future<bool> updateRequestStatus(
    String requestId,
    String status, {
    String? adminNotes,
  }) async {
    try {
      await _firestore.collection('ad_requests').doc(requestId).update({
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث حالة الطلب: $e');
      return false;
    }
  }

  // حذف طلب إعلان
  Future<bool> deleteAdRequest(String requestId) async {
    try {
      // جلب الطلب أولاً لحذف الصورة
      final doc = await _firestore
          .collection('ad_requests')
          .doc(requestId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['imageUrl'] != null) {
          try {
            final ref = _storage.refFromURL(data['imageUrl']);
            await ref.delete();
          } catch (e) {
            print('خطأ في حذف الصورة: $e');
          }
        }
      }

      // حذف الطلب
      await _firestore.collection('ad_requests').doc(requestId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف طلب الإعلان: $e');
      return false;
    }
  }
}
