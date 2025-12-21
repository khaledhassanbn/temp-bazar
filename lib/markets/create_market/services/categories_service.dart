import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final int order;
  final List<SubCategory> subcategories;

  Category({
    required this.id,
    required this.name,
    required this.order,
    required this.subcategories,
  });

  factory Category.fromMap(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      // Use Arabic name as the display name
      name: data['name_ar'] ?? data['name'] ?? '',
      order: data['order'] ?? 0,
      subcategories: [], // سيتم تحميلها منفصلاً
    );
  }
}

class SubCategory {
  final String id;
  final String name;
  final int order;

  SubCategory({required this.id, required this.name, required this.order});

  factory SubCategory.fromMap(Map<String, dynamic> data, String id) {
    return SubCategory(
      id: id,
      // Use Arabic name as the display name
      name: data['name_ar'] ?? data['name'] ?? '',
      order: data['order'] ?? 0,
    );
  }
}

class CategoriesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'Categories';

  // جلب جميع الفئات
  static Future<List<Category>> getAllCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('order')
          .get();

      List<Category> categories = [];

      for (var doc in snapshot.docs) {
        final category = Category.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // جلب التصنيفات الفرعية
        final subCategoriesSnapshot = await doc.reference
            .collection('subCategories')
            .orderBy('order')
            .get();

        final subCategories = subCategoriesSnapshot.docs
            .map((subDoc) => SubCategory.fromMap(subDoc.data(), subDoc.id))
            .toList();

        categories.add(
          Category(
            id: category.id,
            name: category.name,
            order: category.order,
            subcategories: subCategories,
          ),
        );
      }

      return categories;
    } catch (e) {
      print('خطأ في جلب الفئات: $e');
      return [];
    }
  }

  // جلب فئة واحدة مع تصنيفاتها الفرعية
  static Future<Category?> getCategoryById(String categoryId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_collectionName)
          .doc(categoryId)
          .get();

      if (doc.exists) {
        final category = Category.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // جلب التصنيفات الفرعية
        final subCategoriesSnapshot = await doc.reference
            .collection('subCategories')
            .orderBy('order')
            .get();

        final subCategories = subCategoriesSnapshot.docs
            .map((subDoc) => SubCategory.fromMap(subDoc.data(), subDoc.id))
            .toList();

        return Category(
          id: category.id,
          name: category.name,
          order: category.order,
          subcategories: subCategories,
        );
      }
      return null;
    } catch (e) {
      print('خطأ في جلب الفئة: $e');
      return null;
    }
  }

  // إضافة رابط المتجر إلى الفئة الرئيسية مع ترتيب تلقائي
  static Future<void> addStoreToCategory(
    String categoryId,
    String storeLink,
  ) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(categoryId);
      final storesCollection = docRef.collection('stores');

      // الحصول على آخر ترتيب موجود
      final lastOrderSnapshot = await storesCollection
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      int nextOrder = 1;
      if (lastOrderSnapshot.docs.isNotEmpty) {
        final lastOrder =
            lastOrderSnapshot.docs.first.data()['order'] as int? ?? 0;
        nextOrder = lastOrder + 1;
      }

      // إضافة المتجر مع الترتيب الجديد
      await storesCollection.doc(storeLink).set({
        'order': nextOrder,
      }, SetOptions(merge: true));
    } catch (e) {
      print('خطأ في إضافة المتجر للفئة الرئيسية: $e');
      rethrow;
    }
  }

  // إضافة رابط المتجر إلى التصنيف الفرعي مع ترتيب تلقائي
  static Future<void> addStoreToSubCategory(
    String categoryId,
    String subCategoryName,
    String storeLink,
  ) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(categoryId);
      final subCategoryDoc = docRef
          .collection('subCategories')
          .doc(subCategoryName);
      final storesCollection = subCategoryDoc.collection('stores');

      // الحصول على آخر ترتيب موجود في التصنيف الفرعي
      final lastOrderSnapshot = await storesCollection
          .orderBy('order', descending: true)
          .limit(1)
          .get();

      int nextOrder = 1;
      if (lastOrderSnapshot.docs.isNotEmpty) {
        final lastOrder =
            lastOrderSnapshot.docs.first.data()['order'] as int? ?? 0;
        nextOrder = lastOrder + 1;
      }

      // إضافة المتجر مع الترتيب الجديد
      await storesCollection.doc(storeLink).set({
        'order': nextOrder,
      }, SetOptions(merge: true));
    } catch (e) {
      print('خطأ في إضافة المتجر للتصنيف الفرعي: $e');
      rethrow;
    }
  }

  // إضافة رابط المتجر داخل مصفوفة stores وزيادة العداد storesCount في الفئة الرئيسية
  static Future<void> pushStoreLinkToCategoryAndIncrement(
    String categoryId,
    String storeLink,
  ) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc(categoryId);
      await docRef.set({
        'stores': FieldValue.arrayUnion([storeLink]),
        'storesCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      print('خطأ في تحديث stores/storesCount للفئة: $e');
      rethrow;
    }
  }

  // إضافة رابط المتجر داخل مصفوفة stores وزيادة العداد storesCount في التصنيف الفرعي
  static Future<void> pushStoreLinkToSubCategoryAndIncrement(
    String categoryId,
    String subCategoryId,
    String storeLink,
  ) async {
    try {
      final subDocRef = _firestore
          .collection(_collectionName)
          .doc(categoryId)
          .collection('subCategories')
          .doc(subCategoryId);
      await subDocRef.set({
        'stores': FieldValue.arrayUnion([storeLink]),
        'storesCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      print('خطأ في تحديث stores/storesCount للتصنيف الفرعي: $e');
      rethrow;
    }
  }
}
