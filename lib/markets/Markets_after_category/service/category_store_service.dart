import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';

class CategoryStoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      stores.addAll(
        query.docs.map((doc) => StoreModel.fromMap(doc.id, doc.data())),
      );
    }
    // Optional: sort stores as the same order of storeIds
    final Map<String, int> orderMap = {
      for (int i = 0; i < storeIds.length; i++) storeIds[i]: i,
    };
    stores.sort((a, b) => (orderMap[a.id] ?? 0).compareTo(orderMap[b.id] ?? 0));
    return stores;
  }
  Future<List<StoreModel>> getAllStores() async {
    final query = await _firestore.collection('markets').get();
    return query.docs.map((doc) => StoreModel.fromMap(doc.id, doc.data())).toList();
  }
}
