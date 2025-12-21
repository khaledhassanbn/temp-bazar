import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/edit_store_viewmodel.dart';
import '../widgets/cover_image_widget.dart';
import '../widgets/logo_avatar_widget.dart';
import '../widgets/store_basic_info_section.dart';
import '../widgets/store_link_section.dart';
import '../widgets/category_section.dart';
import '../widgets/working_hours_section.dart';
import '../widgets/contact_info_section.dart';
import '../widgets/location_section.dart';
import '../widgets/address_toggle_section.dart';
import '../widgets/add_admin_section.dart';
import '../widgets/save_button_section.dart';
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  bool _controllersInitialized = false;

  void _initializeControllers(EditStoreViewModel vm) {
    if (!_controllersInitialized && !vm.loading && vm.name.isNotEmpty) {
      _nameController.text = vm.name;
      _descriptionController.text = vm.description;
      _phoneController.text = vm.phone;
      _facebookController.text = vm.facebook;
      _instagramController.text = vm.instagram;
      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    _nameController.dispose();
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

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
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
                                horizontal: 18.0,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Page Title
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Text(
                                        'تعديل المتجر',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.mainColor,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Basic Info Section
                                  StoreBasicInfoSection(
                                    viewModel: vm,
                                    nameController: _nameController,
                                    descriptionController:
                                        _descriptionController,
                                  ),

                                  // Store Link Section
                                  StoreLinkSection(viewModel: vm),

                                  // Category Section
                                  CategorySection(viewModel: vm),

                                  // Working Hours Section
                                  WorkingHoursSection(viewModel: vm),

                                  // Contact Info Section
                                  ContactInfoSection(
                                    viewModel: vm,
                                    phoneController: _phoneController,
                                    facebookController: _facebookController,
                                    instagramController: _instagramController,
                                  ),

                                  // Location Section
                                  LocationSection(viewModel: vm),

                                  // Address Toggle Section
                                  AddressToggleSection(
                                    viewModel: vm,
                                    showAddress: _showAddress,
                                    onChanged: (value) {
                                      setState(() => _showAddress = value);
                                    },
                                  ),

                                  // Add Admin Section
                                  AddAdminSection(
                                    viewModel: vm,
                                    adminEmailController: _adminEmailController,
                                    storeId: widget.storeId,
                                  ),

                                  // Save Button Section
                                  SaveButtonSection(
                                    viewModel: vm,
                                    formKey: _formKey,
                                    storeId: widget.storeId,
                                  ),

                                  const SizedBox(height: 28), // bottom spacing
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
