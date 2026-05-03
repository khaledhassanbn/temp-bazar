import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';

class CategoryStoreLinksResult {
  final List<String> mergedStoreIds;
  final Map<String, List<String>> storesBySubCategory;

  CategoryStoreLinksResult({
    required this.mergedStoreIds,
    required this.storesBySubCategory,
  });
}

class CategoryStoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentYear = DateTime.now().year.toString();

  /// جلب كل متاجر الفئة الرئيسية + جميع الفئات الفرعية مجمّعة بدون تكرار
  Future<List<StoreModel>> getAllStoresForCategoryAndSubcategories(
    String categoryId,
  ) async {
    final linksResult = await getCategoryWithSubcategoryStoreLinks(categoryId);
    return getStoresByIds(linksResult.mergedStoreIds);
  }

  Future<CategoryStoreLinksResult> getCategoryWithSubcategoryStoreLinks(
    String categoryId,
  ) async {
    final List<String> orderedMergedIds = [];
    final Set<String> seen = {};
    final Map<String, List<String>> storesBySubCategory = {};

    // 1) روابط الفئة الرئيسية
    final mainLinks = await getStoreLinksForCategory(categoryId);
    for (final id in mainLinks) {
      if (seen.add(id)) orderedMergedIds.add(id);
    }

    // 2) روابط الفئات الفرعية بالتوازي
    try {
      final subCatsSnap = await _firestore
          .collection('Categories')
          .doc(categoryId)
          .collection('subCategories')
          .get();

      final subIds = subCatsSnap.docs.map((d) => d.id).toList();
      final subLinksList = await Future.wait(
        subIds.map((subId) => getStoreLinksForSubCategory(categoryId, subId)),
      );

      for (int i = 0; i < subIds.length; i++) {
        final subId = subIds[i];
        final links = subLinksList[i];
        storesBySubCategory[subId] = links;
        for (final id in links) {
          if (seen.add(id)) orderedMergedIds.add(id);
        }
      }
    } catch (_) {
      // ignore and keep main category links only
    }

    return CategoryStoreLinksResult(
      mergedStoreIds: orderedMergedIds,
      storesBySubCategory: storesBySubCategory,
    );
  }

  Future<List<String>> _getStoreLinksFromCollection(
    CollectionReference<Map<String, dynamic>> storesCollection,
  ) async {
    final querySnapshot = await storesCollection.orderBy('order').get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<List<String>> _getStoreLinksFromArrayField(
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    final doc = await docRef.get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null) return [];
    final dynamic storesField = data['stores'];
    if (storesField is List) {
      return storesField.whereType<String>().toList();
    }
    return [];
  }

  Future<List<String>> getStoreLinksForCategory(String categoryId) async {
    final categoryDoc = _firestore.collection('Categories').doc(categoryId);
    final storesCollection = categoryDoc.collection('stores');
    final subcollectionLinks = await _getStoreLinksFromCollection(
      storesCollection,
    );
    if (subcollectionLinks.isNotEmpty) return subcollectionLinks;
    // fallback to array field on category
    return _getStoreLinksFromArrayField(categoryDoc);
  }

  Future<List<String>> getStoreLinksForSubCategory(
    String categoryId,
    String subCategoryId,
  ) async {
    final subDoc = _firestore
        .collection('Categories')
        .doc(categoryId)
        .collection('subCategories')
        .doc(subCategoryId);
    final storesCollection = subDoc.collection('stores');
    final subcollectionLinks = await _getStoreLinksFromCollection(
      storesCollection,
    );
    if (subcollectionLinks.isNotEmpty) return subcollectionLinks;
    // fallback to array field on subcategory
    return _getStoreLinksFromArrayField(subDoc);
  }

  Future<List<StoreModel>> getStoresByIds(List<String> storeIds) async {
    if (storeIds.isEmpty) return [];

    // Firestore `in` query limited to 10 per request ⇒ chunk
    const int chunkSize = 10;
    final List<StoreModel> stores = [];

    for (var i = 0; i < storeIds.length; i += chunkSize) {
      final chunk = storeIds.sublist(
        i,
        i + chunkSize > storeIds.length ? storeIds.length : i + chunkSize,
      );
      final query = await _firestore
          .collection('markets')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      // جلب الإحصائيات لكل متجر في هذا الجزء
      final storeList = await Future.wait(
        query.docs.map((doc) async {
          final data = doc.data();
          await _enrichStoreStats(doc.id, data);
          return StoreModel.fromMap(doc.id, data);
        }),
      );

      stores.addAll(storeList);
    }
    // Optional: sort stores as the same order of storeIds
    final Map<String, int> orderMap = {
      for (int i = 0; i < storeIds.length; i++) storeIds[i]: i,
    };
    stores.sort((a, b) => (orderMap[a.id] ?? 0).compareTo(orderMap[b.id] ?? 0));

    // Filter out expired stores (only show stores with active licenses)
    stores.removeWhere((store) => store.isLicenseExpired);

    return stores;
  }

  Future<List<StoreModel>> getAllStores() async {
    final query = await _firestore.collection('markets').get();

    final allStores = await Future.wait(
      query.docs.map((doc) async {
        final data = doc.data();
        await _enrichStoreStats(doc.id, data);
        return StoreModel.fromMap(doc.id, data);
      }),
    );

    // Filter out expired stores (only show stores with active licenses)
    return allStores.where((store) => store.hasActiveLicense).toList();
  }

  Future<void> _enrichStoreStats(
    String storeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final ratingDoc = await _firestore
          .collection('markets')
          .doc(storeId)
          .collection('statistics')
          .doc('rating')
          .get();
      if (ratingDoc.exists) {
        final ratingData = ratingDoc.data();
        data['averageRating'] = ratingData?['averageRating'];
        data['totalReviews'] = ratingData?['totalReviews'];
      }
    } catch (_) {
      // ignore
    }

    try {
      final yearlyDoc = await _firestore
          .collection('markets')
          .doc(storeId)
          .collection('statistics')
          .doc(_currentYear)
          .get();
      final summary = yearlyDoc.data()?['summary'];
      if (summary is Map<String, dynamic>) {
        data['completedOrderCount'] =
            (summary['totalOrders'] as num?)?.toInt() ?? 0;
      } else {
        data['completedOrderCount'] = 0;
      }
    } catch (_) {
      data['completedOrderCount'] = 0;
    }
  }
}
