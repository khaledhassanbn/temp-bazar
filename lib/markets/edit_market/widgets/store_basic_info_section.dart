import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import 'section_title_widget.dart';
import 'edit_text_field.dart';

class StoreBasicInfoSection extends StatelessWidget {
  final EditStoreViewModel viewModel;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const StoreBasicInfoSection({
    Key? key,
    required this.viewModel,
    required this.nameController,
    required this.descriptionController,
  }) : super(key: key);

  static final _arabicEnglishFormatter = FilteringTextInputFormatter.allow(
    RegExp(
      r'[A-Za-z\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF0-9\s]',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitleWidget(title: 'اسم المتجر'),
        EditTextField(
          hint: 'متجر السعادة',
          required: true,
          inputFormatters: [_arabicEnglishFormatter],
          controller: nameController,
          onChanged: viewModel.setName,
        ),
        SectionTitleWidget(title: 'وصف المتجر'),
        EditTextField(
          hint: 'لا يتعدى 30 حرف',
          maxLength: 30,
          required: true,
          inputFormatters: [_arabicEnglishFormatter],
          controller: descriptionController,
          onChanged: viewModel.setDescription,
        ),
      ],
    );
  }
}
