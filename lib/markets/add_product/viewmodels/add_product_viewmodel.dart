import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../create_market/models/store_model.dart';
import '../../create_market/services/store_service.dart';
import '../services/product_service.dart';
import '../models/product_models.dart';

class AddProductViewModel extends ChangeNotifier {
  final StoreService _storeService = StoreService();

  // Categories per selected store
  List<ProductCategoryModel> categories = [];
  ProductCategoryModel? selectedCategory;

  bool isLoadingStores = false;
  bool isLoadingCategories = false;
  bool isAddingProduct = false;
  List<StoreModel> userStores = [];
  StoreModel? selectedStore;

  String? errorMessage;
  String? successMessage;

  // Product inputs
  String productName = '';
  String productDescription = '';
  num productPrice = 0;
  int productStock = 0;
  File? productImage;

  // Stock limit settings
  bool hasStockLimit = false;
  int stockQuantity = 0;

  // Discount settings
  bool hasDiscount = false;
  num discountValue = 0;
  num get finalPrice {
    final raw = hasDiscount ? (productPrice - discountValue) : productPrice;
    return raw < 1 ? 1 : raw;
  }

  // End date settings
  bool hasEndDate = false;
  DateTime? endAt;
  bool status = true;
  bool inStock = true;

  // Product options
  List<ProductOptionModel> requiredOptions = [];
  List<ProductOptionModel> extraOptions = [];

  // Cached products for arrangement
  bool isLoadingProductsForArrange = false;
  List<ProductModel> productsInSelectedCategory = [];

  // New category
  String newCategoryName = '';

