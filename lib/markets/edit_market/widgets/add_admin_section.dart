import 'package:flutter/material.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import 'section_title_widget.dart';
import 'edit_text_field.dart';
import 'package:bazar_suez/theme/app_color.dart';

class AddAdminSection extends StatelessWidget {
  final EditStoreViewModel viewModel;
  final TextEditingController adminEmailController;
  final String storeId;

  const AddAdminSection({
    Key? key,
    required this.viewModel,
    required this.adminEmailController,
    required this.storeId,
  }) : super(key: key);

  Future<void> _handleAddAdmin(BuildContext context) async {
    if (adminEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني')),
      );
      return;
    }

    try {
      final message = await viewModel.addAdmin(storeId);
      adminEmailController.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitleWidget(title: 'إضافة مدير جديد'),
        EditTextField(
          hint: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          required: false,
          controller: adminEmailController,
          onChanged: viewModel.setAdminEmail,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: viewModel.addingAdmin
                  ? null
                  : () => _handleAddAdmin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: AppColors.mainColor, width: 1.5),
                ),
              ),
              child: viewModel.addingAdmin
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.mainColor,
                      ),
                    )
                  : const Text('إضافة مدير'),
            ),
          ),
        ),
      ],
    );
  }
}
