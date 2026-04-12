import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import '../widgets/cover_image_widget.dart';
import '../widgets/logo_avatar_widget.dart';
import '../widgets/working_hours_section.dart';
import '../widgets/contact_info_section.dart';
import '../widgets/location_section.dart';
import '../widgets/address_toggle_section.dart';
import '../../../theme/app_color.dart';

class EditStorePage extends StatefulWidget {
  final String storeId;

  const EditStorePage({Key? key, required this.storeId}) : super(key: key);

  @override
  State<EditStorePage> createState() => _EditStorePageState();
}

class _EditStorePageState extends State<EditStorePage> {
  final _formKey = GlobalKey<FormState>();
  bool _showAddress = false;
  bool _isPickingImage = false;
  final _adminEmailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  bool _controllersInitialized = false;

  void _initializeControllers(EditStoreViewModel vm) {
    if (!_controllersInitialized && !vm.loading && vm.name.isNotEmpty) {
      _descriptionController.text = vm.description;
      _phoneController.text = vm.phone;
      _facebookController.text = vm.facebook;
      _instagramController.text = vm.instagram;
      _adminEmailController.clear();
      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = EditStoreViewModel();
        vm.loadStoreData(widget.storeId).catchError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ في تحميل بيانات المتجر: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
        return vm;
      },
      child: Consumer<EditStoreViewModel>(
        builder: (context, vm, _) {
          if (vm.showAddress != _showAddress && !vm.loading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showAddress = vm.showAddress);
            });
          }
          _initializeControllers(vm);

