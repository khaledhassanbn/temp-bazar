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
  final bool status;
  final bool hasStockLimit;
  final int stock;
  final int soldCount;
  final DateTime? endAt;
  final int order;

  MarketItemModel({
    required this.id,
    required this.name,
    this.price,
    this.finalPrice,
    this.imageUrl,
    this.description,
    this.status = true,
    this.hasStockLimit = false,
    this.stock = 0,
    this.soldCount = 0,
    this.endAt,
    this.order = 0,
  });

  bool get isOutOfStock => hasStockLimit && soldCount >= stock;
  bool get isExpired => endAt != null && DateTime.now().isAfter(endAt!);
  bool get shouldBeHidden => !status || isOutOfStock || isExpired;

  factory MarketItemModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final endAtRaw = data['endAt'];
    DateTime? endAt;
    if (endAtRaw is Timestamp) {
      endAt = endAtRaw.toDate();
    } else if (endAtRaw is DateTime) {
      endAt = endAtRaw;
    }
    return MarketItemModel(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      price: data['price'] as num?,
      finalPrice: data['finalPrice'] as num?,
      imageUrl: data['image']?.toString(),
      description: data['description']?.toString(),
      status: data['status'] ?? true,
      hasStockLimit: data['hasStockLimit'] ?? false,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      soldCount: (data['soldCount'] as num?)?.toInt() ?? 0,
      endAt: endAt,
      order: (data['order'] as num?)?.toInt() ?? 0,
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

  StreamSubscription<QuerySnapshot>? _categoriesSubscription;

  /// كاش المنتجات لكل فئة - يُحفظ ويُعاد استخدامه
  final Map<String, List<MarketItemModel>> _itemsCacheByCategoryId = {};
  /// اشتراكات streams الفئات الفردية
  final Map<String, StreamSubscription<QuerySnapshot>> _itemSubscriptions = {};
  /// الفئات الخام (بدون منتجات) من الـ stream الرئيسي
  final Map<String, MarketCategoryModel> _rawCategoriesById = {};

  // عدد المهام المتوازية لجلب منتجات الأقسام (لتسريع الظهور بدون انتظار طويل)
  static const int _maxConcurrentCategoryFetches = 4;

  bool _isDisposed = false;

  List<MarketCategoryModel> _categories = [];
  List<MarketCategoryModel> get categories => _categories;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StoreModel? get store => _store;

  // ════════════════════════════════════════════════
  // تحميل المتجر بالرابط
  // ════════════════════════════════════════════════
  Future<void> loadByLink(String marketLink) async {
    if (_isDisposed) return;
    if (marketLink.isEmpty) {
      _errorMessage = 'رابط المتجر غير صالح';
      _safeNotify();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final doc = await _firestore.collection('markets').doc(marketLink).get();
      if (_isDisposed) return;
      if (!doc.exists) {
        _errorMessage = 'لم يتم العثور على المتجر';
        _isLoading = false;
        _safeNotify();
      } else {
        _store = StoreModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
        await _fetchMarketData();
      }
    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'حدث خطأ أثناء تحميل بيانات المتجر';
        _isLoading = false;
        _safeNotify();
        if (kDebugMode) print('loadByLink error: $e');
      }
    }
  }

  /// تُستخدم فقط عند غياب الـ marketLink (متجر مباشر بـ id ثابت)
  void startCategoriesStream() {
    _fetchMarketData();
  }

  // ════════════════════════════════════════════════
  // جلب الفئات والمنتجات بسرعة (حل مشكلة N+1 Streams)
  // ════════════════════════════════════════════════
  Future<void> _fetchMarketData() async {
    if (_isDisposed) return;

    if (!_isLoading) {
      _isLoading = true;
      _safeNotify();
    }

    final String marketId = (_store?.id.isNotEmpty == true) ? _store!.id : 'kb';
    final productsRef = _firestore
        .collection('markets')
        .doc(marketId)
        .collection('products');

    // إلغاء كل الاشتراكات القديمة (إذا كانت موجودة)
    _categoriesSubscription?.cancel();
    for (final sub in _itemSubscriptions.values) {
      sub.cancel();
    }
    _itemSubscriptions.clear();
    _rawCategoriesById.clear();
    _itemsCacheByCategoryId.clear();
    _categories = [];

    try {
      // 1. استخدام قراءة واحدة بدلاً من Stream (تحميل الفئات)
      final catSnap = await productsRef.get();
      if (_isDisposed) return;

      final newRaw = <String, MarketCategoryModel>{};
      for (final doc in catSnap.docs) {
        final cat = MarketCategoryModel.fromDoc(doc);
        newRaw[cat.id] = cat;
      }

      _rawCategoriesById..clear()..addAll(newRaw);

      // اعرض الفئات فوراً بناءً على الأولويات؛ بدون انتظار تحميل المنتجات 
      // لتظهر واجهة المستخدم مباشرة بدون بطء
      _rebuildCategories();

      // ✅ نلغي شاشة التحميل الكلية هنا! لترسم الشاشة الغلاف والأقسام،
      // بينما المنتجات تكمل تحميلها في الخلفية
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotify();
      }

      // فرز الأقسام حسب الأهمية: الأكثر مبيعاً ثم العروض، ثم حسب الـ order
      final catsList = newRaw.values.toList();
      catsList.sort((a, b) {
        final nameA = a.name.trim();
        final nameB = b.name.trim();
        
        final isBestA = nameA == 'الاكثر مبيعا' || nameA == 'الأكثر مبيعا';
        final isBestB = nameB == 'الاكثر مبيعا' || nameB == 'الأكثر مبيعا';
        if (isBestA && !isBestB) return -1;
        if (!isBestA && isBestB) return 1;

        final isOffersA = nameA == 'العروض';
        final isOffersB = nameB == 'العروض';
        if (isOffersA && !isOffersB) return -1;
        if (!isOffersA && isOffersB) return 1;

        return a.order.compareTo(b.order);
      });

      // جلب أهم 2 أقسام بالتوازي لتكون جاهزة للمستخدم فوراً
      final firstBatch = catsList.take(2).toList();
      final firstFutures = <Future<void>>[];
      for (final cat in firstBatch) {
        firstFutures.add(_fetchItemsForCategory(productsRef, cat.id));
      }
      await Future.wait(firstFutures);

      // الباقي يتم جلبه بتوازي محدود (pool) بدل التسلسل الذي قد يسبب 20-30 ثانية انتظار
      final remaining = catsList.skip(2).toList();
      await _fetchRemainingCategoriesWithConcurrency(productsRef, remaining);

    } catch (e) {
      if (!_isDisposed) {
        _errorMessage = 'تعذر تحميل الفئات';
        if (kDebugMode) print('Categories fetch error: $e');
      }
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  // ════════════════════════════════════════════════
  // جلب المنتجات لكل فئة
  // ════════════════════════════════════════════════
  Future<void> _fetchItemsForCategory(
    CollectionReference<Map<String, dynamic>> productsRef,
    String categoryId,
  ) async {
    try {
      final snap = await productsRef
          .doc(categoryId)
          .collection('items')
          // ترتيب على السيرفر باستخدام فهرس بسيط (أفضل من ترتيب محلي لقوائم كبيرة)
          .orderBy('order')
          .get();
      
      if (_isDisposed) return;
      
      final items = snap.docs
          .map(MarketItemModel.fromDoc)
          .where((item) => !item.shouldBeHidden)
          .toList();
      
      _itemsCacheByCategoryId[categoryId] = items;
      
      // تحديث قائمة الفئات لتظهر محتوياتها بمجرد جاهزيتها
      _rebuildCategories();
      
    } catch (e) {
      if (kDebugMode) print('Items fetch error ($categoryId): $e');
      _itemsCacheByCategoryId[categoryId] = []; // تعيين كفارِغ في حالة الخطأ
      _rebuildCategories();
    }
  }

  Future<void> _fetchRemainingCategoriesWithConcurrency(
    CollectionReference<Map<String, dynamic>> productsRef,
    List<MarketCategoryModel> remaining,
  ) async {
    if (remaining.isEmpty) return;

    var i = 0;
    while (i < remaining.length && !_isDisposed) {
      final end = (i + _maxConcurrentCategoryFetches).clamp(0, remaining.length);
      final batch = remaining.sublist(i, end);
      await Future.wait(batch.map((c) => _fetchItemsForCategory(productsRef, c.id)));
      i = end;
      // اترك مساحة للـUI بين الدُفعات بدل delay ثابت كبير
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  // ════════════════════════════════════════════════
  // إعادة بناء قائمة الفئات بكفاءة
  // ════════════════════════════════════════════════
  void _rebuildCategories() {
    if (_isDisposed) return;

    final built = <MarketCategoryModel>[];
    for (final raw in _rawCategoriesById.values) {
      final items = _itemsCacheByCategoryId[raw.id];
      if (items != null) {
        // اكتمل تحميل القسم، إظهار الفئة فقط إذا كان لها منتجات
        if (items.isNotEmpty) {
          built.add(raw.copyWith(items: items));
        }
      } else {
        // القسم قيد التحميل: إظهاره فارغاً ليجهز الواجهة بلا انتظار
        built.add(raw);
      }
    }

    built.sort((a, b) => a.order.compareTo(b.order));
    _categories = built;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _categoriesSubscription?.cancel();
    for (final sub in _itemSubscriptions.values) {
      sub.cancel();
    }
    _itemSubscriptions.clear();
    super.dispose();
  }
}
