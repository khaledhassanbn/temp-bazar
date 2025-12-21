import 'package:flutter/material.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import 'package:bazar_suez/widgets/category_selector.dart';

class CategorySection extends StatelessWidget {
  final EditStoreViewModel viewModel;

  const CategorySection({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: CategorySelector(
        selectedCategoryId: viewModel.selectedCategoryId,
        selectedSubCategory: viewModel.selectedSubCategoryId,
        onCategoryChanged: (id, nameAr) =>
            viewModel.setSelectedCategory(id, categoryNameAr: nameAr),
        onSubCategoryChanged: (id, nameAr) =>
            viewModel.setSelectedSubCategory(id, subCategoryNameAr: nameAr),
        required: true,
        categoryLabel: 'الفئة الرئيسية',
        subCategoryLabel: 'التصنيف الفرعي',
      ),
    );
  }
}