  Future<void> loadUserStores() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null || email.isEmpty) {
      userStores = [];
      notifyListeners();
      return;
    }

    isLoadingStores = true;
    errorMessage = null;
    notifyListeners();

    try {
      userStores = await _storeService.getStoresByEmail(email);
      // حافظ على اختيار سابق إن أمكن
      if (selectedStore != null) {
        selectedStore = userStores.firstWhere(
          (s) => s.id == selectedStore!.id,
          orElse: () =>
              userStores.isNotEmpty ? userStores.first : selectedStore!,
        );
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoadingStores = false;
      notifyListeners();
    }
  }

  void setSelectedStore(StoreModel? store) {
    selectedStore = store;
    // Load categories for this store
    if (store != null) {
      loadStoreCategories(store.id);
    } else {
      categories = [];
      selectedCategory = null;
    }
    notifyListeners();
  }

  Future<void> loadStoreCategories(String storeId) async {
    isLoadingCategories = true;
    errorMessage = null;
    notifyListeners();

    try {
      categories = await ProductService.getCategories(storeId);
      if (categories.isNotEmpty) {
        selectedCategory = categories.first;
      } else {
        errorMessage = 'لا توجد فئات متاحة لهذا المتجر';
      }
    } catch (e) {
      errorMessage = 'خطأ في تحميل الفئات: ${e.toString()}';
      print('خطأ في تحميل الفئات: $e');
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadProductsForSelectedCategory() async {
    if (selectedStore == null || selectedCategory == null) return;
    isLoadingProductsForArrange = true;
    notifyListeners();
    try {
      productsInSelectedCategory = await ProductService.getProducts(
        selectedStore!.id,
        selectedCategory!.id,
      );
    } catch (e) {
      errorMessage = 'خطأ في تحميل المنتجات: ${e.toString()}';
    } finally {
      isLoadingProductsForArrange = false;
      notifyListeners();
    }
  }

  ProductModel buildTemporaryProductForArrange() {
    return ProductModel(
      id: 'temp_new',
      name: productName,
      price: productPrice,
      image: null,
      description: productDescription.isNotEmpty ? productDescription : null,
      stock: hasStockLimit ? stockQuantity : 0,
      hasStockLimit: hasStockLimit,
      hasDiscount: hasDiscount,
      discountValue: hasDiscount ? discountValue : null,
      finalPrice: finalPrice,
      requiredOptions: requiredOptions,
      extraOptions: extraOptions,
      endAt: hasEndDate ? endAt : null,
      status: status,
      inStock: inStock,
      order:
          (productsInSelectedCategory.isNotEmpty
              ? (productsInSelectedCategory
                    .map((e) => e.order)
                    .reduce((a, b) => a > b ? a : b))
              : 0) +
          1,
    );
  }

  void reorderInMemory(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = productsInSelectedCategory.removeAt(oldIndex);
    productsInSelectedCategory.insert(newIndex, item);
    // renumber orders starting from 1
    for (var i = 0; i < productsInSelectedCategory.length; i++) {
      productsInSelectedCategory[i] = productsInSelectedCategory[i].copyWith(
        order: i + 1,
      );
    }
    notifyListeners();
  }

  Future<void> saveArrangementIncludingNewIfAny() async {
    if (!isFormValid) {
      throw validationError ?? 'اكمل البيانات أولاً';
    }
    if (selectedStore == null || selectedCategory == null) {
      throw 'اختر المتجر والفئة أولاً';
    }

    isAddingProduct = true;
    notifyListeners();

    try {
      // 1) احسب الترتيب النهائي بناءً على ترتيب العناصر على الشاشة
      for (var i = 0; i < productsInSelectedCategory.length; i++) {
        productsInSelectedCategory[i] = productsInSelectedCategory[i].copyWith(
          order: i + 1,
        );
      }

      // 2) أضف المنتج المؤقت إلى القاعدة بنفس الترتيب الظاهر
      final tempIndex = productsInSelectedCategory.indexWhere(
        (p) => p.id == 'temp_new',
      );
      if (tempIndex != -1) {
        final temp = productsInSelectedCategory[tempIndex];
        final newProductId = await ProductService.addProduct(
          selectedStore!.id,
          selectedCategory!.id,
          name: temp.name,
          price: temp.price,
          stock: temp.stock,
          description: temp.description,
          imageFile: productImage,
          hasStockLimit: hasStockLimit,
          hasDiscount: hasDiscount,
          discountValue: hasDiscount ? discountValue : null,
          finalPrice: finalPrice,
          requiredOptions: requiredOptions,
          extraOptions: extraOptions,
          endAt: hasEndDate ? endAt : null,
          status: status,
          inStock: inStock,
          order: temp.order,
        );
        // استبدله بالنسخة ذات المعرف الحقيقي
        productsInSelectedCategory[tempIndex] = temp.copyWith(id: newProductId);
      }

      // 3) احفظ ترتيب كل المنتجات (بما فيها الجديد) في دفعة واحدة
      await ProductService.reorderProducts(
        selectedStore!.id,
        selectedCategory!.id,
        productsInSelectedCategory,
      );

      successMessage = 'تم حفظ الترتيب وإضافة المنتج';
      _resetForm();
      productsInSelectedCategory = [];
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      isAddingProduct = false;
      notifyListeners();
    }
  }

  void setSelectedCategoryByName(String? name) {
    if (name == null) {
      selectedCategory = null;
    } else {
      selectedCategory = categories.firstWhere(
        (c) => c.name == name,
        orElse: () => categories.first,
      );
    }
    notifyListeners();
  }

  // Input setters
  void setProductName(String v) {
    productName = v;
    notifyListeners();
  }

  void setProductDescription(String v) {
    productDescription = v;
    notifyListeners();
  }

  void setProductPrice(String v) {
    final parsed = num.tryParse(v.trim());
    if (parsed != null) {
      productPrice = parsed < 1 ? 1 : parsed;
      if (hasDiscount) {
        final maxAllowedDiscount = productPrice - 1;
        if (discountValue > maxAllowedDiscount) {
          discountValue = maxAllowedDiscount < 0 ? 0 : maxAllowedDiscount;
        }
      }
    }
    notifyListeners();
  }

  void setProductStock(String v) {
    final parsed = int.tryParse(v.trim());
    if (parsed != null) productStock = parsed;
    notifyListeners();
  }

  void setProductImage(File? image) {
    productImage = image;
    notifyListeners();
  }

  // Stock limit setters
  void setHasStockLimit(bool value) {
    hasStockLimit = value;
    if (!value) {
      stockQuantity = 0;
    }
    notifyListeners();
  }

  void setStockQuantity(String v) {
    final parsed = int.tryParse(v.trim());
    if (parsed != null) stockQuantity = parsed;
    notifyListeners();
  }

  // Discount setters
  void setHasDiscount(bool value) {
    hasDiscount = value;
    if (!value) {
      discountValue = 0;
    }
    notifyListeners();
  }

  void setDiscountValue(String v) {
    final parsed = num.tryParse(v.trim());
    if (parsed != null) {
      var val = parsed < 0 ? 0 : parsed;
      final maxAllowedDiscount = productPrice - 1;
      if (val > maxAllowedDiscount) {
        val = maxAllowedDiscount < 0 ? 0 : maxAllowedDiscount;
      }
      discountValue = val;
    }
    notifyListeners();
  }

  // End date setters
  void setHasEndDate(bool value) {
    hasEndDate = value;
    if (!value) {
      endAt = null;
    }
    notifyListeners();
  }

  void setEndAt(DateTime? dateTime) {
    endAt = dateTime;
    notifyListeners();
  }

  void setStatus(bool value) {
    status = value;
    notifyListeners();
  }

  void setInStock(bool value) {
    inStock = value;
    notifyListeners();
  }

  // Options management
  void setRequiredOptions(List<ProductOptionModel> options) {
    requiredOptions = options;
    notifyListeners();
  }

  void setExtraOptions(List<ProductOptionModel> options) {
    extraOptions = options;
    notifyListeners();
  }

  void addRequiredOption(String name, List<String> choices) {
    final option = ProductOptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: name,
      choices: choices
          .map((c) => OptionChoiceModel(name: c, price: 0))
          .toList(),
      isRequired: true,
      order: requiredOptions.length,
    );
    requiredOptions.add(option);
    notifyListeners();
  }

  void addExtraOption(String name, List<String> choices) {
    final option = ProductOptionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: name,
      choices: choices
          .map((c) => OptionChoiceModel(name: c, price: 0))
          .toList(),
      isRequired: false,
      order: extraOptions.length,
    );
    extraOptions.add(option);
    notifyListeners();
  }

  void removeRequiredOption(int index) {
    if (index >= 0 && index < requiredOptions.length) {
      requiredOptions.removeAt(index);
      notifyListeners();
    }
  }

  void removeExtraOption(int index) {
    if (index >= 0 && index < extraOptions.length) {
      extraOptions.removeAt(index);
      notifyListeners();
    }
  }

  // New category
  void setNewCategoryName(String name) {
    newCategoryName = name;
    notifyListeners();
  }

  Future<String> addNewCategory() async {
    if (selectedStore == null) throw 'اختر المتجر أولاً';
    if (newCategoryName.isEmpty) throw 'اسم الفئة مطلوب';

    try {
      final categoryId = await ProductService.addCategory(
        selectedStore!.id,
        name: newCategoryName,
      );

      // إعادة تحميل الفئات
      await loadStoreCategories(selectedStore!.id);

      // تحديد الفئة الجديدة
      selectedCategory = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => categories.first,
      );

      newCategoryName = '';
      notifyListeners();
      return categoryId;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Validation
  bool get isFormValid {
    return selectedStore != null &&
        selectedCategory != null &&
        productName.isNotEmpty &&
        productPrice >= 1 &&
        productImage != null &&
        (!hasStockLimit || stockQuantity > 0) &&
        (!hasDiscount || discountValue >= 0) &&
        (!hasDiscount || (productPrice - discountValue) >= 1);
  }

  String? get validationError {
    if (selectedStore == null) return 'اختر المتجر أولاً';
    if (selectedCategory == null) return 'اختر الفئة أولاً';
    if (productName.isEmpty) return 'اسم المنتج مطلوب';
    if (productPrice < 1) return 'السعر يجب ألا يقل عن 1 جنيه';
    if (productImage == null) return 'الصورة مطلوبة';
    if (hasStockLimit && stockQuantity <= 0) return 'كمية المخزون غير صالحة';
    if (hasDiscount && discountValue < 0) return 'قيمة الخصم غير صالحة';
    if (hasDiscount && (productPrice - discountValue) < 1) {
      return 'السعر النهائي يجب ألا يقل عن 1 جنيه';
    }
    return null;
  }

  // Add product
  Future<String> addProduct() async {
    if (!isFormValid) {
      throw validationError ?? 'يرجى ملء جميع الحقول المطلوبة';
    }

    isAddingProduct = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final productId = await ProductService.addProduct(
        selectedStore!.id,
        selectedCategory!.id,
        name: productName,
        price: productPrice,
        stock: hasStockLimit ? stockQuantity : 0,
        description: productDescription.isNotEmpty ? productDescription : null,
        imageFile: productImage,
        hasStockLimit: hasStockLimit,
        hasDiscount: hasDiscount,
        discountValue: hasDiscount ? discountValue : null,
        finalPrice: finalPrice,
        requiredOptions: requiredOptions,
        extraOptions: extraOptions,
        endAt: hasEndDate ? endAt : null,
        status: status,
        inStock: inStock,
      );

      successMessage = 'تم إضافة المنتج بنجاح';
      _resetForm();
      notifyListeners();
      return productId;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      isAddingProduct = false;
      notifyListeners();
    }
  }

  // Reset form
  void _resetForm() {
    productName = '';
    productDescription = '';
    productPrice = 0;
    productStock = 0;
    productImage = null;
    hasStockLimit = false;
    stockQuantity = 0;
    hasDiscount = false;
    discountValue = 0;
    hasEndDate = false;
    endAt = null;
    status = true;
    inStock = true;
    requiredOptions = [];
    extraOptions = [];
    newCategoryName = '';
    notifyListeners();
  }

  // Clear messages
  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }
}
