import 'package:flutter/material.dart';

import '../../../../theme/app_color.dart';
import '../../../../widgets/app_field.dart';
import '../../viewmodels/edit_product_viewmodel.dart';
import 'section_container.dart';

class EditProductOptionsSection extends StatelessWidget {
  const EditProductOptionsSection({
    super.key,
    required this.viewModel,
    required this.isRequired,
  });

  final EditProductViewModel viewModel;
  final bool isRequired;

  bool get _enabled => isRequired
      ? viewModel.requiredOptionsEnabled
      : viewModel.extraOptionsEnabled;

  List<EditableOptionGroup> get _groups =>
      isRequired ? viewModel.requiredOptionGroups : viewModel.extraOptionGroups;

  @override
  Widget build(BuildContext context) {
    final title = isRequired
        ? 'الأسئلة المطلوبة'
        : 'الأسئلة الإضافية (اختيارية)';
    final subtitle = isRequired
        ? 'يجب على العميل الإجابة عن سؤال واحد على الأقل'
        : 'يمكن للعميل تخطي هذه الأسئلة';
    final icon = isRequired
        ? Icons.feed_outlined
        : Icons.playlist_add_check_outlined;

    return EditSectionContainer(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: _enabled,
            onChanged: viewModel.isSaving
                ? null
                : (val) {
                    if (isRequired) {
                      viewModel.toggleRequiredOptions(val);
                    } else {
                      viewModel.toggleExtraOptions(val);
                    }
                  },
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.mainColor,
            title: const Text(
              'تفعيل هذه المجموعة من الأسئلة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (_enabled) ...[
            const SizedBox(height: 12),
            if (_groups.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'لا توجد أسئلة حتى الآن، قم بإضافة سؤال جديد.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            if (_groups.isNotEmpty)
              ..._groups.map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _OptionGroupCard(
                    viewModel: viewModel,
                    group: group,
                    isRequired: isRequired,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: viewModel.isSaving
                    ? null
                    : () => viewModel.addOptionGroup(isRequired: isRequired),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'إضافة سؤال جديد',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionGroupCard extends StatelessWidget {
  const _OptionGroupCard({
    required this.viewModel,
    required this.group,
    required this.isRequired,
  });

  final EditProductViewModel viewModel;
  final EditableOptionGroup group;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: group.titleController,
            label: 'عنوان السؤال',
            hint: 'مثال: اختر الحجم المناسب',
          ),
          const SizedBox(height: 12),
          Column(
            children: group.choices
                .map(
                  (choice) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: _ChoiceRow(
                      viewModel: viewModel,
                      group: group,
                      choice: choice,
                      isRequired: isRequired,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: viewModel.isSaving
                    ? null
                    : () => viewModel.addChoice(
                        isRequired: isRequired,
                        groupId: group.id,
                      ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة خيار',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainColor,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: viewModel.isSaving
                    ? null
                    : () => viewModel.removeOptionGroup(
                        isRequired: isRequired,
                        groupId: group.id,
                      ),
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  'حذف السؤال',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.viewModel,
    required this.group,
    required this.choice,
    required this.isRequired,
  });

  final EditProductViewModel viewModel;
  final EditableOptionGroup group;
  final EditableOptionChoice choice;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            controller: choice.nameController,
            label: 'اسم الخيار',
            hint: 'مثال: حجم كبير',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            controller: choice.priceController,
            label: 'سعر الخيار',
            hint: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.redAccent),
          onPressed: viewModel.isSaving
              ? null
              : () => viewModel.removeChoice(
                  isRequired: isRequired,
                  groupId: group.id,
                  choiceId: choice.id,
                ),
          tooltip: 'حذف الخيار',
        ),
      ],
    );
  }
}
