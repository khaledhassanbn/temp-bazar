import 'package:flutter/material.dart';

import '../../viewmodels/edit_product_viewmodel.dart';
import 'section_container.dart';

class EditProductCategorySection extends StatelessWidget {
  const EditProductCategorySection({super.key, required this.viewModel});

  final EditProductViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final categories = viewModel.categories;

    return EditSectionContainer(
      icon: Icons.category_outlined,
      title: 'الفئة',
      subtitle: 'يمكنك نقل المنتج إلى فئة أخرى في أي وقت',
      child: viewModel.isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : categories.isEmpty
          ? const Text(
              'لم يتم العثور على فئات. أضف فئة جديدة أولاً.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            )
          : DropdownButtonFormField<String>(
              value: viewModel.selectedCategory?.id,
              items: categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ),
                  )
                  .toList(),
              onChanged: viewModel.isSaving
                  ? null
                  : (value) => viewModel.setSelectedCategoryById(value),
              decoration: InputDecoration(
                labelText: 'اختر الفئة',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
    );
  }
}
