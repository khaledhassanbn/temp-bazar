import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product_models.dart';

class ProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static CollectionReference _productsCol(String marketId) =>
      _firestore.collection('markets').doc(marketId).collection('products');

  static CollectionReference _productsInCategoryCol(
    String marketId,
    String categoryId,
  ) => _productsCol(marketId).doc(categoryId).collection('items');

  // Categories - قراءة الفئات من subcollection products
  static Future<List<ProductCategoryModel>> getCategories(
    String marketId,
  ) async {
    try {
      final snap = await _productsCol(marketId).orderBy('order').get();

      // إذا لم تكن هناك فئات، أنشئ الفئات الافتراضية
      if (snap.docs.isEmpty) {
        await _createDefaultCategories(marketId);
        // جلب الفئات مرة أخرى بعد إنشائها
        final newSnap = await _productsCol(marketId).orderBy('order').get();
        return newSnap.docs.map(ProductCategoryModel.fromDoc).toList();
      }

      return snap.docs.map(ProductCategoryModel.fromDoc).toList();
    } catch (e) {
      print('خطأ في جلب الفئات: $e');
      return [];
    }
  }

  // إنشاء الفئات الافتراضية
  static Future<void> _createDefaultCategories(String marketId) async {
    try {
      // فئة "الأكثر مبيعاً"
      await _productsCol(
        marketId,
      ).doc('الأكثر مبيعاً').set({'name': 'الأكثر مبيعاً', 'order': 1});

      // فئة "العروض"
      await _productsCol(
        marketId,
      ).doc('العروض').set({'name': 'العروض', 'order': 2});
    } catch (e) {
      print('خطأ في إنشاء الفئات الافتراضية: $e');
    }
  }

  static Future<String> addCategory(
    String marketId, {
    required String name,
  }) async {
    try {
      // compute next order
      final last = await _productsCol(
        marketId,
      ).orderBy('order', descending: true).limit(1).get();
      final nextOrder = last.docs.isNotEmpty
          ? ((last.docs.first.data() as Map)['order'] ?? 0) + 1
          : 1;

      final ref = await _productsCol(
        marketId,
      ).add({'name': name, 'order': nextOrder});
      return ref.id;
    } catch (e) {
      print('خطأ في إضافة الفئة: $e');
      rethrow;
    }
  }

  // Products - إضافة منتج مع جميع الحقول الجديدة
  static Future<String> addProduct(
    String marketId,
    String categoryId, {
    required String name,
    required num price,
    required int stock,
    String? description,
    File? imageFile,
    bool hasStockLimit = false,
    bool hasDiscount = false,
    num? discountValue,
    num? finalPrice,
    List<ProductOptionModel> requiredOptions = const [],
    List<ProductOptionModel> extraOptions = const [],
    DateTime? endAt,
    bool status = true,
    bool inStock = true,
    int? order,
  }) async {
    try {
      // استخدم اسم المنتج كـ ID بعد تنظيفه
      final String productId = _sanitizeDocId(name);
      // أنشئ معرفًا عامًا عشوائيًا للمنتج لفتحه عبر روابط/مشاركة
      final String publicId = _generatePublicId();
      String? imageUrl;
      if (imageFile != null) {
        final ref = _storage.ref().child(
          'markets/$marketId/products/$categoryId/items/$productId/${DateTime.now().millisecondsSinceEpoch}',
        );
        final task = await ref.putFile(imageFile);
        imageUrl = await task.ref.getDownloadURL();
      }

      // حساب السعر النهائي إذا كان هناك خصم
      num calculatedFinalPrice = price;
      if (hasDiscount && discountValue != null) {
        calculatedFinalPrice = price - discountValue;
      }
      if (calculatedFinalPrice < 1) calculatedFinalPrice = 1;

      int computedOrder = 1;
      if (order != null) {
        computedOrder = order;
      } else {
        final last = await _productsInCategoryCol(
          marketId,
          categoryId,
        ).orderBy('order', descending: true).limit(1).get();
        computedOrder = last.docs.isNotEmpty
            ? ((last.docs.first.data() as Map)['order'] ?? 0) + 1
            : 1;
      }

      await _productsInCategoryCol(marketId, categoryId).doc(productId).set({
        'name': name,
        'price': price,
        'image': imageUrl,
        'description': description,
        'publicId': publicId,
        'stock': stock,
        'hasStockLimit': hasStockLimit,
        'hasDiscount': hasDiscount,
        'discountValue': discountValue,
        'finalPrice': calculatedFinalPrice,
        'requiredOptions': requiredOptions.map((e) => e.toMap()).toList(),
        'extraOptions': extraOptions.map((e) => e.toMap()).toList(),
        'endAt': endAt,
        'status': status,
        'inStock': inStock,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'order': computedOrder,
      }, SetOptions(merge: true));

      // زيادة عدد المنتجات في الفئة +1
      await _productsCol(marketId).doc(categoryId).set({
        'numberOfProducts': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // زيادة عدد المنتجات الإجمالي في المتجر
      await _firestore.collection('markets').doc(marketId).set({
        'totalProducts': FieldValue.increment(1),
      }, SetOptions(merge: true));

      return productId;
    } catch (e) {
      print('خطأ في إضافة المنتج: $e');
      rethrow;
    }
  }

  // جلب منتج عبر publicId داخل فئة معينة
  static Future<ProductModel?> getProductByPublicId(
    String marketId,
    String categoryId,
    String publicId,
  ) async {
    final snap = await _productsInCategoryCol(
      marketId,
      categoryId,
    ).where('publicId', isEqualTo: publicId).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return ProductModel.fromDoc(snap.docs.first);
    }
    return null;
  }

  // جلب منتج عبر publicId دون معرفة الفئة (يفحص جميع الفئات)
  static Future<ProductModel?> findProductByPublicId(
    String marketId,
    String publicId,
  ) async {
    final categories = await getCategories(marketId);
    for (final category in categories) {
      final found = await getProductByPublicId(marketId, category.id, publicId);
      if (found != null) return found;
    }
    return null;
  }

  // تحديث منتج موجود
  static Future<void> updateProduct(
    String marketId,
    String categoryId,
    String productId, {
    String? name,
    num? price,
    int? stock,
    String? description,
    File? imageFile,
    bool? hasStockLimit,
    bool? hasDiscount,
    num? discountValue,
    List<ProductOptionModel>? requiredOptions,
    List<ProductOptionModel>? extraOptions,
    DateTime? endAt,
    bool? status,
    bool? inStock,
  }) async {
    final Map<String, dynamic> updateData = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updateData['name'] = name;
    if (price != null) updateData['price'] = price;
    if (stock != null) updateData['stock'] = stock;
    if (description != null) updateData['description'] = description;
    if (hasStockLimit != null) updateData['hasStockLimit'] = hasStockLimit;
    if (hasDiscount != null) updateData['hasDiscount'] = hasDiscount;
    if (discountValue != null) updateData['discountValue'] = discountValue;
    if (requiredOptions != null)
      updateData['requiredOptions'] = requiredOptions
          .map((e) => e.toMap())
          .toList();
    if (extraOptions != null)
      updateData['extraOptions'] = extraOptions.map((e) => e.toMap()).toList();
    if (endAt != null) updateData['endAt'] = endAt;
    if (status != null) updateData['status'] = status;
    if (inStock != null) updateData['inStock'] = inStock;

    // رفع صورة جديدة إذا تم توفيرها
    if (imageFile != null) {
      final ref = _storage.ref().child(
        'markets/$marketId/products/$categoryId/items/$productId/${DateTime.now().millisecondsSinceEpoch}',
      );
      final task = await ref.putFile(imageFile);
      final imageUrl = await task.ref.getDownloadURL();
      updateData['image'] = imageUrl;
    }

    // حساب السعر النهائي إذا كان هناك خصم
    if (hasDiscount == true && discountValue != null && price != null) {
      final fp = price - discountValue;
      updateData['finalPrice'] = fp < 1 ? 1 : fp;
    } else if (hasDiscount == false) {
      final p = price ?? 0;
      updateData['finalPrice'] = p < 1 ? 1 : p;
    }

    await _productsInCategoryCol(
      marketId,
      categoryId,
    ).doc(productId).update(updateData);
  }

  static Future<ProductModel> moveProduct({
    required String marketId,
    required String fromCategoryId,
    required String toCategoryId,
    required ProductModel updatedProduct,
    File? imageFile,
  }) async {
    if (fromCategoryId == toCategoryId) {
      throw 'الفئة الجديدة مطابقة للفئة الحالية';
    }

    try {
      final oldRef = _productsInCategoryCol(
        marketId,
        fromCategoryId,
      ).doc(updatedProduct.id);
      final oldSnapshot = await oldRef.get();

      if (!oldSnapshot.exists) {
        throw 'المنتج غير موجود في الفئة الحالية';
      }

      final oldData = oldSnapshot.data() as Map<String, dynamic>;
      String? imageUrl = updatedProduct.image ?? oldData['image'] as String?;
      final String? publicId = oldData['publicId'] as String?;
      final createdAt = oldData['createdAt'];

      if (imageFile != null) {
        final ref = _storage.ref().child(
          'markets/$marketId/products/$toCategoryId/items/${updatedProduct.id}/${DateTime.now().millisecondsSinceEpoch}',
        );
        final task = await ref.putFile(imageFile);
        imageUrl = await task.ref.getDownloadURL();
      }

      final orderSnap = await _productsInCategoryCol(
        marketId,
        toCategoryId,
      ).orderBy('order', descending: true).limit(1).get();
      final newOrder = orderSnap.docs.isNotEmpty
          ? (() {
              final data = orderSnap.docs.first.data() as Map<String, dynamic>;
              final orderValue = data['order'];
              if (orderValue is num) {
                return orderValue.toInt() + 1;
              }
              return 1;
            })()
          : 1;

      final sanitizedDiscount = updatedProduct.hasDiscount
          ? (updatedProduct.discountValue ?? 0)
          : 0;
      final sanitizedStock = updatedProduct.hasStockLimit
          ? updatedProduct.stock
          : 0;
      final computedFinalPrice = updatedProduct.hasDiscount
          ? updatedProduct.price - sanitizedDiscount
          : updatedProduct.price;
      final safeFinalPrice = computedFinalPrice < 1 ? 1 : computedFinalPrice;

      final newRef = _productsInCategoryCol(
        marketId,
        toCategoryId,
      ).doc(updatedProduct.id);

      final batch = _firestore.batch();

      batch.set(newRef, {
        'name': updatedProduct.name,
        'price': updatedProduct.price,
        'image': imageUrl,
        'description': updatedProduct.description,
        'publicId': publicId ?? updatedProduct.publicId,
        'stock': sanitizedStock,
        'hasStockLimit': updatedProduct.hasStockLimit,
        'hasDiscount': updatedProduct.hasDiscount,
        'discountValue': sanitizedDiscount,
        'finalPrice': safeFinalPrice,
        'requiredOptions': updatedProduct.requiredOptions
            .map((e) => e.toMap())
            .toList(),
        'extraOptions': updatedProduct.extraOptions
            .map((e) => e.toMap())
            .toList(),
        'endAt': updatedProduct.endAt,
        'status': updatedProduct.status,
        'inStock': updatedProduct.inStock,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'order': newOrder,
      });

      batch.delete(oldRef);

      batch.set(_productsCol(marketId).doc(fromCategoryId), {
        'numberOfProducts': FieldValue.increment(-1),
      }, SetOptions(merge: true));
      batch.set(_productsCol(marketId).doc(toCategoryId), {
        'numberOfProducts': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();

      final refreshed = await getProduct(
        marketId,
        toCategoryId,
        updatedProduct.id,
      );

      return refreshed ??
          updatedProduct.copyWith(
            image: imageUrl,
            publicId: publicId ?? updatedProduct.publicId,
            order: newOrder,
            endAt: updatedProduct.endAt,
          );
    } catch (e) {
      print('خطأ في نقل المنتج: $e');
      rethrow;
    }
  }

  // حذف منتج
  static Future<void> deleteProduct(
    String marketId,
    String categoryId,
    String productId,
  ) async {
    await _productsInCategoryCol(marketId, categoryId).doc(productId).delete();

    // تقليل عدد المنتجات في الفئة -1
    await _productsCol(marketId).doc(categoryId).set({
      'numberOfProducts': FieldValue.increment(-1),
    }, SetOptions(merge: true));

    // تقليل عدد المنتجات الإجمالي في المتجر
    await _firestore.collection('markets').doc(marketId).set({
      'totalProducts': FieldValue.increment(-1),
    }, SetOptions(merge: true));
  }

  // جلب منتج واحد
  static Future<ProductModel?> getProduct(
    String marketId,
    String categoryId,
    String productId,
  ) async {
    final doc = await _productsInCategoryCol(
      marketId,
      categoryId,
    ).doc(productId).get();

    if (doc.exists) {
      return ProductModel.fromDoc(doc);
    }
    return null;
  }

  // جلب جميع المنتجات في فئة معينة
  static Future<List<ProductModel>> getProducts(
    String marketId,
    String categoryId,
  ) async {
    final snap = await _productsInCategoryCol(
      marketId,
      categoryId,
    ).orderBy('order').get();
    return snap.docs.map(ProductModel.fromDoc).toList();
  }

  // إعادة تعيين ترتيب المنتجات لقيم متسلسلة تبدأ من 1
  static Future<void> reorderProducts(
    String marketId,
    String categoryId,
    List<ProductModel> ordered,
  ) async {
    final batch = _firestore.batch();
    for (var i = 0; i < ordered.length; i++) {
      final product = ordered[i];
      final ref = _productsInCategoryCol(marketId, categoryId).doc(product.id);
      batch.update(ref, {
        'order': i + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // جلب جميع المنتجات في متجر معين
  static Future<List<ProductModel>> getAllProductsInMarket(
    String marketId,
  ) async {
    final categories = await getCategories(marketId);
    List<ProductModel> allProducts = [];

    for (final category in categories) {
      final products = await getProducts(marketId, category.id);
      allProducts.addAll(products);
    }

    return allProducts;
  }

  // البحث في المنتجات
  static Future<List<ProductModel>> searchProducts(
    String marketId,
    String searchQuery,
  ) async {
    final allProducts = await getAllProductsInMarket(marketId);
    return allProducts
        .where(
          (product) =>
              product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (product.description?.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  // تحديث مخزون المنتج
  static Future<void> updateProductStock(
    String marketId,
    String categoryId,
    String productId,
    int newStock,
  ) async {
    await _productsInCategoryCol(marketId, categoryId).doc(productId).update({
      'stock': newStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // تحديث حالة توفر المنتج
  static Future<void> updateProductInStock(
    String marketId,
    String categoryId,
    String productId,
    bool inStock,
  ) async {
    await _productsInCategoryCol(marketId, categoryId).doc(productId).update({
      'inStock': inStock,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // تنظيف النص ليصبح صالحًا كمُعرّف مستند في Firestore
  static String _sanitizeDocId(String raw) {
    var s = raw.trim();
    // دمج المسافات المتتالية إلى مسافة واحدة
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    // إزالة الأحرف غير المناسبة لمسارات Firestore
    s = s.replaceAll('/', '');
    s = s.replaceAll('\\', '');
    s = s.replaceAll('#', '');
    s = s.replaceAll('?', '');
    s = s.replaceAll('[', '').replaceAll(']', '');
    // استبدال المسافات بشرطة سفلية
    s = s.replaceAll(' ', '_');
    // إلى أحرف صغيرة لتفادي حساسية الحالة
    return s.toLowerCase();
  }

  // مولد معرف عام قصير عشوائي
  static String _generatePublicId() {
    // 12 حقل من [a-z0-9]
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final millis = DateTime.now().millisecondsSinceEpoch;
    var acc = millis.toRadixString(36);
    while (acc.length < 12) {
      acc += chars[(millis + acc.length * 37) % chars.length];
    }
    return acc.substring(0, 12);
  }

  // إعادة ترتيب الفئات داخل markets/{marketId}/products بحسب الفهرس
  static Future<void> reorderCategories(
    String marketId,
    List<ProductCategoryModel> ordered,
  ) async {
    final batch = _firestore.batch();
    for (var i = 0; i < ordered.length; i++) {
      final category = ordered[i];
      final ref = _productsCol(marketId).doc(category.id);
      batch.update(ref, {'order': i + 1});
    }
    await batch.commit();
  }
}
