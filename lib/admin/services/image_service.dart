import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Delete portfolio image from craftsman account
  Future<void> deletePortfolioImage({
    required String craftsmanId,
    required String imageUrl,
    bool deleteFromStorage = true,
  }) async {
    try {
      // 1. Get craftsman document
      final doc =
          await _firestore.collection('craftsmen').doc(craftsmanId).get();

      if (!doc.exists) {
        throw Exception('الصنايعي غير موجود');
      }

      final data = doc.data()!;
      final portfolioUrls =
          List<String>.from(data['portfolioUrls'] ?? []);

      // 2. Remove image URL from array
      portfolioUrls.remove(imageUrl);

      // 3. Update Firestore document
      await _firestore.collection('craftsmen').doc(craftsmanId).update({
        'portfolioUrls': portfolioUrls,
      }).timeout(Duration(seconds: 30));

      // 4. Optionally delete from Firebase Storage
      if (deleteFromStorage) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image from storage: $e');
          // Don't throw - image is already removed from document
        }
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لحذف الصور');
      } else if (e.toString().contains('not-found')) {
        throw Exception('الصنايعي غير موجود');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ أثناء حذف الصورة');
      }
    }
  }

  /// Delete all portfolio images for a craftsman
  Future<void> deleteAllPortfolioImages({
    required String craftsmanId,
    bool deleteFromStorage = true,
  }) async {
    try {
      // 1. Get craftsman document
      final doc =
          await _firestore.collection('craftsmen').doc(craftsmanId).get();

      if (!doc.exists) {
        throw Exception('الصنايعي غير موجود');
      }

      final data = doc.data()!;
      final portfolioUrls =
          List<String>.from(data['portfolioUrls'] ?? []);

      // 2. Update Firestore document
      await _firestore.collection('craftsmen').doc(craftsmanId).update({
        'portfolioUrls': [],
      }).timeout(Duration(seconds: 30));

      // 3. Optionally delete from Firebase Storage
      if (deleteFromStorage) {
        for (final imageUrl in portfolioUrls) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Error deleting image from storage: $e');
            // Continue with other images
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لحذف الصور');
      } else if (e.toString().contains('not-found')) {
        throw Exception('الصنايعي غير موجود');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ أثناء حذف الصور');
      }
    }
  }

  /// Get portfolio images for a craftsman
  Future<List<String>> getPortfolioImages(String craftsmanId) async {
    try {
      final doc = await _firestore
          .collection('craftsmen')
          .doc(craftsmanId)
          .get()
          .timeout(Duration(seconds: 30));

      if (!doc.exists) {
        throw Exception('الصنايعي غير موجود');
      }

      final data = doc.data()!;
      return List<String>.from(data['portfolioUrls'] ?? []);
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض الصور');
      } else if (e.toString().contains('not-found')) {
        throw Exception('الصنايعي غير موجود');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ أثناء جلب الصور');
      }
    }
  }

  /// Watch portfolio images in real-time
  Stream<List<String>> watchPortfolioImages(String craftsmanId) {
    try {
      return _firestore
          .collection('craftsmen')
          .doc(craftsmanId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return [];
        final data = doc.data()!;
        return List<String>.from(data['portfolioUrls'] ?? []);
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لعرض الصور');
      }
      rethrow;
    }
  }

  /// Delete store image
  Future<void> deleteStoreImage({
    required String storeId,
    required String imageUrl,
    bool deleteFromStorage = true,
  }) async {
    try {
      // 1. Get store document
      final doc = await _firestore.collection('markets').doc(storeId).get();

      if (!doc.exists) {
        throw Exception('المتجر غير موجود');
      }

      final data = doc.data()!;
      final storeImages = List<String>.from(data['storeImages'] ?? []);

      // 2. Remove image URL from array
      storeImages.remove(imageUrl);

      // 3. Update Firestore document
      await _firestore.collection('markets').doc(storeId).update({
        'storeImages': storeImages,
      }).timeout(Duration(seconds: 30));

      // 4. Optionally delete from Firebase Storage
      if (deleteFromStorage) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          print('Error deleting image from storage: $e');
        }
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        throw Exception('ليس لديك صلاحيات لحذف الصور');
      } else if (e.toString().contains('not-found')) {
        throw Exception('المتجر غير موجود');
      } else if (e.toString().contains('timeout')) {
        throw Exception('انتهت مهلة الاتصال، حاول مرة أخرى');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('حدث خطأ أثناء حذف الصورة');
      }
    }
  }
}
