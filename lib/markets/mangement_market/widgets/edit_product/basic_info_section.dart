import 'package:flutter/material.dart';

import '../../../../widgets/app_field.dart';
import '../../viewmodels/edit_product_viewmodel.dart';
import 'section_container.dart';

class EditProductBasicInfoSection extends StatelessWidget {
  const EditProductBasicInfoSection({
    super.key,
    required this.viewModel,
    required this.nameController,
    required this.descriptionController,
  });

  final EditProductViewModel viewModel;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return EditSectionContainer(
      icon: Icons.shopping_bag_outlined,
      title: 'معلومات المنتج الأساسية',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: nameController,
            label: 'اسم المنتج',
            hint: 'أدخل اسم المنتج',
            required: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: descriptionController,
            label: 'وصف المنتج',
            hint: 'اكتب وصفاً جذاباً',
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
