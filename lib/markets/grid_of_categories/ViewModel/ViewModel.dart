import 'package:flutter/material.dart';
import '../Model/model.dart';
import '../service/service.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;

  Future<void> fetchCategories({bool force = false}) async {
    if (_hasLoaded && !force) return; // خلاص محملة من قبل

    _isLoading = true;
    notifyListeners();

    _categories = await _service.getMainCategories();

    _hasLoaded = true;
    _isLoading = false;
    notifyListeners();
  }
}
