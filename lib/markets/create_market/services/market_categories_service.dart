import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MarketCategoryModel {
  final String id;
  final String name;
  final int order;

  MarketCategoryModel({
    required this.id,
    required this.name,
    required this.order,
  });

  factory MarketCategoryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MarketCategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'order': order};
}

class MarketProductModel {
  final String id;
  final String name;
  final num price;
  final String? image;
  final String? description;
  final int stock;

  MarketProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.description,
    required this.stock,
  });

  factory MarketProductModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MarketProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      price: data['price'] ?? 0,
      image: data['image'],
      description: data['description'],
      stock: data['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'image': image,
    'description': description,
    'stock': stock,
  };
}

class MarketCategoriesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static CollectionReference _productsCol(String marketId) =>
      _firestore.collection('markets').doc(marketId).collection('products');

  static CollectionReference _productsInCategoryCol(
    String marketId,
    String categoryId,
  ) => _productsCol(marketId).doc(categoryId).collection('items');

  // Categories - قراءة الفئات من subcollection products
  static Future<List<MarketCategoryModel>> getCategories(
    String marketId,
  ) async {
    final snap = await _productsCol(marketId).orderBy('order').get();
    return snap.docs.map(MarketCategoryModel.fromDoc).toList();
  }

  static Future<String> addCategory(
    String marketId, {
    required String name,
  }) async {
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
  }

  // Products
  static Future<String> addProduct(
    String marketId,
    String categoryId, {
    required String name,
    required num price,
    required int stock,
    String? description,
    File? imageFile,
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      final ref = _storage.ref().child(
        'markets/$marketId/products/$categoryId/items/${DateTime.now().millisecondsSinceEpoch}',
      );
      final task = await ref.putFile(imageFile);
      imageUrl = await task.ref.getDownloadURL();
    }

    final doc = await _productsInCategoryCol(marketId, categoryId).add({
      'name': name,
      'price': price,
      'image': imageUrl,
      'description': description,
      'stock': stock,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  static Future<List<MarketProductModel>> getProducts(
    String marketId,
    String categoryId,
  ) async {
    final snap = await _productsInCategoryCol(marketId, categoryId).get();
    return snap.docs.map(MarketProductModel.fromDoc).toList();
  }
}
