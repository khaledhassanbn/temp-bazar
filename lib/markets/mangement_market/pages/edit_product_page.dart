import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../widgets/primary_button.dart';
import '../../add_product/models/product_models.dart';
import '../viewmodels/edit_product_viewmodel.dart';
import '../widgets/edit_product/basic_info_section.dart';
import '../widgets/edit_product/category_section.dart';
import '../widgets/edit_product/edit_product_header.dart';
import '../widgets/edit_product/image_picker_card.dart';
import '../widgets/edit_product/inventory_section.dart';
import '../widgets/edit_product/options_section.dart';
import '../widgets/edit_product/pricing_section.dart';
import '../widgets/edit_product/status_section.dart';

class EditProductModernPage extends StatefulWidget {
  const EditProductModernPage({
    super.key,
    required this.marketId,
    required this.category,
    required this.product,
  });

  final String marketId;
  final ProductCategoryModel category;
  final ProductModel product;

  @override
  State<EditProductModernPage> createState() => _EditProductModernPageState();
}

class _EditProductModernPageState extends State<EditProductModernPage> {
  late final EditProductViewModel _viewModel;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _viewModel = EditProductViewModel(
      marketId: widget.marketId,
      initialCategory: widget.category,
      product: widget.product,
    );

    _nameController.text = widget.product.name;
    _priceController.text = widget.product.price.toString();
    _descriptionController.text = widget.product.description ?? '';
    _stockController.text = widget.product.stock.toString();
    if (widget.product.hasDiscount && widget.product.discountValue != null) {
      _discountController.text = widget.product.discountValue!.toString();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickImage(EditProductViewModel vm) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        vm.setNewImage(File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في اختيار الصورة: $e')));
    }
  }

  Future<void> _pickEndDate(EditProductViewModel vm) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: vm.endAt ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: vm.endAt != null
          ? TimeOfDay.fromDateTime(vm.endAt!)
          : TimeOfDay.now(),
    );

    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );

    vm.setEndAt(endDateTime);
  }

  Future<void> _save(EditProductViewModel vm) async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('يرجى إدخال اسم المنتج');
      return;
    }

    final priceRaw = _priceController.text.trim();
    final price = num.tryParse(priceRaw);
    if (price == null) {
      _showSnackBar('يرجى إدخال سعر صحيح');
      return;
    }
    vm.setPrice(priceRaw);

    if (vm.hasDiscount) {
      final discountRaw = _discountController.text.trim();
      if (discountRaw.isEmpty) {
        _showSnackBar('يرجى إدخال قيمة الخصم');
        return;
      }
      vm.setDiscountValue(discountRaw);
    }

    if (vm.hasStockLimit) {
      final qtyRaw = _stockController.text.trim();
      final qty = int.tryParse(qtyRaw);
      if (qty == null || qty <= 0) {
        _showSnackBar('يرجى إدخال كمية صالحة');
        return;
      }
      vm.setStockQuantity(qtyRaw);
    }

    final description = _descriptionController.text.trim();

    final updated = await vm.submit(name: name, description: description);
    if (updated != null && mounted) {
      Navigator.pop(context, updated);
    } else if (vm.errorMessage != null) {
      _showSnackBar(vm.errorMessage!);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFE0F2F1);

    return ChangeNotifierProvider<EditProductViewModel>.value(
      value: _viewModel,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Consumer<EditProductViewModel>(
              builder: (context, vm, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (vm.errorMessage != null) {
                    _showSnackBar(vm.errorMessage!);
                    vm.errorMessage = null;
                  }
                  if (vm.successMessage != null) {
                    _showSnackBar(vm.successMessage!);
                    vm.successMessage = null;
                  }
                });

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      EditProductHeader(
                        onBack: () => Navigator.of(context).pop(),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              EditProductImagePicker(
                                viewModel: vm,
                                onPickImage: () => _pickImage(vm),
                              ),
                              const SizedBox(height: 24),
                              EditProductCategorySection(viewModel: vm),
                              const SizedBox(height: 16),
                              EditProductBasicInfoSection(
                                viewModel: vm,
                                nameController: _nameController,
                                descriptionController: _descriptionController,
                              ),
                              const SizedBox(height: 16),
                              EditProductPricingSection(
                                viewModel: vm,
                                priceController: _priceController,
                                discountController: _discountController,
                              ),
                              const SizedBox(height: 16),
                              EditProductInventorySection(
                                viewModel: vm,
                                stockController: _stockController,
                              ),
                              const SizedBox(height: 16),
                              EditProductStatusSection(
                                viewModel: vm,
                                onRequestEndDate: () => _pickEndDate(vm),
                              ),
                              const SizedBox(height: 16),
                              EditProductOptionsSection(
                                viewModel: vm,
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              EditProductOptionsSection(
                                viewModel: vm,
                                isRequired: false,
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(
                                text: 'حفظ التعديلات',
                                isLoading: vm.isSaving,
                                onPressed: () => _save(vm),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
