import 'package:flutter/material.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import 'section_title_widget.dart';

class StoreLinkSection extends StatelessWidget {
  final EditStoreViewModel viewModel;

  const StoreLinkSection({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitleWidget(title: 'لينك المتجر'),
        TextFormField(
          enabled: false,
          initialValue: viewModel.link,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
