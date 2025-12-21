import 'package:flutter/material.dart';
import '../Model/model.dart';
import '../service/service.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _service.getMainCategories();

    _isLoading = false;
    notifyListeners();
  }
}
