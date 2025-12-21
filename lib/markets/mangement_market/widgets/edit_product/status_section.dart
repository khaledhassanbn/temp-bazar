import 'package:flutter/material.dart';

import '../../../../theme/app_color.dart';
import '../../viewmodels/edit_product_viewmodel.dart';
import 'section_container.dart';

class EditProductStatusSection extends StatelessWidget {
  const EditProductStatusSection({
    super.key,
    required this.viewModel,
    required this.onRequestEndDate,
  });

  final EditProductViewModel viewModel;
  final VoidCallback onRequestEndDate;

  @override
  Widget build(BuildContext context) {
    return EditSectionContainer(
      icon: Icons.toggle_on_outlined,
      title: 'حالة المنتج',
      subtitle: 'تحكم في ظهور المنتج وتوفّره وتاريخ انتهائه',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: viewModel.status,
            onChanged: viewModel.isSaving ? null : viewModel.setStatus,
            activeColor: AppColors.mainColor,
            title: const Text(
              'المنتج مفعل',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: viewModel.inStock,
            onChanged: viewModel.isSaving ? null : viewModel.setInStock,
            activeColor: AppColors.mainColor,
            title: const Text(
              'المنتج متاح للبيع',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: viewModel.hasEndDate,
            onChanged: viewModel.isSaving
                ? null
                : (val) {
                    viewModel.setHasEndDate(val);
                    if (val) onRequestEndDate();
                  },
            activeColor: AppColors.mainColor,
            title: const Text(
              'تحديد تاريخ انتهاء',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (viewModel.hasEndDate)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                viewModel.endAt != null
                    ? _formatDateTime(viewModel.endAt!)
                    : 'لم يتم اختيار تاريخ',
              ),
              trailing: TextButton(
                onPressed: viewModel.isSaving ? null : onRequestEndDate,
                child: const Text('تغيير التاريخ'),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}/${two(date.month)}/${two(date.day)} - ${two(date.hour)}:${two(date.minute)}';
  }
}
