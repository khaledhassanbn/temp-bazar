import 'package:flutter/material.dart';
import 'package:bazar_suez/markets/create_market/services/categories_service.dart'
    as cms;
import 'package:bazar_suez/markets/Markets_after_category/service/category_store_service.dart';
import 'package:bazar_suez/markets/create_market/models/store_model.dart';

class CategoryFilterViewModel extends ChangeNotifier {
  final CategoryStoreService _storeService;

  CategoryFilterViewModel({CategoryStoreService? storeService})
    : _storeService = storeService ?? CategoryStoreService();

  String? selectedCategoryId;
  String? selectedSubCategoryId;

  bool isLoading = false;
  List<cms.SubCategory> subCategories = [];
  List<StoreModel> stores = [];

  // Map to store stores for each category (for home page display)
  Map<String, List<StoreModel>> categoryStoresMap = {};
  bool isLoadingCategoryStores = false;

  Future<void> setCategory(String? categoryId) async {
    selectedCategoryId = categoryId;
    selectedSubCategoryId = null;
    subCategories = [];
    stores = [];

    if (categoryId == null) {
      await fetchAllStores();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final category = await cms.CategoriesService.getCategoryById(categoryId);
      subCategories = category?.subcategories ?? [];
      // دائمًا حمّل متاجر الفئة الرئيسية حتى لو فيه Subcategories
      final links = await _storeService.getStoreLinksForCategory(categoryId);
      stores = await _storeService.getStoresByIds(links);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSubCategory(String? subCategoryId) async {
    selectedSubCategoryId = subCategoryId;
    stores = [];
    notifyListeners();

    if (selectedCategoryId == null) return;
    if (subCategoryId == null || subCategoryId.isEmpty) {
      // عند إلغاء الاختيار: ارجع لمتاجر الفئة الرئيسية
      isLoading = true;
      notifyListeners();
      try {
        final links = await _storeService.getStoreLinksForCategory(
          selectedCategoryId!,
        );
        stores = await _storeService.getStoresByIds(links);
      } finally {
        isLoading = false;
        notifyListeners();
      }
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      final links = await _storeService.getStoreLinksForSubCategory(
        selectedCategoryId!,
        subCategoryId,
      );
      stores = await _storeService.getStoresByIds(links);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<void> fetchAllStores() async {
    isLoading = true;
    selectedCategoryId = null;
    selectedSubCategoryId = null;
    subCategories = [];
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
  }) async {
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
    } finally {
      isLoadingCategoryStores = false;
      notifyListeners();
    }
  }

  /// Clear selected category and fetch all stores again
  void clearCategorySelection() {
    selectedCategoryId = null;
    selectedSubCategoryId = null;
    subCategories = [];
    stores = [];
    notifyListeners();
  }

  /// Select a category and fetch its stores (for home page)
  Future<void> selectCategoryAndFetchStores(String categoryId) async {
    selectedCategoryId = categoryId;
    selectedSubCategoryId = null;
    subCategories = [];
    stores = [];

    isLoading = true;
    notifyListeners();

    try {
      final links = await _storeService.getStoreLinksForCategory(categoryId);
      stores = await _storeService.getStoresByIds(links);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Clear category filter (for home page)
  void clearCategoryFilter() {
    selectedCategoryId = null;
    selectedSubCategoryId = null;
    subCategories = [];
    stores = [];
    notifyListeners();
  }
}
