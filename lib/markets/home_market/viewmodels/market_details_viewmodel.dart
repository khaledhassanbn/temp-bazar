import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';

/// عنصر منتج مبسط للعرض داخل أقسام المتجر
class MarketItemModel {
  final String id;
  final String name;
  final num? price;
  final num? finalPrice;
  final String? imageUrl;
  final String? description;

  MarketItemModel({
    required this.id,
    required this.name,
    this.price,
    this.finalPrice,
    this.imageUrl,
    this.description,
  });

  factory MarketItemModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MarketItemModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      price: data['price'] as num?,
      finalPrice: data['finalPrice'] as num?,
      imageUrl: data['image']?.toString(),
      description: data['description']?.toString(),
    );
  }
}

/// فئة تحتوي على بيانات الفئة وقائمة العناصر الخاصة بها
class MarketCategoryModel {
  final String id;
  final String name;
  final int order;
  final int numberOfProducts;
  final List<MarketItemModel> items;

  MarketCategoryModel({
    required this.id,
    required this.name,
    required this.order,
    required this.numberOfProducts,
    this.items = const [],
  });

  MarketCategoryModel copyWith({List<MarketItemModel>? items}) {
    return MarketCategoryModel(
      id: id,
      name: name,
      order: order,
      numberOfProducts: numberOfProducts,
      items: items ?? this.items,
    );
  }

  factory MarketCategoryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MarketCategoryModel(
      id: doc.id,
      name: (data['name']?.toString() ?? doc.id),
      order: (data['order'] as num?)?.toInt() ?? 0,
      numberOfProducts: (data['numberOfProducts'] as num?)?.toInt() ?? 0,
    );
  }
}

class MarketDetailsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;
  StoreModel? _store;

  // تدفقات الفئات والعناصر
  Stream<List<MarketCategoryModel>>? _categoriesStream;
  StreamSubscription<List<MarketCategoryModel>>? _categoriesSubscription;
  List<MarketCategoryModel> _categories = [];
  bool _isDisposed = false;
  bool get _canNotify => !_isDisposed;

  void _safeNotifyListeners() {
    if (_canNotify) notifyListeners();
  }

  List<MarketCategoryModel> get categories => _categories;
  MarketCategoryModel? get bestSellersCategory =>
      _categories
          .firstWhere(
            (c) => c.name.trim() == 'الأكثر مبيعا' && c.items.isNotEmpty,
            orElse: () => MarketCategoryModel(
              id: '',
              name: '',
              order: 0,
              numberOfProducts: 0,
            ),
          )
          .id
          .isEmpty
      ? null
      : _categories.firstWhere((c) => c.name.trim() == 'الأكثر مبيعا');
  MarketCategoryModel? get offersCategory =>
      _categories
          .firstWhere(
            (c) => c.name.trim() == 'العروض' && c.items.isNotEmpty,
            orElse: () => MarketCategoryModel(
              id: '',
              name: '',
              order: 0,
              numberOfProducts: 0,
            ),
          )
          .id
          .isEmpty
      ? null
      : _categories.firstWhere((c) => c.name.trim() == 'العروض');

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StoreModel? get store => _store;

  Future<void> loadByLink(String marketLink) async {
    if (_isDisposed) return;
    if (marketLink.isEmpty) {
      _errorMessage = 'رابط المتجر غير صالح';
      _safeNotifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();
    try {
      final doc = await _firestore.collection('markets').doc(marketLink).get();
      if (_isDisposed) return;
      if (!doc.exists) {
        _errorMessage = 'لم يتم العثور على المتجر';
      } else {
        final data = doc.data() as Map<String, dynamic>;
        // averageRating و totalReviews موجودين في document المتجر مباشرة
        // (بفضل denormalization في ReviewService)
        // لا حاجة لـ query إضافي على statistics/rating subcollection

        if (_isDisposed) return;
        _store = StoreModel.fromMap(doc.id, data);
        // ابدأ بث الفئات حسب الهيكل الجديد (من جذر products)
        startCategoriesStream();
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل بيانات المتجر';
      if (kDebugMode) {
        print('MarketDetailsViewModel.loadByLink error: $e');
      }
    } finally {
      if (_isDisposed) return;
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// يبدأ جلب الفئات — تحميل أولي سريع بالتوازي ثم بث للتحديثات
  void startCategoriesStream() {
    final String marketId = (_store?.id.isNotEmpty == true) ? _store!.id : 'kb';

    final productsCollection = _firestore
        .collection('markets')
        .doc(marketId)
        .collection('products');

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 1) تحميل أولي سريع بـ get() — أسرع من snapshots() للمرة الأولى
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _loadCategoriesOnce(productsCollection);

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 2) بث للتحديثات في الخلفية (لو أضاف صاحب المتجر منتج جديد)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    _categoriesSubscription?.cancel();
    if (_isDisposed) return;

    _categoriesStream = productsCollection.snapshots().asyncMap((
      snapshot,
    ) async {
      final rawCategories = snapshot.docs
          .map((d) => MarketCategoryModel.fromDoc(d))
          .toList();

      final futures = rawCategories.map((category) async {
        final itemsSnap = await productsCollection
            .doc(category.id)
            .collection('items')
            .get();
        final items = itemsSnap.docs.map(MarketItemModel.fromDoc).toList();
        return category.copyWith(items: items);
      }).toList();

      var withItems = await Future.wait(futures);
      withItems = withItems.where((c) => c.items.isNotEmpty).toList();
      withItems.sort((a, b) => a.order.compareTo(b.order));
      return withItems;
    });

    _categoriesSubscription = _categoriesStream!.listen(
      (data) {
        if (_isDisposed) return;
        _categories = data;
        _safeNotifyListeners();
      },
      onError: (e) {
        if (_isDisposed) return;
        if (kDebugMode) {
          print('Categories stream error: $e');
        }
        _errorMessage = 'تعذر تحميل الفئات';
        _safeNotifyListeners();
      },
    );
  }

  /// تحميل أولي سريع — كل الفئات والـ items بالتوازي بدون stream
  Future<void> _loadCategoriesOnce(CollectionReference productsCollection) async {
    try {
      final categoriesSnap = await productsCollection.get();
      if (_isDisposed) return;

      final rawCategories = categoriesSnap.docs
          .map((d) => MarketCategoryModel.fromDoc(d))
          .toList();

      // جلب items لكل فئة بالتوازي
      final futures = rawCategories.map((category) async {
        final itemsSnap = await productsCollection
            .doc(category.id)
            .collection('items')
            .get();
        final items = itemsSnap.docs.map(MarketItemModel.fromDoc).toList();
        return category.copyWith(items: items);
      }).toList();

      var withItems = await Future.wait(futures);
      withItems = withItems.where((c) => c.items.isNotEmpty).toList();
      withItems.sort((a, b) => a.order.compareTo(b.order));

      if (_isDisposed) return;
      _categories = withItems;
      _safeNotifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('_loadCategoriesOnce error: $e');
      }
      // الـ stream هيحاول تاني في الخلفية
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
