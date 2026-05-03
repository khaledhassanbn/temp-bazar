import 'package:flutter/material.dart';
import 'package:bazar_suez/markets/create_market/services/categories_service.dart'
    as cms;
import 'package:bazar_suez/markets/Markets_after_category/service/category_store_service.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';

/// خيارات الفرز المتاحة
enum SortOption {
  suggested, // المقترحات (الترتيب الافتراضي)
  alphabetical, // ترتيب أبجدي
  mostReviews, // تعليقات أكثر
  bySubcategory, // حسب الفئات الفرعية
  bestSelling, // أكثر مبيعاً
  highRating, // تقييم +4.0 (فلتر)
}

class CategoryFilterViewModel extends ChangeNotifier {
  final CategoryStoreService _storeService;

  CategoryFilterViewModel({CategoryStoreService? storeService})
    : _storeService = storeService ?? CategoryStoreService();

  String? selectedCategoryId;
  String? selectedSubCategoryId;

  bool isLoading = false;
  List<cms.SubCategory> subCategories = [];
  List<StoreModel> stores = [];
  List<String> _defaultStoreOrder = [];
  Map<String, List<String>> _storesBySubCategory = {};

  SortOption _selectedSort = SortOption.suggested;
  SortOption get selectedSort => _selectedSort;
  bool filterAlphabetical = false;
  bool filterMostReviews = false;
  bool filterBestSelling = false;
  bool filterMinRating4 = false;

  // Map to store stores for each category (for home page display)
  Map<String, List<StoreModel>> categoryStoresMap = {};
  bool isLoadingCategoryStores = false;
  bool _hasLoadedCategoryStores = false;

  /// المتاجر بعد تطبيق الفرز والتصفية
  List<StoreModel> get sortedStores {
    List<StoreModel> result = List.from(stores);

    if (selectedSubCategoryId != null && selectedSubCategoryId!.isNotEmpty) {
      final ids = _storesBySubCategory[selectedSubCategoryId!] ?? const <String>[];
      final idSet = ids.toSet();
      result = result.where((s) => idSet.contains(s.id)).toList();
    }

    if (filterMinRating4) {
      result = result.where((s) => s.averageRating >= 4.0).toList();
    }

    if (!filterAlphabetical && !filterMostReviews && !filterBestSelling) {
      _sortByDefaultOrder(result);
      return result;
    }

    result.sort((a, b) {
      if (filterBestSelling) {
        final c = b.completedOrderCount.compareTo(a.completedOrderCount);
        if (c != 0) return c;
      }
      if (filterMostReviews) {
        final c = b.totalReviews.compareTo(a.totalReviews);
        if (c != 0) return c;
      }
      if (filterAlphabetical) {
        final c = a.name.compareTo(b.name);
        if (c != 0) return c;
      }
      return 0;
    });

    return result;
  }

  void _syncSelectedSortLabel() {
    if (selectedSubCategoryId != null && selectedSubCategoryId!.isNotEmpty) {
      _selectedSort = SortOption.bySubcategory;
      return;
    }
    if (filterBestSelling) {
      _selectedSort = SortOption.bestSelling;
      return;
    }
    if (filterMostReviews) {
      _selectedSort = SortOption.mostReviews;
      return;
    }
    if (filterAlphabetical) {
      _selectedSort = SortOption.alphabetical;
      return;
    }
    if (filterMinRating4) {
      _selectedSort = SortOption.highRating;
      return;
    }
    _selectedSort = SortOption.suggested;
  }

  void clearAllFilters() {
    filterAlphabetical = false;
    filterMostReviews = false;
    filterBestSelling = false;
    filterMinRating4 = false;
    selectedSubCategoryId = null;
    _selectedSort = SortOption.suggested;
    notifyListeners();
  }

  void toggleAlphabetical() {
    filterAlphabetical = !filterAlphabetical;
    _syncSelectedSortLabel();
    notifyListeners();
  }

  void toggleMostReviews() {
    filterMostReviews = !filterMostReviews;
    _syncSelectedSortLabel();
    notifyListeners();
  }

  void toggleBestSelling() {
    filterBestSelling = !filterBestSelling;
    _syncSelectedSortLabel();
    notifyListeners();
  }

  void toggleMinRating4() {
    filterMinRating4 = !filterMinRating4;
    _syncSelectedSortLabel();
    notifyListeners();
  }

  /// إبقاء setSort للتوافق مع الاستدعاءات القديمة
  void setSort(SortOption sort) {
    filterAlphabetical = sort == SortOption.alphabetical;
    filterMostReviews = sort == SortOption.mostReviews;
    filterBestSelling = sort == SortOption.bestSelling;
    filterMinRating4 = sort == SortOption.highRating;
    if (sort != SortOption.bySubcategory) {
      selectedSubCategoryId = null;
    }
    _selectedSort = sort;
    notifyListeners();
  }

