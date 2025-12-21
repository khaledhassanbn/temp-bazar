import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/saved_location_model.dart';

/// سيرفس للتعامل مع العناوين المحفوظة في Firestore
class SavedLocationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// الحصول على reference لـ collection العناوين
  CollectionReference<Map<String, dynamic>> _locationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_locations');
  }

  /// جلب كل العناوين المحفوظة للمستخدم الحالي
  Future<List<SavedLocation>> getSavedLocations() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _locationsRef(user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SavedLocation.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('خطأ في جلب العناوين: $e');
      return [];
    }
  }

  /// Stream للاستماع لتغييرات العناوين
  Stream<List<SavedLocation>> savedLocationsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _locationsRef(user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavedLocation.fromFirestore(doc))
            .toList());
  }

  /// إضافة عنوان جديد
  Future<SavedLocation?> addLocation({
    required String name,
    required String address,
    required GeoPoint location,
    bool setAsDefault = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // إذا كان العنوان الجديد هو الافتراضي، نلغي الافتراضي من الباقي
      if (setAsDefault) {
        await _clearDefaultLocations(user.uid);
      }

      // إذا لم يكن هناك عناوين، يصبح هذا الافتراضي تلقائيًا
      final existingLocations = await getSavedLocations();
      final isFirstLocation = existingLocations.isEmpty;

      final docRef = await _locationsRef(user.uid).add({
        'name': name,
        'address': address,
        'location': location,
        'isDefault': setAsDefault || isFirstLocation,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // تحديث حالة إعداد الموقع
      await markLocationSetupComplete();

      return SavedLocation(
        id: docRef.id,
        name: name,
        address: address,
        location: location,
        isDefault: setAsDefault || isFirstLocation,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('خطأ في إضافة العنوان: $e');
      return null;
    }
  }

  /// تعديل عنوان موجود
  Future<bool> updateLocation(SavedLocation location) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _locationsRef(user.uid).doc(location.id).update({
        'name': location.name,
        'address': location.address,
        'location': location.location,
        'isDefault': location.isDefault,
      });
      return true;
    } catch (e) {
      debugPrint('خطأ في تعديل العنوان: $e');
      return false;
    }
  }

  /// حذف عنوان
  Future<bool> deleteLocation(String locationId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _locationsRef(user.uid).doc(locationId).delete();
      return true;
    } catch (e) {
      debugPrint('خطأ في حذف العنوان: $e');
      return false;
    }
  }

  /// تعيين عنوان كافتراضي
  Future<bool> setDefaultLocation(String locationId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // إلغاء الافتراضي من كل العناوين
      await _clearDefaultLocations(user.uid);

      // تعيين العنوان الجديد كافتراضي
      await _locationsRef(user.uid).doc(locationId).update({
        'isDefault': true,
      });

      return true;
    } catch (e) {
      debugPrint('خطأ في تعيين العنوان الافتراضي: $e');
      return false;
    }
  }

  /// الحصول على العنوان الافتراضي
  Future<SavedLocation?> getDefaultLocation() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _locationsRef(user.uid)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // إذا لم يكن هناك افتراضي، نرجع أول عنوان
        final allLocations = await getSavedLocations();
        return allLocations.isNotEmpty ? allLocations.first : null;
      }

      return SavedLocation.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('خطأ في جلب العنوان الافتراضي: $e');
      return null;
    }
  }

  /// التحقق من إعداد الموقع لأول مرة
  Future<bool> hasSetupLocation() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      return doc.data()?['hasSetupLocation'] ?? false;
    } catch (e) {
      debugPrint('خطأ في التحقق من إعداد الموقع: $e');
      return false;
    }
  }

  /// تعليم اكتمال إعداد الموقع
  Future<void> markLocationSetupComplete() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'hasSetupLocation': true,
      });
    } catch (e) {
      debugPrint('خطأ في تحديث حالة إعداد الموقع: $e');
    }
  }

  /// إلغاء الافتراضي من كل العناوين
  Future<void> _clearDefaultLocations(String userId) async {
    final snapshot = await _locationsRef(userId)
        .where('isDefault', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'isDefault': false});
    }
  }
}
