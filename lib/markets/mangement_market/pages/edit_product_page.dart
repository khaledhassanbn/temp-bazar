import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../theme/app_color.dart';
import '../../../widgets/app_field.dart';
import '../../../widgets/primary_button.dart';
import '../../add_product/models/product_models.dart';
import '../../add_product/widget/app_dropdown_field.dart';
import '../viewmodels/edit_product_viewmodel.dart';

// ─────────────────────────────────────────────────────────────
// 🔹 ويدجت الخصم (خاص بالتعديل)
// ─────────────────────────────────────────────────────────────
class _EditDiscountWidget extends StatefulWidget {
  const _EditDiscountWidget({Key? key}) : super(key: key);

  @override
  State<_EditDiscountWidget> createState() => _EditDiscountWidgetState();
}

class _EditDiscountWidgetState extends State<_EditDiscountWidget> {
  final TextEditingController discountController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditProductViewModel>(
      builder: (context, vm, _) {
        if (!_initialized) {
          _initialized = true;
          if (vm.hasDiscount && vm.discountValue > 0) {
            discountController.text = vm.discountValue.toString();
          }
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تفعيل",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    activeColor: AppColors.mainColor,
                    value: vm.hasDiscount,
                    onChanged: (val) {
                      vm.toggleDiscount(val);
                      if (val) {
                        discountController.text = vm.discountValue.toString();
                      } else {
                        discountController.clear();
                      }
                    },
                  ),
                ],
              ),
              if (vm.hasDiscount) ...[
                const SizedBox(height: 16),
                AppTextField(
                  controller: discountController,
                  label: "قيمة الخصم",
                  hint: "مثال: 10",
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    vm.setDiscountValue(value);
                  },
                ),
                const SizedBox(height: 16),
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
                    children: [
                      const Icon(
                        Icons.calculate,
                        color: AppColors.mainColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "السعر النهائي هو: ${vm.finalPrice.toStringAsFixed(0)} جنيه",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mainColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 ويدجت الكمية (خاص بالتعديل)
// ─────────────────────────────────────────────────────────────
class _EditQuantityWidget extends StatefulWidget {
  const _EditQuantityWidget({Key? key}) : super(key: key);

  @override
  State<_EditQuantityWidget> createState() => _EditQuantityWidgetState();
}

class _EditQuantityWidgetState extends State<_EditQuantityWidget> {
  final TextEditingController qtyController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditProductViewModel>(
      builder: (context, vm, _) {
        if (!_initialized) {
          _initialized = true;
          if (vm.hasStockLimit && vm.stockQuantity > 0) {
            qtyController.text = vm.stockQuantity.toString();
          }
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تفعيل",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    activeColor: AppColors.mainColor,
                    value: vm.hasStockLimit,
                    onChanged: (val) {
                      vm.setHasStockLimit(val);
                      if (val) {
                        qtyController.text = vm.stockQuantity.toString();
                      } else {
                        qtyController.clear();
                      }
                    },
                  ),
                ],
              ),
              if (vm.hasStockLimit) ...[
                const SizedBox(height: 16),
                AppTextField(
                  controller: qtyController,
                  label: "عدد القطع المتاحة",
                  hint: "مثال: 50",
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    vm.setStockQuantity(value);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 ويدجت تاريخ الإزالة (خاص بالتعديل)
// ─────────────────────────────────────────────────────────────
class _EditEndDateWidget extends StatefulWidget {
  const _EditEndDateWidget({Key? key}) : super(key: key);

  @override
  State<_EditEndDateWidget> createState() => _EditEndDateWidgetState();
}

class _EditEndDateWidgetState extends State<_EditEndDateWidget> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<EditProductViewModel>(
      builder: (context, vm, _) {
        if (!_initialized) {
          _initialized = true;
          if (vm.endAt != null) {
            _selectedDate = vm.endAt;
            _selectedTime = TimeOfDay.fromDateTime(vm.endAt!);
          }
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تفعيل",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    activeColor: AppColors.mainColor,
                    value: vm.hasEndDate,
                    onChanged: (val) {
                      vm.setHasEndDate(val);
                      if (val) {
                        if (_selectedDate == null) {
                          _selectedDate = DateTime.now().add(
                            const Duration(days: 1),
                          );
                        }
                        if (_selectedTime == null) {
                          _selectedTime =
                              const TimeOfDay(hour: 23, minute: 59);
                        }
                        _updateEndAt(vm);
                      }
                    },
                  ),
                ],
              ),
              if (vm.hasEndDate) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.mainColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppColors.mainColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "تاريخ الإزالة: ${_formatDate(_selectedDate)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.mainColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "وقت الإزالة: ${_formatTime(_selectedTime)}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectDate(vm),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text("اختر التاريخ"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectTime(vm),
                        icon: const Icon(Icons.access_time),
                        label: const Text("اختر الوقت"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mainColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "سيتم إزالة المنتج تلقائياً في التاريخ والوقت المحددين",
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "غير محدد";
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "غير محدد";
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDate(EditProductViewModel vm) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _updateEndAt(vm);
    }
  }

  Future<void> _selectTime(EditProductViewModel vm) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
      _updateEndAt(vm);
    }
  }

  void _updateEndAt(EditProductViewModel vm) {
    if (_selectedDate != null && _selectedTime != null) {
      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      vm.setEndAt(dt);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 ويدجت الخيارات المطلوبة / الإضافية (خاص بالتعديل)
// ─────────────────────────────────────────────────────────────
class _EditOptionsWidget extends StatelessWidget {
  const _EditOptionsWidget({Key? key, required this.isRequired})
      : super(key: key);

  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Consumer<EditProductViewModel>(
      builder: (context, vm, _) {
        final enabled = isRequired
            ? vm.requiredOptionsEnabled
            : vm.extraOptionsEnabled;
        final groups = isRequired
            ? vm.requiredOptionGroups
            : vm.extraOptionGroups;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تفعيل",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    activeColor: AppColors.mainColor,
                    value: enabled,
                    onChanged: (val) {
                      if (isRequired) {
                        vm.toggleRequiredOptions(val);
                      } else {
                        vm.toggleExtraOptions(val);
                      }
                    },
                  ),
                ],
              ),
              if (enabled) ...[
                const SizedBox(height: 16),
                for (int gi = 0; gi < groups.length; gi++) ...[
                  AppTextField(
                    controller: groups[gi].titleController,
                    label: "عنوان مجموعة الخيارات",
                    hint: "مثال: اختر الحجم",
                  ),
                  const SizedBox(height: 12),
                  for (int ci = 0;
                      ci < groups[gi].choices.length;
                      ci++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller:
                                  groups[gi].choices[ci].nameController,
                              label: "اسم الخيار",
                              hint: "مثال: حجم كبير",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppTextField(
                              controller:
                                  groups[gi].choices[ci].priceController,
                              label: "سعر الخيار",
                              hint: "0",
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.mainColor,
                            ),
                            onPressed: () => vm.removeChoice(
                              isRequired: isRequired,
                              groupId: groups[gi].id,
                              choiceId: groups[gi].choices[ci].id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 12,
                      children: [
                        TextButton.icon(
                          onPressed: () => vm.addChoice(
                            isRequired: isRequired,
                            groupId: groups[gi].id,
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            "إضافة خيار آخر",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              vm.addOptionGroup(isRequired: isRequired),
                          icon: const Icon(Icons.playlist_add),
                          label: const Text(
                            "إضافة مجموعة خيارات جديدة",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ),
                        if (groups.length > 1)
                          TextButton.icon(
                            onPressed: () => vm.removeOptionGroup(
                              isRequired: isRequired,
                              groupId: groups[gi].id,
                            ),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text(
                              "حذف المجموعة",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.mainColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 صفحة السؤال مع حركة اهتزاز (مطابقة لـ AddProductModernPage)
// ─────────────────────────────────────────────────────────────
class _EditQuestionPage extends StatefulWidget {
  final String question;
  final IconData icon;
  final Widget child;

  const _EditQuestionPage({
    Key? key,
    required this.question,
    required this.child,
    required this.icon,
  }) : super(key: key);

  @override
  State<_EditQuestionPage> createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends State<_EditQuestionPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8EAEC), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBFC),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(widget.icon,
                      size: 18, color: AppColors.mainColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
                    padding: const EdgeInsets.all(16),
                    child: widget.child)
                .animate()
                .shake(
                    duration: 600.ms,
                    hz: 3,
                    offset: const Offset(8, 0)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 🔹 الصفحة الرئيسية لتعديل المنتج (بتصميم AddProductModernPage)
// ─────────────────────────────────────────────────────────────
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
  State<EditProductModernPage> createState() =>
      _EditProductModernPageState();
}

class _EditProductModernPageState extends State<EditProductModernPage> {
  late final EditProductViewModel _viewModel;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _viewModel = EditProductViewModel(
      marketId: widget.marketId,
      initialCategory: widget.category,
      product: widget.product,
    );

    // تعبئة الحقول ببيانات المنتج الحالية
    _nameController.text = widget.product.name;
    _priceController.text = widget.product.price.toString();
    _descriptionController.text = widget.product.description ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadCategories();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        _viewModel.setNewImage(File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الصورة: $e')),
      );
    }
  }

  IconData _questionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.tune;
      case 1:
        return Icons.auto_awesome;
      case 2:
        return Icons.inventory_2_outlined;
      case 3:
        return Icons.local_offer_outlined;
      default:
        return Icons.schedule;
    }
  }

  void _goToQuestion(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _save() async {
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
    _viewModel.setPrice(priceRaw);

    if (_viewModel.hasDiscount) {
      if (_viewModel.discountValue <= 0) {
        _showSnackBar('يرجى إدخال قيمة الخصم');
        return;
      }
    }

    if (_viewModel.hasStockLimit) {
      if (_viewModel.stockQuantity <= 0) {
        _showSnackBar('يرجى إدخال كمية صالحة');
        return;
      }
    }

    final description = _descriptionController.text.trim();

    final updated = await _viewModel.submit(
      name: name,
      description: description,
    );
    if (updated != null && mounted) {
      Navigator.pop(context, updated);
    } else if (_viewModel.errorMessage != null) {
      _showSnackBar(_viewModel.errorMessage!);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onBackRequested() {
    if (_viewModel.isSaving) {
      _showSnackBar('يرجى الانتظار حتى انتهاء الحفظ');
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.mainColor.withOpacity(0.08);

    return ChangeNotifierProvider<EditProductViewModel>.value(
      value: _viewModel,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Consumer<EditProductViewModel>(
              builder: (context, vm, _) {
                // عرض الرسائل
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

                return PopScope(
                  canPop: !vm.isSaving,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop && vm.isSaving && mounted) {
                      _showSnackBar('يرجى الانتظار حتى انتهاء الحفظ');
                    }
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ─── Header بتدرج ───
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.fromLTRB(20, 24, 20, 72),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.mainColor,
                                AppColors.mainColor.withOpacity(0.82),
                              ],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // زر الرجوع
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    onPressed: _onBackRequested,
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "تعديل المنتج",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "عدّل بيانات وخصائص المنتج",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ─── البطاقة الرئيسية ───
                        Transform.translate(
                          offset: const Offset(0, -36),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 24,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                // ─── صورة المنتج ───
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 200,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF8FAFB),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: _buildImagePreview(vm),
                                        ),
                                        // زر تغيير الصورة
                                        if (_hasImage(vm))
                                          Positioned(
                                            bottom: 12,
                                            right: 12,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 14,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.mainColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        20),
                                              ),
                                              child: const Text(
                                                "تغيير الصورة",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ─── بيانات المنتج ───
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 20, 20, 0),
                                  child: Text(
                                    "بيانات المنتج",
                                    style: TextStyle(
                                      color: AppColors.mainColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 12, 20, 0),
                                  child: Column(
                                    children: [
                                      AppTextField(
                                        controller: _nameController,
                                        label: "اسم المنتج",
                                        hint: "مثال: برجر دجاج مقرمش",
                                      ),
                                      const SizedBox(height: 8),
                                      AppTextField(
                                        controller:
                                            _descriptionController,
                                        label: "وصف المنتج",
                                        hint:
                                            "صف منتجك بإيجاز للعملاء...",
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: AppTextField(
                                              controller:
                                                  _priceController,
                                              label: "السعر (جنيه)",
                                              hint: "0",
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              onChanged: (v) =>
                                                  vm.setPrice(v),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: vm.isLoadingCategories
                                                ? const Padding(
                                                    padding:
                                                        EdgeInsets.only(
                                                            top: 20),
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                  )
                                                : AppDropdownField(
                                                    label: "الفئة",
                                                    value: vm
                                                        .selectedCategory
                                                        ?.name,
                                                    items: vm.categories
                                                        .map(
                                                            (c) => c.name)
                                                        .toSet()
                                                        .toList(),
                                                    required: true,
                                                    onChanged: (val) {
                                                      if (val != null) {
                                                        final cat = vm
                                                            .categories
                                                            .firstWhere(
                                                          (c) =>
                                                              c.name ==
                                                              val,
                                                          orElse: () =>
                                                              vm.categories
                                                                  .first,
                                                        );
                                                        vm.setSelectedCategoryById(
                                                            cat.id);
                                                      }
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // ─── حالة المنتج (متاح / مخفي) ───
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: vm.status
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: vm.status
                                                ? Colors.green.shade200
                                                : Colors.red.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  vm.status
                                                      ? Icons.visibility
                                                      : Icons
                                                          .visibility_off,
                                                  color: vm.status
                                                      ? Colors
                                                          .green.shade700
                                                      : Colors
                                                          .red.shade700,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  vm.status
                                                      ? "المنتج متاح"
                                                      : "المنتج مخفي",
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: vm.status
                                                        ? Colors.green
                                                            .shade700
                                                        : Colors.red
                                                            .shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Switch(
                                              activeColor:
                                                  Colors.green.shade600,
                                              value: vm.status,
                                              onChanged: vm.isSaving
                                                  ? null
                                                  : (val) =>
                                                      vm.setStatus(val),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(
                                    height: 24,
                                    color: Color(0xFFF0F2F4)),

                                // ─── الإعدادات الإضافية ───
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Text(
                                    "الإعدادات الإضافية",
                                    style: TextStyle(
                                      color: AppColors.mainColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // ─── Page indicator + عداد ───
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 16, 20, 0),
                                  child: Row(
                                    children: [
                                      SmoothPageIndicator(
                                        controller: _pageController,
                                        count: 5,
                                        onDotClicked: _goToQuestion,
                                        effect: ExpandingDotsEffect(
                                          activeDotColor:
                                              AppColors.mainColor,
                                          dotColor:
                                              Colors.grey.shade300,
                                          dotHeight: 8,
                                          dotWidth: 8,
                                          spacing: 6,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "${_currentPage + 1} من 5",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // ─── الأسئلة (5 صفحات) ───
                                SizedBox(
                                  height: 370,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: PageView(
                                          controller: _pageController,
                                          onPageChanged: (index) {
                                            setState(() =>
                                                _currentPage = index);
                                          },
                                          children: [
                                            _EditQuestionPage(
                                              question:
                                                  "هل تريد إضافة خيارات مطلوبة من العميل؟",
                                              icon: _questionIcon(0),
                                              child:
                                                  const _EditOptionsWidget(
                                                      isRequired: true),
                                              key: const ValueKey(
                                                  "edit_page_0"),
                                            ),
                                            _EditQuestionPage(
                                              question:
                                                  "هل تريد إضافة خيارات إضافية (غير مطلوبة) من العميل؟",
                                              icon: _questionIcon(1),
                                              child:
                                                  const _EditOptionsWidget(
                                                      isRequired: false),
                                              key: const ValueKey(
                                                  "edit_page_1"),
                                            ),
                                            _EditQuestionPage(
                                              question:
                                                  "هل تريد وضع عدد محدد من القطع للمنتج، بحيث يظهر (غير متاح) عند نفاد الكمية؟",
                                              icon: _questionIcon(2),
                                              child:
                                                  const _EditQuantityWidget(),
                                              key: const ValueKey(
                                                  "edit_page_2"),
                                            ),
                                            _EditQuestionPage(
                                              question:
                                                  "هل يوجد خصم على هذا المنتج؟",
                                              icon: _questionIcon(3),
                                              child:
                                                  const _EditDiscountWidget(),
                                              key: const ValueKey(
                                                  "edit_page_3"),
                                            ),
                                            _EditQuestionPage(
                                              question:
                                                  "هل تريد إزالة المنتج في وقت معين؟",
                                              icon: _questionIcon(4),
                                              child:
                                                  const _EditEndDateWidget(),
                                              key: const ValueKey(
                                                  "edit_page_4"),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // أزرار التنقل
                                      Padding(
                                        padding:
                                            const EdgeInsets.fromLTRB(
                                                20, 10, 20, 0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: OutlinedButton(
                                                style: OutlinedButton
                                                    .styleFrom(
                                                  padding:
                                                      EdgeInsets.zero,
                                                  side: BorderSide(
                                                    color: Colors
                                                        .grey.shade300,
                                                  ),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                10),
                                                  ),
                                                ),
                                                onPressed:
                                                    _currentPage == 0
                                                        ? null
                                                        : () =>
                                                            _goToQuestion(
                                                              _currentPage -
                                                                  1,
                                                            ),
                                                child: const Icon(
                                                  Icons
                                                      .arrow_forward_ios,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              "السؤال ${_currentPage + 1}",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    Colors.grey.shade600,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: OutlinedButton(
                                                style: OutlinedButton
                                                    .styleFrom(
                                                  padding:
                                                      EdgeInsets.zero,
                                                  side: BorderSide(
                                                    color: Colors
                                                        .grey.shade300,
                                                  ),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                10),
                                                  ),
                                                ),
                                                onPressed:
                                                    _currentPage == 4
                                                        ? null
                                                        : () =>
                                                            _goToQuestion(
                                                              _currentPage +
                                                                  1,
                                                            ),
                                                child: const Icon(
                                                  Icons
                                                      .arrow_back_ios_new,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ─── زر الحفظ ───
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: PrimaryButton(
                                    text: "حفظ التعديلات",
                                    isLoading: vm.isSaving,
                                    onPressed: _save,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// هل يوجد صورة (جديدة أو حالية)
  bool _hasImage(EditProductViewModel vm) {
    return vm.newImageFile != null ||
        (widget.product.image != null &&
            widget.product.image!.isNotEmpty);
  }

  /// عرض الصورة (الجديدة أولاً، ثم الحالية، ثم placeholder)
  Widget _buildImagePreview(EditProductViewModel vm) {
    if (vm.newImageFile != null) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: Image.file(vm.newImageFile!, fit: BoxFit.cover),
      );
    }
    if (widget.product.image != null &&
        widget.product.image!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: Image.network(
          widget.product.image!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 36,
          color: Colors.grey.shade500,
        ),
        const SizedBox(height: 8),
        Text(
          "اضغط لإضافة صورة المنتج",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
