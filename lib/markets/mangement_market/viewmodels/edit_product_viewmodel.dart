import 'dart:io';

import 'package:flutter/material.dart';

import '../../add_product/models/product_models.dart';
import '../../add_product/services/product_service.dart';

class EditProductViewModel extends ChangeNotifier {
  EditProductViewModel({
    required this.marketId,
    required ProductCategoryModel initialCategory,
    required ProductModel product,
  }) : _product = product,
       initialCategoryId = initialCategory.id,
       _currentCategoryId = initialCategory.id,
       selectedCategory = initialCategory {
    price = product.price;
    hasDiscount = product.hasDiscount;
    discountValue = product.discountValue ?? 0;
    hasStockLimit = product.hasStockLimit;
    stockQuantity = product.stock;
    status = product.status;
    inStock = product.inStock;
    endAt = product.endAt;
    hasEndDate = product.endAt != null;
    requiredOptionsEnabled = product.requiredOptions.isNotEmpty;
    extraOptionsEnabled = product.extraOptions.isNotEmpty;

    _seedOptionGroups();
  }

  final String marketId;
  final String initialCategoryId;

  ProductModel _product;
  ProductModel get product => _product;

  String _currentCategoryId;
  String get currentCategoryId => _currentCategoryId;

  List<ProductCategoryModel> categories = [];
  ProductCategoryModel? selectedCategory;

  bool isLoadingCategories = false;
  bool isSaving = false;

  String? errorMessage;
  String? successMessage;

  File? newImageFile;

  late num price;
  late bool hasDiscount;
  late num discountValue;
  late bool hasStockLimit;
  late int stockQuantity;
  late bool status;
  late bool inStock;
  late bool hasEndDate;
  DateTime? endAt;

  late bool requiredOptionsEnabled;
  late bool extraOptionsEnabled;

  final List<EditableOptionGroup> requiredOptionGroups = [];
  final List<EditableOptionGroup> extraOptionGroups = [];

  int _optionIdCounter = 0;
  int _choiceIdCounter = 0;

  num get finalPrice {
    final raw = hasDiscount ? (price - discountValue) : price;
    return raw < 1 ? 1 : raw;
  }

