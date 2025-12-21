import 'package:flutter/material.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import 'package:bazar_suez/widgets/working_hours_selector.dart';

class WorkingHoursSection extends StatelessWidget {
  final EditStoreViewModel viewModel;

  const WorkingHoursSection({Key? key, required this.viewModel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: WorkingHoursSelector(
        initialWorkingHours: viewModel.workingHours,
        onChanged: viewModel.setWorkingHours,
        required: false,
      ),
    );
  }
}
