import 'package:flutter/material.dart';

import '../../add_product/models/product_models.dart';
import '../../add_product/services/product_service.dart';

class ManageProductsViewModel extends ChangeNotifier {
  bool isLoadingCategories = false;
  bool isLoadingProducts = false;
  bool isSavingOrder = false;
  String? errorMessage;
  String? successMessage;

  ProductCategoryModel? selectedCategory;
  List<ProductCategoryModel> categories = [];
  List<ProductModel> products = [];
  String searchQuery = '';

  // أسماء غير قابلة للترتيب
  final List<String> _fixedNames = ['الأكثر مبيعاً', 'العروض'];

  List<ProductModel> get filteredProducts {
    if (searchQuery.trim().isEmpty) return products;
    final q = searchQuery.trim().toLowerCase();
    return products.where((p) {
      final inName = p.name.toLowerCase().contains(q);
      final inDesc = (p.description ?? '').toLowerCase().contains(q);
      return inName || inDesc;
    }).toList();
  }

  bool _isFixed(ProductCategoryModel c) {
    return _fixedNames.contains(c.name);
  }

  Future<void> loadCategories(String marketId) async {
    try {
      isLoadingCategories = true;
      errorMessage = null;
      notifyListeners();

      final allCategories = await ProductService.getCategories(marketId);
      // نرتب بحسب الحقل order من backend إن وُجد
      try {
        allCategories.sort((a, b) => a.order.compareTo(b.order));
      } catch (_) {}

      // جلب المنتجات لكل فئة ثم فلترة الفارغة
      final productsFutures = allCategories
          .map((c) => ProductService.getProducts(marketId, c.id))
          .toList();
      final productsPerCategory = await Future.wait(productsFutures);

      final filtered = <ProductCategoryModel>[];
      for (var i = 0; i < allCategories.length; i++) {
        final cat = allCategories[i];
        final prods = productsPerCategory[i];
        if (prods.isNotEmpty) filtered.add(cat);
      }

      categories = filtered;

      // المحافظة على المحددة أو اختيار الأولى
      if (selectedCategory != null) {
        final found = categories.firstWhere(
          (c) => c.id == selectedCategory!.id,
          orElse: () =>
              categories.isNotEmpty ? categories.first : selectedCategory!,
        );
        selectedCategory = found;
      } else if (categories.isNotEmpty) {
        selectedCategory = categories.first;
      }

      if (selectedCategory != null) {
        await loadProducts(marketId, selectedCategory!.id);
      } else {
        products = [];
      }
    } catch (e) {
      errorMessage = 'حدث خطأ أثناء تحميل الفئات';
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(ProductCategoryModel category) async {
    selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadProducts(String marketId, String categoryId) async {
    try {
      isLoadingProducts = true;
      errorMessage = null;
      notifyListeners();

      products = await ProductService.getProducts(marketId, categoryId);
    } catch (e) {
      errorMessage = 'حدث خطأ أثناء تحميل المنتجات';
    } finally {
      isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// إعادة ترتيب الفئات: يحدث محليًا، يحفظ فورًا في الـ backend (مباشر)، ويرجع عند فشل الحفظ.
  Future<void> onReorderCategories(
    String marketId,
    int oldIndex,
    int newIndex,
  ) async {
    // newIndex يأتي من ReorderableListView؛ نحدد مكان الإدراج الصحيح بعد إزالة العنصر
    final int insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;

    // validations
    if (oldIndex < 0 || oldIndex >= categories.length) return;
    if (insertIndex < 0 || insertIndex > categories.length) return;

    final moving = categories[oldIndex];

    // لو العنصر نفسه ثابت أو نحاول الإدراج عند عنصر ثابت، نوقف
    if (_isFixed(moving)) return;
    // ملاحظة: insertIndex قد يساوي categories.length (إدراج في النهاية) -> في هذه الحالة لا يوجد targetCat
    ProductCategoryModel? targetCat;
    if (insertIndex < categories.length) targetCat = categories[insertIndex];
    if (targetCat != null && _isFixed(targetCat)) {
      // منع الإدراج داخل موضع عنصر ثابت
      return;
    }

    // قم ببناء قائمة جديدة مع نقل العنصر
    final temp = List<ProductCategoryModel>.from(categories);
    final item = temp.removeAt(oldIndex);
    // إذا insertIndex > temp.length (نهاية) نضع في النهاية
    final safeInsert = insertIndex <= temp.length ? insertIndex : temp.length;
    temp.insert(safeInsert, item);

    final updated = List<ProductCategoryModel>.generate(
      temp.length,
      (index) => temp[index].copyWith(order: index + 1),
    );

    // احتفظ بنسخة قديمة للـ rollback لو فشل الحفظ
    final oldSnapshot = List<ProductCategoryModel>.from(categories);

    // عيّن محليًا وحدث الـ UI فورًا
    categories = updated;
    notifyListeners();

    // الآن نحفظ مباشرة في backend (مباشر)
    try {
      isSavingOrder = true;
      notifyListeners();

      await ProductService.reorderCategories(marketId, categories);

      successMessage = 'تم حفظ ترتيب الفئات';
    } catch (e) {
      // rollback عند الخطأ
      categories = oldSnapshot;
      errorMessage = 'تعذر حفظ الترتيب — تم التراجع';
      notifyListeners();
    } finally {
      isSavingOrder = false;
      notifyListeners();
    }
  }

  /// (بدون تغيير كبير) لكن يمكن استخدامه لو حبيت أن المستخدم يضغط زر الحفظ يدوياً
  Future<void> saveCategoriesOrder(String marketId) async {
    try {
      isSavingOrder = true;
      successMessage = null;
      errorMessage = null;
      notifyListeners();

      // تأكد حقل order محدث
      final toSend = List<ProductCategoryModel>.generate(
        categories.length,
        (index) => categories[index].copyWith(order: index + 1),
      );

      await ProductService.reorderCategories(marketId, toSend);
      await loadCategories(marketId);
      successMessage = 'تم حفظ ترتيب الفئات بنجاح';
    } catch (e) {
      errorMessage = 'تعذر حفظ ترتيب الفئات';
    } finally {
      isSavingOrder = false;
      notifyListeners();
    }
  }

  Future<void> onReorderProducts(
    String marketId,
    String categoryId,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < 0 || oldIndex >= products.length) return;
    if (newIndex < 0 || newIndex > products.length) return;

    // Flutter يعيد newIndex كما لو كان العنصر أُزيل بالفعل
    final insertIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;

    final temp = List<ProductModel>.from(products);
    final movingItem = temp.removeAt(oldIndex);
    final safeInsert = insertIndex.clamp(0, temp.length).toInt();
    temp.insert(safeInsert, movingItem);

    final updated = List<ProductModel>.generate(
      temp.length,
      (index) => temp[index].copyWith(order: index + 1),
    );

    final oldSnapshot = List<ProductModel>.from(products);
    products = updated;
    notifyListeners();

    // حفظ مباشر للمنتجات (كما تريد)
    try {
      await ProductService.reorderProducts(marketId, categoryId, products);
      successMessage = 'تم تحديث ترتيب المنتجات';
    } catch (e) {
      products = oldSnapshot;
      errorMessage = 'تعذر تحديث ترتيب المنتجات';
      notifyListeners();
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteProduct(
    String marketId,
    String categoryId,
    String productId,
  ) async {
    final idx = products.indexWhere((p) => p.id == productId);
    if (idx != -1) {
      final removed = products.removeAt(idx);
      notifyListeners();
      try {
        await ProductService.deleteProduct(marketId, categoryId, productId);
        successMessage = 'تم حذف المنتج: ${removed.name}';
      } catch (e) {
        // rollback
        products.insert(idx, removed);
        errorMessage = 'تعذر حذف المنتج';
        notifyListeners();
      }
    }
  }

  void applySearch(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<void> editProduct(
    String marketId,
    String categoryId,
    ProductModel updated,
  ) async {
    final index = products.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    final original = products[index];
    products[index] = updated;
    notifyListeners();
    try {
      await ProductService.updateProduct(
        marketId,
        categoryId,
        updated.id,
        name: updated.name,
        price: updated.price,
        stock: updated.stock,
        description: updated.description,
        hasDiscount: updated.hasDiscount,
        discountValue: updated.discountValue,
        hasStockLimit: updated.hasStockLimit,
        endAt: updated.endAt,
        status: updated.status,
        inStock: updated.inStock,
        requiredOptions: updated.requiredOptions,
        extraOptions: updated.extraOptions,
      );
      successMessage = 'تم حفظ تعديل المنتج';
    } catch (e) {
      products[index] = original;
      errorMessage = 'تعذر حفظ تعديل المنتج';
      notifyListeners();
    }
  }

  void updateProductLocally(ProductModel updated) {
    final index = products.indexWhere((p) => p.id == updated.id);
    if (index == -1) return;
    products[index] = updated;
    notifyListeners();
  }
}
