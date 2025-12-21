// lib/markets/pages/create_store/services/store_service.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/store_model.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// ينشئ مستندًا جديدًا في collection 'markets' ويرفع الصور داخل مجلد
  /// markets/{docId}/logo و markets/{docId}/cover
  Future<String> createStoreDocument(
    Map<String, dynamic> data, {
    File? logo,
    File? cover,
  }) async {
    // استخدام رابط المتجر كـ document ID
    final String storeLink = data['link'] as String;
    final String docId = storeLink; // استخدام الـ link مباشرة كـ document ID
    final docRef = _firestore.collection('markets').doc(docId);

    String? logoUrl;
    String? coverUrl;

    if (logo != null) {
      logoUrl = await _uploadFile(logo, 'markets/$docId/logo');
    }
    if (cover != null) {
      coverUrl = await _uploadFile(cover, 'markets/$docId/cover');
    }

    final payload = Map<String, dynamic>.from(data);
    if (logoUrl != null) payload['logoUrl'] = logoUrl;
    if (coverUrl != null) payload['coverUrl'] = coverUrl;

    // تهيئة عدد المنتجات الإجمالي
    payload['totalProducts'] = 0;

    await docRef.set(payload);

    // Initialize default subcollections under markets/{docId}
    try {
      // Create 'products' subcollection with two initial category docs
      // Use document IDs equal to the category name
      final int maxProducts = (payload['numberOfProducts'] as int?) ?? 0;

      // 1) Default category (renamed to "الأكثر مبيعاً") with order 1
      const String defaultCategoryName = 'الأكثر مبيعاً';
      await docRef.collection('products').doc(defaultCategoryName).set({
        'name': defaultCategoryName,
        'order': 1,
        'numberOfProducts': 0,
        'maximumNumberOfProducts': 6,
      }, SetOptions(merge: true));

      // 2) Offers category named "العروض" with order 2
      const String offersCategoryName = 'العروض';
      await docRef.collection('products').doc(offersCategoryName).set({
        'name': offersCategoryName,
        'order': 2,
        'numberOfProducts': 0,
        'maximumNumberOfProducts': maxProducts,
      }, SetOptions(merge: true));
    } catch (e) {
      // Do not fail store creation if seeding categories fails
      // You can log this error or handle it as needed
      // print('Failed to seed default categories: $e');
    }

    return docId;
  }

  Future<String> _uploadFile(File file, String path) async {
    final String id = Uuid().v4();
    final ref = _storage.ref().child('$path-$id');
    final taskSnapshot = await ref.putFile(file);
    final downloadUrl = await taskSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // استدعاء مستند متجر
  Future<DocumentSnapshot<Map<String, dynamic>>> getStore(String id) async {
    return _firestore.collection('markets').doc(id).get();
  }

  // التحقق من وجود رابط المتجر
  Future<bool> isStoreLinkExists(String link) async {
    try {
      // التحقق من وجود document بالـ ID المحدد
      final docSnapshot = await _firestore
          .collection('markets')
          .doc(link)
          .get();

      return docSnapshot.exists;
    } catch (e) {
      print('خطأ في التحقق من رابط المتجر: $e');
      return false;
    }
  }

  // جلب كل المتاجر المرتبطة ببريد إلكتروني محدد
  Future<List<StoreModel>> getStoresByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('markets')
          .where('email', isEqualTo: email)
          .get();

      return query.docs
          .map((doc) => StoreModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('خطأ أثناء جلب المتاجر للمستخدم $email: $e');
      return [];
    }
  }

  /// يحدث مستند المتجر في collection 'markets'
  Future<void> updateStoreDocument(
    String storeId,
    Map<String, dynamic> data, {
    File? logo,
    File? cover,
  }) async {
    final docRef = _firestore.collection('markets').doc(storeId);

    String? logoUrl;
    String? coverUrl;

    if (logo != null) {
      logoUrl = await _uploadFile(logo, 'markets/$storeId/logo');
    }
    if (cover != null) {
      coverUrl = await _uploadFile(cover, 'markets/$storeId/cover');
    }

    final payload = Map<String, dynamic>.from(data);
    if (logoUrl != null) payload['logoUrl'] = logoUrl;
    if (coverUrl != null) payload['coverUrl'] = coverUrl;

    await docRef.update(payload);
  }

  /// البحث عن مستخدم بالبريد الإلكتروني في collection 'users'
  Future<DocumentSnapshot<Map<String, dynamic>>?> findUserByEmail(
    String email,
  ) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return query.docs.first;
    } catch (e) {
      print('خطأ في البحث عن المستخدم بالبريد الإلكتروني: $e');
      return null;
    }
  }

  // ممكن إضافة دوال تحديث / حذف لاحقًا
}
