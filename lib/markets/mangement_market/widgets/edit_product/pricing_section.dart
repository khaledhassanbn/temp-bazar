import 'package:flutter/material.dart';

import '../../../../theme/app_color.dart';
import '../../../../widgets/app_field.dart';
import '../../viewmodels/edit_product_viewmodel.dart';
import 'section_container.dart';

class EditProductPricingSection extends StatelessWidget {
  const EditProductPricingSection({
    super.key,
    required this.viewModel,
    required this.priceController,
    required this.discountController,
  });

  final EditProductViewModel viewModel;
  final TextEditingController priceController;
  final TextEditingController discountController;

  @override
  Widget build(BuildContext context) {
    return EditSectionContainer(
      icon: Icons.attach_money,
      title: 'التسعير والخصومات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: priceController,
            label: 'السعر',
            hint: '0',
            keyboardType: TextInputType.number,
            onChanged: viewModel.setPrice,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            value: viewModel.hasDiscount,
            onChanged: viewModel.isSaving
                ? null
                : (val) {
                    viewModel.toggleDiscount(val);
                    if (val) {
                      discountController.text = viewModel.discountValue
                          .toString();
                    } else {
                      discountController.clear();
                    }
                  },
            activeColor: AppColors.mainColor,
            title: const Text(
              'تفعيل خصم',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (viewModel.hasDiscount) ...[
            AppTextField(
              controller: discountController,
              label: 'قيمة الخصم',
              hint: '0',
              keyboardType: TextInputType.number,
              onChanged: viewModel.setDiscountValue,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mainColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mainColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: AppColors.mainColor),
                  const SizedBox(width: 12),
                  Text(
                    'السعر بعد الخصم: ${viewModel.finalPrice.toStringAsFixed(0)} جنيه',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
