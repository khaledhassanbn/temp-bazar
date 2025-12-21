import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_color.dart';
import '../viewmodels/request_ads_viewmodel.dart';
import '../widgets/loading_snackbar.dart';

class RequestAdsPage extends StatelessWidget {
  const RequestAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RequestAdsViewModel()..loadUserStores(),
      child: const _RequestAdsView(),
    );
  }
}

class _RequestAdsView extends StatefulWidget {
  const _RequestAdsView();

  @override
  State<_RequestAdsView> createState() => _RequestAdsViewState();
}

class _RequestAdsViewState extends State<_RequestAdsView> {
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _daysController.addListener(_onDaysChanged);
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _daysController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onDaysChanged() {
    final viewModel = context.read<RequestAdsViewModel>();
    final days = int.tryParse(_daysController.text) ?? 0;
    viewModel.setDays(days);
  }

  void _onPhoneChanged() {
    final viewModel = context.read<RequestAdsViewModel>();
    viewModel.setPhoneNumber(_phoneController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'طلب إعلان',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
          elevation: 0,
        ),
        body: Consumer<RequestAdsViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoadingStores) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LoadingSnackBar.showError(context, viewModel.errorMessage!);
                viewModel.clearError();
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // صورة الإعلان
                  const Text(
                    'صورة الإعلان',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => viewModel.pickImage(),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: viewModel.selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                viewModel.selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'اضغط لاختيار صورة',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // اختيار المتجر
                  const Text(
                    'اختر المتجر',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    value: viewModel.selectedStore,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: viewModel.userStores.map((store) {
                      return DropdownMenuItem(
                        value: store,
                        child: Text(store.name),
                      );
                    }).toList(),
                    onChanged: (value) => viewModel.setSelectedStore(value),
                    hint: const Text('اختر متجر'),
                  ),

                  const SizedBox(height: 24),

                  // عدد الأيام
                  const Text(
                    'عدد الأيام',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'مثال: 7',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'السعر: 70 جنيه في اليوم',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  // السعر النهائي
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.mainColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'السعر النهائي',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${viewModel.totalPrice.toStringAsFixed(0)} جنيه',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // رقم الهاتف
                  const Text(
                    'رقم الهاتف للتواصل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'مثال: 01234567890',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // زر متابعة الدفع
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _handleSubmitRequest(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'متابعة الدفع',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleSubmitRequest(BuildContext context) async {
    final viewModel = context.read<RequestAdsViewModel>();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الدفع'),
        content: Text(
          'هل أنت متأكد من خصم ${viewModel.totalPrice.toStringAsFixed(0)} جنيه من محفظتك؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
            ),
            child: const Text('موافق'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await viewModel.submitRequest();

    if (!mounted) return;

    if (result['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('تم الإرسال بنجاح'),
          content: const Text('تم إرسال الطلب وسوف يتم عرض إعلانك خلال دقائق'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/HomePage');
              },
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
    } else {
      final insufficientBalance = result['insufficientBalance'] == true;

      if (insufficientBalance) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('رصيد غير كافٍ'),
            content: const Text('رصيدك غير كافٍ'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/wallet');
                },
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      } else {
        LoadingSnackBar.showError(
          context,
          viewModel.errorMessage ?? 'فشل إرسال الطلب. يرجى المحاولة مرة أخرى',
        );
      }
    }
  }
}
