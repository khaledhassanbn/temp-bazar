import 'package:flutter/material.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import 'package:bazar_suez/theme/app_color.dart';

class SaveButtonSection extends StatelessWidget {
  final EditStoreViewModel viewModel;
  final GlobalKey<FormState> formKey;
  final String storeId;

  const SaveButtonSection({
    Key? key,
    required this.viewModel,
    required this.formKey,
    required this.storeId,
  }) : super(key: key);

  Future<void> _handleSave(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء استكمال جميع الحقول المطلوبة')),
      );
      return;
    }

    if (viewModel.location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار موقع المتجر على الخريطة')),
      );
      return;
    }

    try {
      await viewModel.updateStore(storeId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التعديلات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ التعديلات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: ElevatedButton(
        onPressed: viewModel.loading ? null : () => _handleSave(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: viewModel.loading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('حفظ التعديلات'),
      ),
    );
  }
}
