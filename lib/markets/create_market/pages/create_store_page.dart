import 'dart:io';
import 'package:bazar_suez/widgets/app_field.dart';
import 'package:bazar_suez/widgets/store_link_field.dart';
import 'package:bazar_suez/widgets/custom_back_button.dart';
import 'package:bazar_suez/widgets/category_selector.dart';
import 'package:bazar_suez/widgets/working_hours_selector.dart';
import 'package:bazar_suez/widgets/primary_button.dart'; // ✅ زرار موحد
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/create_store_viewmodel.dart';
import '../../planes/services/pending_payment_service.dart';
import 'map_picker_page.dart';
import '../../../theme/app_color.dart';

//enum StoreType { onlineOnly, withLocation }

class CreateStoreModernPage extends StatefulWidget {
  final int? numberOfProducts;
  final String? selectedDuration;
  final String? packageId;
  final int? days;

  const CreateStoreModernPage({
    Key? key,
    this.numberOfProducts,
    this.selectedDuration,
    this.packageId,
    this.days,
  }) : super(key: key);

  @override
  State<CreateStoreModernPage> createState() => _CreateStoreModernPageState();
}

class _CreateStoreModernPageState extends State<CreateStoreModernPage> {
  final _formKey = GlobalKey<FormState>();
  // StoreType _storeType = StoreType.onlineOnly;
  bool _showAddress = false;
  bool _isPickingImage = false; // guard to prevent multiple pickers
  final PendingPaymentService _pendingPaymentService = PendingPaymentService();

  final _arabicEnglishFormatter = FilteringTextInputFormatter.allow(
    RegExp(
      r'[A-Za-z\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF0-9\s]',
    ),
  );

  @override
  void initState() {
    super.initState();
    _checkPendingPayment();
  }

