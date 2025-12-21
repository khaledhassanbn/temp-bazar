import 'package:flutter/material.dart';
import '../viewmodels/edit_store_viewmodel.dart';

class AddressToggleSection extends StatelessWidget {
  final EditStoreViewModel viewModel;
  final bool showAddress;
  final ValueChanged<bool> onChanged;

  const AddressToggleSection({
    Key? key,
    required this.viewModel,
    required this.showAddress,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: SwitchListTile.adaptive(
        title: const Text('إظهار العنوان على الصفحة'),
        value: showAddress,
        onChanged: (bool value) {
          onChanged(value);
          viewModel.setShowAddress(value);
        },
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
