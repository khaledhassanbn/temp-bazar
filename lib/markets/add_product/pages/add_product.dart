import 'package:bazar_suez/markets/add_product/widget/QuestionWithOptions.dart';
import 'package:bazar_suez/markets/add_product/widget/app_dropdown_field.dart';
import 'package:bazar_suez/markets/add_product/widget/EndDateQuestionWidget.dart';
import 'package:bazar_suez/widgets/app_field.dart';
import 'package:bazar_suez/widgets/custom_back_button.dart';
import 'package:bazar_suez/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'arrange_product_page.dart';
import 'package:flutter/services.dart';
import '../viewmodels/add_product_viewmodel.dart';
import '../models/product_models.dart';
import '../debug/firebase_debug.dart';
import '../../../theme/app_color.dart';

/// 🔹 ويدجت منفصل للخصم
class DiscountQuestionWidget extends StatefulWidget {
  const DiscountQuestionWidget({Key? key}) : super(key: key);

  @override
  State<DiscountQuestionWidget> createState() => _DiscountQuestionWidgetState();
}

class _DiscountQuestionWidgetState extends State<DiscountQuestionWidget> {
  final TextEditingController discountController = TextEditingController();

  @override
  void dispose() {
    discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddProductViewModel>(
      builder: (context, vm, _) {
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
                      vm.setHasDiscount(val);
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

/// 🔹 ويدجت منفصل للكمية
class QuantityQuestionWidget extends StatefulWidget {
  const QuantityQuestionWidget({Key? key}) : super(key: key);

  @override
  State<QuantityQuestionWidget> createState() => _QuantityQuestionWidgetState();
}

class _QuantityQuestionWidgetState extends State<QuantityQuestionWidget> {
  final TextEditingController qtyController = TextEditingController();

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddProductViewModel>(
      builder: (context, vm, _) {
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

/// 🔹 الصفحة الرئيسية لإضافة المنتج
class AddProductModernPage extends StatefulWidget {
  const AddProductModernPage({Key? key}) : super(key: key);

  @override
  State<AddProductModernPage> createState() => _AddProductModernPageState();
}

class _AddProductModernPageState extends State<AddProductModernPage> {
  String? selectedCategoryName;
  bool showNewCategoryField = false;
  final TextEditingController newCategoryController = TextEditingController();

  final List<Map<String, TextEditingController>> requiredOptionControllers = [];
  final List<Map<String, TextEditingController>> extraOptionControllers = [];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final ImagePicker _picker = ImagePicker();
  static const String _addCategoryValue = "➕ إضافة فئة جديدة";

  @override
  void dispose() {
    _pageController.dispose();
    newCategoryController.dispose();
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
        final vm = context.read<AddProductViewModel>();
        vm.setProductImage(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في اختيار الصورة: $e')));
    }
  }

  Future<void> _addNewCategory() async {
    if (newCategoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم الفئة')));
      return;
    }

    try {
      final vm = context.read<AddProductViewModel>();
      vm.setNewCategoryName(newCategoryController.text.trim());
      await vm.addNewCategory();

      setState(() {
        showNewCategoryField = false;
        selectedCategoryName = vm.selectedCategory?.name;
      });

      newCategoryController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إضافة الفئة بنجاح')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في إضافة الفئة: $e')));
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

  Future<void> _goToArrange(AddProductViewModel vm) async {
    final err = vm.validationError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    await vm.loadProductsForSelectedCategory();
    final temp = vm.buildTemporaryProductForArrange();
    vm.productsInSelectedCategory = [...vm.productsInSelectedCategory, temp];
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ArrangeProductPage()));
  }

  Future<void> _debugFirebase() async {
    try {
      final vm = context.read<AddProductViewModel>();

      // تشخيص عام
      final generalDiagnosis = await FirebaseDebugHelper.diagnoseFirebase();
      FirebaseDebugHelper.printDiagnosis(generalDiagnosis);

      // تشخيص المتجر المحدد
      if (vm.selectedStore != null) {
        final storeDiagnosis = await FirebaseDebugHelper.diagnoseStore(
          vm.selectedStore!.id,
        );
        print('=== Store Diagnosis ===');
        print('Store ID: ${storeDiagnosis['store_id']}');
        print('Store Exists: ${storeDiagnosis['store_exists']}');
        print('Categories Count: ${storeDiagnosis['categories_count']}');
        if (storeDiagnosis['errors'].isNotEmpty) {
          print('Store Errors:');
          for (final error in storeDiagnosis['errors']) {
            print('  - $error');
          }
        }
        print('======================');

        // إذا لم تكن هناك فئات، أنشئها
        if (storeDiagnosis['categories_count'] == 0) {
          final created = await FirebaseDebugHelper.createDefaultCategories(
            vm.selectedStore!.id,
          );
          if (created) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إنشاء الفئات الافتراضية')),
            );
            // إعادة تحميل الفئات
            await vm.loadStoreCategories(vm.selectedStore!.id);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إجراء التشخيص - راجع الكونسول')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطأ في التشخيص: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.mainColor.withOpacity(0.08);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AddProductViewModel>();
      if (vm.userStores.isEmpty && !vm.isLoadingStores) {
        vm.loadUserStores();
      }
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Consumer<AddProductViewModel>(
          builder: (context, vm, _) {
            if (vm.selectedStore != null &&
                vm.selectedStore!.isLicenseExpired) {
              return _buildLicenseExpiredMessage(context, vm.selectedStore!);
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 72),
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
                            const CustomBackButton(),
                            const Spacer(),
                            IconButton(
                              onPressed: _debugFirebase,
                              icon: const Icon(
                                Icons.bug_report,
                                color: Colors.white,
                              ),
                              tooltip: 'تشخيص Firebase',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "إضافة منتج جديد",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "أضف منتجك وخصائصه بخطوات بسيطة",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -36),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                    child: vm.productImage != null
                                        ? ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(20),
                                                ),
                                            child: Image.file(
                                              vm.productImage!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                          ),
                                  ),
                                  if (vm.productImage == null)
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          "مطلوب",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (vm.productImage != null)
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.mainColor,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Column(
                              children: [
                                AppTextField(
                                  label: "اسم المنتج",
                                  hint: "مثال: برجر دجاج مقرمش",
                                  onChanged: (v) => vm.setProductName(v),
                                ),
                                const SizedBox(height: 8),
                                AppDropdownField(
                                  label: "المتجر",
                                  value: vm.selectedStore?.name,
                                  items: vm.userStores
                                      .map((s) => s.name)
                                      .toSet()
                                      .toList(),
                                  required: true,
                                  onChanged: (val) {
                                    final store = vm.userStores.firstWhere(
                                      (s) => s.name == val,
                                      orElse: () => vm.userStores.isNotEmpty
                                          ? vm.userStores.first
                                          : vm.selectedStore!,
                                    );
                                    vm.setSelectedStore(store);
                                    setState(() {
                                      selectedCategoryName =
                                          vm.selectedCategory?.name;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  label: "وصف المنتج",
                                  hint: "صف منتجك بإيجاز للعملاء...",
                                  maxLines: 2,
                                  onChanged: (v) => vm.setProductDescription(v),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: AppTextField(
                                        label: "السعر (جنيه)",
                                        hint: "0",
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onChanged: (v) => vm.setProductPrice(v),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: vm.isLoadingCategories
                                          ? const Padding(
                                              padding: EdgeInsets.only(top: 20),
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : AppDropdownField(
                                              label: "الفئة",
                                              value:
                                                  selectedCategoryName ??
                                                  vm.selectedCategory?.name,
                                              items: [
                                                ...vm.categories
                                                    .map((c) => c.name)
                                                    .toSet()
                                                    .toList(),
                                                _addCategoryValue,
                                              ],
                                              required: true,
                                              onChanged: (val) {
                                                setState(() {
                                                  selectedCategoryName = val;
                                                  showNewCategoryField =
                                                      val == _addCategoryValue;
                                                });
                                                if (val != null &&
                                                    val != _addCategoryValue) {
                                                  vm.setSelectedCategoryByName(
                                                    val,
                                                  );
                                                }
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                                if (showNewCategoryField) ...[
                                  AppTextField(
                                    controller: newCategoryController,
                                    label: "الفئة الجديدة",
                                    hint: "أدخل اسم الفئة الجديدة",
                                    required: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: PrimaryButton(
                                          text: "إضافة الفئة",
                                          onPressed: _addNewCategory,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setState(() {
                                              showNewCategoryField = false;
                                              newCategoryController.clear();
                                            });
                                          },
                                          child: const Text("إلغاء"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Divider(height: 24, color: Color(0xFFF0F2F4)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              "الإعدادات الإضافية",
                              style: TextStyle(
                                color: AppColors.mainColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              children: [
                                SmoothPageIndicator(
                                  controller: _pageController,
                                  count: 5,
                                  onDotClicked: _goToQuestion,
                                  effect: ExpandingDotsEffect(
                                    activeDotColor: AppColors.mainColor,
                                    dotColor: Colors.grey.shade300,
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
                          SizedBox(
                            height: 370,
                            child: Column(
                              children: [
                                Expanded(
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() => _currentPage = index);
                                    },
                                    children: [
                                      QuestionPage(
                                        question:
                                            "هل تريد إضافة خيارات مطلوبة من العميل؟",
                                        icon: _questionIcon(0),
                                        child: QuestionWithOptions(
                                          optionsControllers:
                                              requiredOptionControllers,
                                          onChanged:
                                              ({
                                                required bool enabled,
                                                required List<
                                                  Map<String, dynamic>
                                                >
                                                groups,
                                              }) {
                                                final vm = context
                                                    .read<
                                                      AddProductViewModel
                                                    >();
                                                if (!enabled) {
                                                  vm.setRequiredOptions([]);
                                                  return;
                                                }
                                                final built =
                                                    <ProductOptionModel>[];
                                                for (
                                                  var i = 0;
                                                  i < groups.length;
                                                  i++
                                                ) {
                                                  final g = groups[i];
                                                  final title =
                                                      (g['title'] as String?) ??
                                                      '';
                                                  final items =
                                                      (g['items']
                                                          as List<
                                                            Map<String, String>
                                                          >?) ??
                                                      [];
                                                  final choices = items
                                                      .map(
                                                        (
                                                          e,
                                                        ) => OptionChoiceModel(
                                                          name: e['name'] ?? '',
                                                          price:
                                                              num.tryParse(
                                                                e['price'] ??
                                                                    '0',
                                                              ) ??
                                                              0,
                                                        ),
                                                      )
                                                      .toList();
                                                  built.add(
                                                    ProductOptionModel(
                                                      id: '${DateTime.now().millisecondsSinceEpoch}-$i',
                                                      title: title,
                                                      choices: choices,
                                                      isRequired: true,
                                                      order: i,
                                                    ),
                                                  );
                                                }
                                                vm.setRequiredOptions(built);
                                              },
                                        ),
                                        key: const ValueKey("page_0"),
                                      ),
                                      QuestionPage(
                                        question:
                                            "هل تريد إضافة خيارات إضافية (غير مطلوبة) من العميل؟",
                                        icon: _questionIcon(1),
                                        child: QuestionWithOptions(
                                          optionsControllers:
                                              extraOptionControllers,
                                          onChanged:
                                              ({
                                                required bool enabled,
                                                required List<
                                                  Map<String, dynamic>
                                                >
                                                groups,
                                              }) {
                                                final vm = context
                                                    .read<
                                                      AddProductViewModel
                                                    >();
                                                if (!enabled) {
                                                  vm.setExtraOptions([]);
                                                  return;
                                                }
                                                final built =
                                                    <ProductOptionModel>[];
                                                for (
                                                  var i = 0;
                                                  i < groups.length;
                                                  i++
                                                ) {
                                                  final g = groups[i];
                                                  final title =
                                                      (g['title'] as String?) ??
                                                      '';
                                                  final items =
                                                      (g['items']
                                                          as List<
                                                            Map<String, String>
                                                          >?) ??
                                                      [];
                                                  final choices = items
                                                      .map(
                                                        (
                                                          e,
                                                        ) => OptionChoiceModel(
                                                          name: e['name'] ?? '',
                                                          price:
                                                              num.tryParse(
                                                                e['price'] ??
                                                                    '0',
                                                              ) ??
                                                              0,
                                                        ),
                                                      )
                                                      .toList();
                                                  built.add(
                                                    ProductOptionModel(
                                                      id: '${DateTime.now().millisecondsSinceEpoch}-$i',
                                                      title: title,
                                                      choices: choices,
                                                      isRequired: false,
                                                      order: i,
                                                    ),
                                                  );
                                                }
                                                vm.setExtraOptions(built);
                                              },
                                        ),
                                        key: const ValueKey("page_1"),
                                      ),
                                      QuestionPage(
                                        question:
                                            "هل تريد وضع عدد محدد من القطع للمنتج، بحيث يظهر (غير متاح) عند نفاد الكمية؟",
                                        icon: _questionIcon(2),
                                        child: const QuantityQuestionWidget(),
                                        key: const ValueKey("page_2"),
                                      ),
                                      QuestionPage(
                                        question: "هل يوجد خصم على هذا المنتج؟",
                                        icon: _questionIcon(3),
                                        child: const DiscountQuestionWidget(),
                                        key: const ValueKey("page_3"),
                                      ),
                                      QuestionPage(
                                        question:
                                            "هل تريد إزالة المنتج في وقت معين؟",
                                        icon: _questionIcon(4),
                                        child: const EndDateQuestionWidget(),
                                        key: const ValueKey("page_4"),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    20,
                                    0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: _currentPage == 0
                                              ? null
                                              : () => _goToQuestion(
                                                  _currentPage - 1,
                                                ),
                                          child: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "السؤال ${_currentPage + 1}",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            side: BorderSide(
                                              color: Colors.grey.shade300,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: _currentPage == 4
                                              ? null
                                              : () => _goToQuestion(
                                                  _currentPage + 1,
                                                ),
                                          child: const Icon(
                                            Icons.arrow_back_ios_new,
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

                          // ✅ رسائل الخطأ والنجاح
                          Consumer<AddProductViewModel>(
                            builder: (context, vm, _) {
                              if (vm.errorMessage != null) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error,
                                        color: Colors.red.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          vm.errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (vm.successMessage != null) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          vm.successMessage!,
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),

                          // ✅ زر الإضافة ينتقل لصفحة ترتيب المنتج
                          Consumer<AddProductViewModel>(
                            builder: (context, vm, _) {
                              return PrimaryButton(
                                text: "ترتيب المنتج والحفظ",
                                isLoading: vm.isAddingProduct,
                                onPressed: () => _goToArrange(vm),
                              );
                            },
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
    );
  }

  /// Widget displayed when store license is expired
  Widget _buildLicenseExpiredMessage(BuildContext context, store) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'انتهت صلاحية الترخيص',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'لا يمكنك إضافة منتجات جديدة حتى تجدد ترخيص المتجر',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          if (store.licenseEndAt != null)
            Text(
              'انتهى في: ${store.licenseEndAt!.day}/${store.licenseEndAt!.month}/${store.licenseEndAt!.year}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/PricingPage');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('تجديد الترخيص الآن'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'العودة',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 صفحة السؤال مع حركة اهتزاز
class QuestionPage extends StatefulWidget {
  final String question;
  final IconData icon;
  final Widget child;

  const QuestionPage({
    Key? key,
    required this.question,
    required this.child,
    required this.icon,
  }) : super(key: key);

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> with AutomaticKeepAliveClientMixin {
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  child: Icon(widget.icon, size: 18, color: AppColors.mainColor),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(padding: const EdgeInsets.all(16), child: widget.child)
                .animate()
                .shake(duration: 600.ms, hz: 3, offset: const Offset(8, 0)),
          ),
        ],
      ),
    );
  }
}