  Future<void> _checkPendingPayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pendingPayment = await _pendingPaymentService.getPendingPayment(
      user.uid,
    );
    // لا نعرض dialog هنا لتجنب loading مزدوج
    // البيانات ستُستخدم تلقائياً عند إنشاء المتجر
    if (pendingPayment != null && pendingPayment.isValid && mounted) {
      // تحديث packageId و days في ViewModel إذا لم تكن موجودة
      // ننتظر حتى يتم بناء Provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            final viewModel = Provider.of<CreateStoreViewModel>(
              context,
              listen: false,
            );
            if (viewModel.packageId == null &&
                pendingPayment.packageId.isNotEmpty) {
              viewModel.packageId = pendingPayment.packageId;
            }
            if (viewModel.packageDays == null && pendingPayment.days > 0) {
              viewModel.packageDays = pendingPayment.days;
            }
          } catch (e) {
            // Provider غير جاهز بعد، سيتم تحديث البيانات لاحقاً
            print('Provider not ready yet: $e');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE0F2F1);

    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = CreateStoreViewModel();
        if (widget.numberOfProducts != null &&
            widget.selectedDuration != null) {
          viewModel.setPlanData(
            widget.numberOfProducts!,
            widget.selectedDuration!,
          );
        }
        // حفظ packageId و days للاستخدام لاحقاً
        if (widget.packageId != null) {
          viewModel.packageId = widget.packageId;
        }
        if (widget.days != null) {
          viewModel.packageDays = widget.days;
        }
        return viewModel;
      },
      child: Consumer<CreateStoreViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ✅ الهيدر
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(60),
                        ),
                      ),
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(16),
                      child: const CustomBackButton(),
                    ),

                    // ✅ الجسم الأبيض
                    Transform.translate(
                      offset: const Offset(0, -50),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                "إنشاء متجر",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mainColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // ✅ اللوجو
                              GestureDetector(
                                onTap: () async {
                                  if (_isPickingImage || vm.loading) return;
                                  _isPickingImage = true;
                                  try {
                                    final XFile? f = await ImagePicker()
                                        .pickImage(
                                          source: ImageSource.gallery,
                                          imageQuality: 80,
                                        );
                                    if (f != null) vm.setLogo(File(f.path));
                                  } on PlatformException catch (e) {
                                    if (e.code != 'already_active') {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'حدث خطأ أثناء اختيار الصورة: ${e.message ?? e.code}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } finally {
                                    _isPickingImage = false;
                                  }
                                },
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: AppColors.mainColor
                                      .withOpacity(0.2),
                                  backgroundImage: vm.logoFile != null
                                      ? FileImage(vm.logoFile!)
                                      : null,
                                  child: vm.logoFile == null
                                      ? const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white70,
                                          size: 30,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ✅ الحقول
                              AppTextField(
                                label: "اسم المتجر",
                                hint: "متجر السعادة",
                                required: true,
                                inputFormatters: [_arabicEnglishFormatter],
                                onChanged: vm.setName,
                              ),
                              AppTextField(
                                label: "وصف المتجر",
                                hint: "لا يتعدى 30 حرف",
                                maxLength: 30,
                                required: true,
                                inputFormatters: [_arabicEnglishFormatter],
                                onChanged: vm.setDescription,
                              ),

                              CategorySelector(
                                selectedCategoryId: vm.selectedCategoryId,
                                selectedSubCategory: vm.selectedSubCategoryId,
                                onCategoryChanged: (id, nameAr) =>
                                    vm.setSelectedCategory(
                                      id,
                                      categoryNameAr: nameAr,
                                    ),
                                onSubCategoryChanged: (id, nameAr) =>
                                    vm.setSelectedSubCategory(
                                      id,
                                      subCategoryNameAr: nameAr,
                                    ),
                                required: true,
                                categoryLabel: "الفئة الرئيسية",
                                subCategoryLabel: "التصنيف الفرعي",
                              ),

                              StoreLinkField(onChanged: vm.setLink),

                              WorkingHoursSelector(
                                initialWorkingHours: vm.workingHours,
                                onChanged: vm.setWorkingHours,
                                required: false,
                              ),
                              const SizedBox(height: 16),

                              AppTextField(
                                label: "رقم الهاتف (واتساب)",
                                hint: "+20...",
                                keyboardType: TextInputType.phone,
                                required: true,
                                onChanged: vm.setPhone,
                              ),
                              AppTextField(
                                label: "فيسبوك",
                                hint: "https://facebook.com/...",
                                onChanged: vm.setFacebook,
                              ),
                              AppTextField(
                                label: "انستجرام",
                                hint: "https://instagram.com/...",
                                onChanged: vm.setInstagram,
                              ),
                              const SizedBox(height: 16),

                              // ✅ اختيار نوع المتجر
                              // Align(
                              //   alignment: Alignment.centerRight,
                              //   child: Column(
                              //     children: [
                              //       RadioListTile<StoreType>(
                              //         title: const Text("متجر أونلاين فقط"),
                              //         value: StoreType.onlineOnly,
                              //         groupValue: _storeType,
                              //         activeColor: AppColors.mainColor,
                              //         onChanged: (val) {
                              //           setState(() {
                              //             _storeType = val!;
                              //             vm.setLocation(null);
                              //           });
                              //         },
                              //       ),
                              //       RadioListTile<StoreType>(
                              //         title: const Text(
                              //           "حدد مكان متجرك على الخريطة",
                              //         ),
                              //         value: StoreType.withLocation,
                              //         groupValue: _storeType,
                              //         activeColor: AppColors.mainColor,
                              //         onChanged: (val) {
                              //           setState(() {
                              //             _storeType = val!;
                              //           });
                              //         },
                              //       ),
                              //     ],
                              //   ),
                              // ),

                              // if (_storeType == StoreType.withLocation)
                              PrimaryButton(
                                text: vm.location == null
                                    ? "اختر الموقع من الخريطة"
                                    : "تم اختيار موقع",
                                isLoading: false,
                                onPressed: () async {
                                  final LatLng? picked =
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const MapPickerPage(),
                                        ),
                                      );
                                  if (picked != null) {
                                    vm.setLocation(picked);
                                  }
                                },
                              ),
                              SwitchListTile(
                                title: const Text("إظهار العنوان على الصفحة"),
                                value: _showAddress,
                                onChanged: (bool value) {
                                  setState(() {
                                    _showAddress = value;
                                  });
                                  vm.setShowAddress(value);
                                },
                                activeColor: AppColors.mainColor,
                              ),
                              const SizedBox(height: 24),

                              // ✅ زرار إنشاء المتجر
                              PrimaryButton(
                                text: "إنشاء المتجر",
                                isLoading: vm.loading,
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate()) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'الرجاء استكمال جميع الحقول المطلوبة',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  // Enforce picking a logo image from the phone
                                  if (vm.logoFile == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'الرجاء اختيار صورة للمتجر',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (vm.location == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'الرجاء اختيار موقع المتجر على الخريطة',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    await vm.createStore(DateTime.now());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تم إنشاء المتجر بنجاح'),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'حدث خطأ أثناء إنشاء المتجر: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