  Future<void> loadCategories() async {
    isLoadingCategories = true;
    notifyListeners();
    try {
      categories = await ProductService.getCategories(marketId);
      if (categories.isEmpty) {
        errorMessage = 'لا توجد فئات متاحة';
      } else {
        final currentId = selectedCategory?.id ?? initialCategoryId;
        selectedCategory = categories.firstWhere(
          (c) => c.id == currentId,
          orElse: () => categories.first,
        );
      }
    } catch (e) {
      errorMessage = 'خطأ في تحميل الفئات: $e';
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  void setSelectedCategoryById(String? id) {
    if (id == null) return;
    final found = categories.firstWhere(
      (c) => c.id == id,
      orElse: () => selectedCategory ?? categories.first,
    );
    selectedCategory = found;
    notifyListeners();
  }

  void setNewImage(File? file) {
    newImageFile = file;
    notifyListeners();
  }

  void setPrice(String raw) {
    final parsed = num.tryParse(raw.trim());
    if (parsed == null) return;
    price = parsed < 1 ? 1 : parsed;
    if (hasDiscount) {
      final maxAllowedDiscount = price - 1;
      if (discountValue > maxAllowedDiscount) {
        discountValue = maxAllowedDiscount < 0 ? 0 : maxAllowedDiscount;
      }
    }
    notifyListeners();
  }

  void toggleDiscount(bool value) {
    hasDiscount = value;
    if (!value) {
      discountValue = 0;
    }
    notifyListeners();
  }

  void setDiscountValue(String raw) {
    final parsed = num.tryParse(raw.trim());
    if (parsed == null) return;
    var val = parsed < 0 ? 0 : parsed;
    final maxAllowedDiscount = price - 1;
    if (val > maxAllowedDiscount) {
      val = maxAllowedDiscount < 0 ? 0 : maxAllowedDiscount;
    }
    discountValue = val;
    notifyListeners();
  }

  void setHasStockLimit(bool value) {
    hasStockLimit = value;
    if (!value) {
      stockQuantity = 0;
    } else if (stockQuantity <= 0) {
      stockQuantity = product.stock > 0 ? product.stock : 1;
    }
    notifyListeners();
  }

  void setStockQuantity(String raw) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) return;
    stockQuantity = parsed;
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

  void toggleRequiredOptions(bool value) {
    requiredOptionsEnabled = value;
    if (value && requiredOptionGroups.isEmpty) {
      _addBlankGroup(isRequired: true, notify: false);
    }
    notifyListeners();
  }

  void toggleExtraOptions(bool value) {
    extraOptionsEnabled = value;
    if (value && extraOptionGroups.isEmpty) {
      _addBlankGroup(isRequired: false, notify: false);
    }
    notifyListeners();
  }

  void addOptionGroup({required bool isRequired}) {
    _addBlankGroup(isRequired: isRequired);
  }

  void removeOptionGroup({required bool isRequired, required String groupId}) {
    final list = isRequired ? requiredOptionGroups : extraOptionGroups;
    final index = list.indexWhere((g) => g.id == groupId);
    if (index == -1) return;
    list.removeAt(index).dispose();
    notifyListeners();
  }

  void addChoice({required bool isRequired, required String groupId}) {
    final group = _findGroup(isRequired: isRequired, groupId: groupId);
    if (group == null) return;
    group.choices.add(
      EditableOptionChoice(id: _nextChoiceId(), name: '', price: 0),
    );
    notifyListeners();
  }

  void removeChoice({
    required bool isRequired,
    required String groupId,
    required String choiceId,
  }) {
    final group = _findGroup(isRequired: isRequired, groupId: groupId);
    if (group == null) return;
    final index = group.choices.indexWhere((c) => c.id == choiceId);
    if (index == -1) return;
    group.choices.removeAt(index).dispose();
    notifyListeners();
  }

  EditableOptionGroup? _findGroup({
    required bool isRequired,
    required String groupId,
  }) {
    final list = isRequired ? requiredOptionGroups : extraOptionGroups;
    final index = list.indexWhere((g) => g.id == groupId);
    if (index == -1) return null;
    return list[index];
  }

  Future<ProductModel?> submit({
    required String name,
    required String description,
  }) async {
    isSaving = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    final targetCategoryId = selectedCategory?.id ?? currentCategoryId;
    final movingCategory = targetCategoryId != currentCategoryId;

    final sanitizedDescription = description;
    final sanitizedStock = hasStockLimit ? stockQuantity : 0;
    final sanitizedDiscount = hasDiscount ? discountValue : 0;
    final sanitizedEndAt = hasEndDate ? endAt : null;

    final requiredOptions = requiredOptionsEnabled
        ? _collectOptionModels(requiredOptionGroups, isRequired: true)
        : <ProductOptionModel>[];
    final extraOptions = extraOptionsEnabled
        ? _collectOptionModels(extraOptionGroups, isRequired: false)
        : <ProductOptionModel>[];

    final updatedProduct = _product.copyWith(
      name: name,
      price: price,
      description: sanitizedDescription.isEmpty ? null : sanitizedDescription,
      stock: sanitizedStock,
      hasStockLimit: hasStockLimit,
      hasDiscount: hasDiscount,
      discountValue: hasDiscount ? sanitizedDiscount : 0,
      finalPrice: finalPrice,
      requiredOptions: requiredOptions,
      extraOptions: extraOptions,
      endAt: sanitizedEndAt,
      status: status,
      inStock: inStock,
    );

    try {
      if (movingCategory) {
        final moved = await ProductService.moveProduct(
          marketId: marketId,
          fromCategoryId: currentCategoryId,
          toCategoryId: targetCategoryId,
          updatedProduct: updatedProduct,
          imageFile: newImageFile,
        );
        _product = moved;
        _currentCategoryId = targetCategoryId;
      } else {
        await ProductService.updateProduct(
          marketId,
          targetCategoryId,
          updatedProduct.id,
          name: updatedProduct.name,
          price: updatedProduct.price,
          stock: sanitizedStock,
          description: sanitizedDescription,
          imageFile: newImageFile,
          hasStockLimit: updatedProduct.hasStockLimit,
          hasDiscount: updatedProduct.hasDiscount,
          discountValue: updatedProduct.hasDiscount ? sanitizedDiscount : 0,
          requiredOptions: requiredOptions,
          extraOptions: extraOptions,
          endAt: sanitizedEndAt,
          status: updatedProduct.status,
          inStock: updatedProduct.inStock,
        );
        final refreshed = await ProductService.getProduct(
          marketId,
          targetCategoryId,
          updatedProduct.id,
        );
        _product = refreshed ?? updatedProduct;
      }
      newImageFile = null;
      successMessage = 'تم حفظ التعديلات بنجاح';
      return _product;
    } catch (e) {
      errorMessage = 'تعذر حفظ التعديلات: $e';
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  void _seedOptionGroups() {
    if (_product.requiredOptions.isNotEmpty) {
      for (final option in _product.requiredOptions) {
        requiredOptionGroups.add(EditableOptionGroup.fromModel(option));
      }
    }
    if (_product.extraOptions.isNotEmpty) {
      for (final option in _product.extraOptions) {
        extraOptionGroups.add(EditableOptionGroup.fromModel(option));
      }
    }
  }

  void _addBlankGroup({required bool isRequired, bool notify = true}) {
    final group = EditableOptionGroup(
      id: _nextOptionId(),
      isRequired: isRequired,
      title: '',
      choices: [EditableOptionChoice(id: _nextChoiceId(), name: '', price: 0)],
    );
    if (isRequired) {
      requiredOptionGroups.add(group);
    } else {
      extraOptionGroups.add(group);
    }
    if (notify) notifyListeners();
  }

  List<ProductOptionModel> _collectOptionModels(
    List<EditableOptionGroup> groups, {
    required bool isRequired,
  }) {
    final models = <ProductOptionModel>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      final title = group.titleController.text.trim();
      final choices = <OptionChoiceModel>[];
      for (final choice in group.choices) {
        final name = choice.nameController.text.trim();
        if (name.isEmpty) continue;
        final priceText = choice.priceController.text.trim();
        final price = num.tryParse(priceText.isEmpty ? '0' : priceText) ?? 0;
        choices.add(choice.toModel(price: price));
      }
      if (title.isEmpty && choices.isEmpty) continue;
      models.add(
        ProductOptionModel(
          id: group.id,
          title: title,
          choices: choices,
          isRequired: isRequired,
          order: i,
        ),
      );
    }
    return models;
  }

  String _nextOptionId() =>
      'opt-${DateTime.now().microsecondsSinceEpoch}-${_optionIdCounter++}';

  String _nextChoiceId() =>
      'choice-${DateTime.now().microsecondsSinceEpoch}-${_choiceIdCounter++}';

  @override
  void dispose() {
    for (final group in requiredOptionGroups) {
      group.dispose();
    }
    for (final group in extraOptionGroups) {
      group.dispose();
    }
    super.dispose();
  }
}

class EditableOptionGroup {
  EditableOptionGroup({
    required this.id,
    required this.isRequired,
    required String title,
    List<EditableOptionChoice>? choices,
  }) : titleController = TextEditingController(text: title),
       choices = choices ?? [];

  factory EditableOptionGroup.fromModel(ProductOptionModel model) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    var index = 0;
    return EditableOptionGroup(
      id: model.id,
      isRequired: model.isRequired,
      title: model.title,
      choices: model.choices
          .map(
            (choice) => EditableOptionChoice(
              id: 'existing-$timestamp-${index++}',
              name: choice.name,
              price: choice.price,
            ),
          )
          .toList(),
    );
  }

  final String id;
  final bool isRequired;
  final TextEditingController titleController;
  final List<EditableOptionChoice> choices;

  void dispose() {
    titleController.dispose();
    for (final choice in choices) {
      choice.dispose();
    }
  }
}

class EditableOptionChoice {
  EditableOptionChoice({
    required this.id,
    required String name,
    required num price,
  }) : nameController = TextEditingController(text: name),
       priceController = TextEditingController(
         text: price == 0 ? '' : price.toString(),
       );

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;

  OptionChoiceModel toModel({required num price}) {
    return OptionChoiceModel(name: nameController.text.trim(), price: price);
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}
