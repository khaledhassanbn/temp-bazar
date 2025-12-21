import 'package:flutter/material.dart';

import '../../../../theme/app_color.dart';
import '../../../../widgets/app_field.dart';
import '../../viewmodels/edit_product_viewmodel.dart';
import 'section_container.dart';

class EditProductInventorySection extends StatelessWidget {
  const EditProductInventorySection({
    super.key,
    required this.viewModel,
    required this.stockController,
  });

  final EditProductViewModel viewModel;
  final TextEditingController stockController;

  @override
  Widget build(BuildContext context) {
    return EditSectionContainer(
      icon: Icons.inventory_2_outlined,
      title: 'المخزون',
      subtitle: 'حدد كمية المنتج المتاحة والقيود المرتبطة بها',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: viewModel.hasStockLimit,
            onChanged: viewModel.isSaving
                ? null
                : (val) {
                    viewModel.setHasStockLimit(val);
                    if (val) {
                      stockController.text = viewModel.stockQuantity.toString();
                    } else {
                      stockController.clear();
                    }
                  },
            activeColor: AppColors.mainColor,
            title: const Text(
              'تحديد حد للمخزون',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (viewModel.hasStockLimit)
            AppTextField(
              controller: stockController,
              label: 'الكمية المتاحة',
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: viewModel.setStockQuantity,
            ),
        ],
      ),
    );
  }
}