  void _sortByDefaultOrder(List<StoreModel> list) {
    if (_defaultStoreOrder.isEmpty) return;
    final orderMap = {
      for (int i = 0; i < _defaultStoreOrder.length; i++) _defaultStoreOrder[i]: i,
    };
    list.sort(
      (a, b) =>
          (orderMap[a.id] ?? (1 << 30)).compareTo(orderMap[b.id] ?? (1 << 30)),
    );
  }

  Future<void> setCategory(String? categoryId) async {
    selectedCategoryId = categoryId;
    selectedSubCategoryId = null;
    subCategories = [];
    stores = [];
    _defaultStoreOrder = [];
    _storesBySubCategory = {};
    _selectedSort = SortOption.suggested;
    filterAlphabetical = false;
    filterMostReviews = false;
    filterBestSelling = false;
    filterMinRating4 = false;

    if (categoryId == null) {
      await fetchAllStores();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final category = await cms.CategoriesService.getCategoryById(categoryId);
      subCategories = category?.subcategories ?? [];
      final linksResult = await _storeService
          .getCategoryWithSubcategoryStoreLinks(categoryId);
      _storesBySubCategory = linksResult.storesBySubCategory;
      _defaultStoreOrder = linksResult.mergedStoreIds;
      stores = await _storeService.getStoresByIds(linksResult.mergedStoreIds);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSubCategory(String? subCategoryId) async {
    selectedSubCategoryId = subCategoryId;
    _syncSelectedSortLabel();
    notifyListeners();
  }

  Future<void> fetchAllStores() async {
    isLoading = true;
    selectedCategoryId = null;
    selectedSubCategoryId = null;
    subCategories = [];
    _defaultStoreOrder = [];
    _storesBySubCategory = {};
    _selectedSort = SortOption.suggested;
    filterAlphabetical = false;
    filterMostReviews = false;
    filterBestSelling = false;
    filterMinRating4 = false;
    notifyListeners();

    try {
      stores = await _storeService.getAllStores();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch stores for all categories with a limit per category
  /// Used for home page display
  Future<void> fetchStoresForAllCategories(
    List<String> categoryIds, {
    int limit = 8,
    bool force = false,
  }) async {
    if (_hasLoadedCategoryStores && !force) return;

    isLoadingCategoryStores = true;
    notifyListeners();

    try {
      categoryStoresMap = {};
      for (final categoryId in categoryIds) {
        final links = await _storeService.getStoreLinksForCategory(categoryId);
        final limitedLinks = links.take(limit).toList();
        final categoryStores = await _storeService.getStoresByIds(limitedLinks);
        categoryStoresMap[categoryId] = categoryStores;
      }
      _hasLoadedCategoryStores = true;
    } finally {
      isLoadingCategoryStores = false;
      notifyListeners();
    }
  }

  void clearCategorySelection() {
    selectedCategoryId = null;
    selectedSubCategoryId = null;
    subCategories = [];
    stores = [];
    _defaultStoreOrder = [];
    _storesBySubCategory = {};
    _selectedSort = SortOption.suggested;
    filterAlphabetical = false;
    filterMostReviews = false;
    filterBestSelling = false;
    filterMinRating4 = false;
    notifyListeners();
  }

  Future<void> selectCategoryAndFetchStores(String categoryId) async {
    selectedCategoryId = categoryId;
    selectedSubCategoryId = null;
    subCategories = [];
    stores = [];
    _defaultStoreOrder = [];
    _storesBySubCategory = {};
    _selectedSort = SortOption.suggested;
    filterAlphabetical = false;
    filterMostReviews = false;
    filterBestSelling = false;
    filterMinRating4 = false;

    isLoading = true;
    notifyListeners();

    try {
      final linksResult = await _storeService
          .getCategoryWithSubcategoryStoreLinks(categoryId);
      _storesBySubCategory = linksResult.storesBySubCategory;
      _defaultStoreOrder = linksResult.mergedStoreIds;
      stores = await _storeService.getStoresByIds(linksResult.mergedStoreIds);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void clearCategoryFilter() {
    selectedCategoryId = null;
    selectedSubCategoryId = null;
    subCategories = [];
    stores = [];
    _defaultStoreOrder = [];
    _storesBySubCategory = {};
    _selectedSort = SortOption.suggested;
    filterAlphabetical = false;
    filterMostReviews = false;
    filterBestSelling = false;
    filterMinRating4 = false;
    notifyListeners();
  }
}