          return WillPopScope(
            onWillPop: () async {
              _handleBackNavigation();
              return false;
            },
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F7FB),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                leading: IconButton(
                  onPressed: _handleBackNavigation,
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: AppColors.mainColor,
                ),
                title: const Text(
                  'تعديل المتجر',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.mainColor,
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: vm.loading ? null : () => _handleSave(vm),
                    icon: vm.loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.mainColor,
                            ),
                          )
                        : const Icon(Icons.done_all_rounded),
                    label: const Text('حفظ'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mainColor,
                    ),
                  ),
                ],
              ),
              body: SafeArea(
                top: false,
                child: vm.loading && vm.name.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : CustomScrollView(
                        slivers: [
                          // Cover + Avatar
                          SliverToBoxAdapter(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CoverImageWidget(
                                  viewModel: vm,
                                  onCoverSelected: (file) {
                                    setState(() => _isPickingImage = true);
                                    vm.setCover(file);
                                    setState(() => _isPickingImage = false);
                                  },
                                  isPickingImage: _isPickingImage,
                                ),
                                LogoAvatarWidget(
                                  viewModel: vm,
                                  onLogoSelected: (file) {
                                    setState(() => _isPickingImage = true);
                                    vm.setLogo(file);
                                    setState(() => _isPickingImage = false);
                                  },
                                  isPickingImage: _isPickingImage,
                                ),
                              ],
                            ),
                          ),

                          // Spacer to accommodate avatar overlap
                          const SliverToBoxAdapter(child: SizedBox(height: 40)),

                          // Content
                          SliverToBoxAdapter(
                            child: Form(
                              key: _formKey,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _statusCard(vm),
                                    const SizedBox(height: 12),

                                    _sectionCard(
                                      title: 'معلومات المتجر',
                                      child: Column(
                                        children: [
                                          _readOnlyRow('اسم المتجر', vm.name),
                                          const SizedBox(height: 10),
                                          _readOnlyRow(
                                            'الفئة',
                                            vm.selectedCategoryNameAr ?? '--',
                                          ),
                                          const SizedBox(height: 10),
                                          _readOnlyRow('لينك المتجر', vm.link),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'وصف المتجر',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TextFormField(
                                            controller: _descriptionController,
                                            textAlign: TextAlign.right,
                                            maxLength: 30,
                                            decoration: _inputDecoration(
                                              hint: 'وصف المتجر',
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'هذا الحقل مطلوب';
                                              }
                                              return null;
                                            },
                                            onChanged: vm.setDescription,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    _sectionCard(
                                      title: 'مواعيد العمل',
                                      child: WorkingHoursSection(viewModel: vm),
                                    ),
                                    const SizedBox(height: 12),

                                    _sectionCard(
                                      title: 'الاتصال والتواصل',
                                      child: ContactInfoSection(
                                        viewModel: vm,
                                        phoneController: _phoneController,
                                        facebookController: _facebookController,
                                        instagramController:
                                            _instagramController,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    _sectionCard(
                                      title: 'الموقع والعنوان',
                                      child: Column(
                                        children: [
                                          LocationSection(viewModel: vm),
                                          AddressToggleSection(
                                            viewModel: vm,
                                            showAddress: _showAddress,
                                            onChanged: (value) {
                                              setState(
                                                () => _showAddress = value,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    _adminsSection(vm),
                                    const SizedBox(height: 22),
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

  void _handleBackNavigation() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go('/HomePage');
  }

  Future<void> _handleSave(EditStoreViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) {
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
      await viewModel.updateStore(widget.storeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التعديلات بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      final navigator = Navigator.of(context);
      context.go('/HomePage');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ التعديلات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _statusCard(EditStoreViewModel vm) {
    return _sectionCard(
      title: 'حالة المتجر',
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: vm.loading
                  ? null
                  : () async {
                      final next = !vm.available;
                      try {
                        await vm.updateAvailability(widget.storeId, next);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              next
                                  ? 'تم تفعيل المتجر'
                                  : 'تم تحويل المتجر إلى مشغول',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تعذر تحديث حالة المتجر: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: Icon(
                vm.available
                    ? Icons.check_circle_outline
                    : Icons.do_not_disturb,
              ),
              label: Text(vm.available ? 'المتجر فعال' : 'المتجر مشغول'),
              style: ElevatedButton.styleFrom(
                backgroundColor: vm.available
                    ? AppColors.mainColor
                    : Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminsSection(EditStoreViewModel vm) {
    return _sectionCard(
      title: 'المديرين',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _adminEmailController,
            keyboardType: TextInputType.emailAddress,
            textAlign: TextAlign.right,
            decoration: _inputDecoration(
              hint: 'إضافة مدير جديد بالبريد الإلكتروني',
            ),
            onChanged: vm.setAdminEmail,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: vm.addingAdmin
                  ? null
                  : () async {
                      vm.setAdminEmail(_adminEmailController.text);
                      try {
                        final message = await vm.addAdmin(widget.storeId);
                        _adminEmailController.clear();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              icon: vm.addingAdmin
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: const Text('إضافة مدير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<StoreAdminProfile>>(
            stream: vm.watchAdmins(widget.storeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final admins = snapshot.data ?? [];
              if (admins.isEmpty) {
                return const Text(
                  'لا يوجد مديرين حاليًا',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: Colors.black54),
                );
              }
              return Column(
                children: admins.map((admin) {
                  final canDelete = admins.length > 1;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: canDelete
                              ? () async {
                                  try {
                                    await vm.removeAdmin(
                                      admin.uid,
                                      currentCount: admins.length,
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم حذف المدير'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(
                            Icons.delete_outline,
                            color: canDelete ? Colors.redAccent : Colors.grey,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                admin.displayName,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                admin.email,
                                textAlign: TextAlign.right,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.mainColor.withOpacity(
                            0.12,
                          ),
                          backgroundImage: admin.avatarUrl != null
                              ? NetworkImage(admin.avatarUrl!)
                              : null,
                          child: admin.avatarUrl == null
                              ? Text(
                                  admin.initials,
                                  style: const TextStyle(
                                    color: AppColors.mainColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _readOnlyRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.isEmpty ? '--' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      counterText: '',
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
