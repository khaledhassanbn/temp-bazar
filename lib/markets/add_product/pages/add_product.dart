import 'package:bazar_suez/markets/add_product/widget/QuestionWithOptions.dart';
import 'package:bazar_suez/markets/add_product/widget/app_dropdown_field.dart';
import 'package:bazar_suez/markets/add_product/widget/EndDateQuestionWidget.dart';
import 'package:bazar_suez/widgets/app_field.dart';
import 'package:bazar_suez/widgets/custom_back_button.dart';
import 'package:bazar_suez/widgets/primary_button.dart';
import 'package:flutter/material.dart';
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

  // تم استبدال الحفظ المباشر بخطوة ترتيب المنتج

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
    const backgroundColor = Color(0xFFE0F2F1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AddProductViewModel>();
      if (vm.userStores.isEmpty && !vm.isLoadingStores) {
        vm.loadUserStores();
      }
    });

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
                child: Row(
                  children: [
                    const CustomBackButton(),
                    const Spacer(),
                    IconButton(
                      onPressed: _debugFirebase,
                      icon: const Icon(Icons.bug_report, color: Colors.white),
                      tooltip: 'تشخيص Firebase',
                    ),
                  ],
                ),
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
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Consumer<AddProductViewModel>(
                    builder: (context, vm, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ✅ صورة المنتج
                          Consumer<AddProductViewModel>(
                            builder: (context, vm, _) {
                              return GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: (vm.productImage == null)
                                          ? Colors.red.shade300
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  child: vm.productImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.file(
                                            vm.productImage!,
                                            width: double.infinity,
                                            height: 150,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Icons.add_a_photo,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'الصورة مطلوبة',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // ✅ الحقول
                          AppTextField(
                            label: "اسم المنتج",
                            hint: "أدخل اسم المنتج",
                            onChanged: (v) => context
                                .read<AddProductViewModel>()
                                .setProductName(v),
                          ),
                          const SizedBox(height: 8),

                          AppDropdownField(
                            label: "حدد المتجر",
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
                            hint: "أدخل وصف المنتج",
                            onChanged: (v) => context
                                .read<AddProductViewModel>()
                                .setProductDescription(v),
                          ),
                          const SizedBox(height: 8),

                          AppTextField(
                            label: "السعر",
                            hint: "أدخل السعر",
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => context
                                .read<AddProductViewModel>()
                                .setProductPrice(v),
                          ),
                          const SizedBox(height: 8),

                          // عرض رسالة تحميل الفئات
                          if (vm.isLoadingCategories)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            AppDropdownField(
                              label: "الفئة (ضمن المتجر)",
                              value:
                                  selectedCategoryName ??
                                  vm.selectedCategory?.name,
                              items: [
                                ...vm.categories
                                    .map((c) => c.name)
                                    .toSet()
                                    .toList(),
                                "➕ إضافة فئة جديدة",
                              ],
                              required: true,
                              onChanged: (val) {
                                setState(() {
                                  selectedCategoryName = val;
                                  showNewCategoryField =
                                      val == "➕ إضافة فئة جديدة";
                                });
                                if (val != null && val != "➕ إضافة فئة جديدة") {
                                  vm.setSelectedCategoryByName(val);
                                }
                              },
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

                          const SizedBox(height: 16),

                          // ✅ مجموعة الأسئلة (PageView أفقي + Indicator)
                          SizedBox(
                            height: 560,
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
                                        key: ValueKey("page_0_$_currentPage"),
                                      ),
                                      QuestionPage(
                                        question:
                                            "هل تريد إضافة خيارات إضافية (غير مطلوبة) من العميل؟",
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
                                        key: ValueKey("page_1_$_currentPage"),
                                      ),
                                      QuestionPage(
                                        question:
                                            "هل تريد وضع عدد محدد من القطع للمنتج، بحيث يظهر (غير متاح) عند نفاد الكمية؟",
                                        child: const QuantityQuestionWidget(),
                                        key: ValueKey("page_2_$_currentPage"),
                                      ),
                                      QuestionPage(
                                        question: "هل يوجد خصم على هذا المنتج؟",
                                        child: const DiscountQuestionWidget(),
                                        key: ValueKey("page_3_$_currentPage"),
                                      ),
                                      QuestionPage(
                                        question:
                                            "هل تريد إزالة المنتج في وقت معين؟",
                                        child: const EndDateQuestionWidget(),
                                        key: ValueKey("page_4_$_currentPage"),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SmoothPageIndicator(
                                  controller: _pageController,
                                  count: 5, // ✅ عدد الأسئلة = 5
                                  effect: ExpandingDotsEffect(
                                    activeDotColor: AppColors.mainColor,
                                    dotColor: Colors.grey.shade300,
                                    dotHeight: 10,
                                    dotWidth: 10,
                                    spacing: 6,
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
                                text: "ترتيب المنتج",
                                isLoading: vm.isAddingProduct,
                                onPressed: () async {
                                  final err = vm.validationError;
                                  if (err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err)),
                                    );
                                    return;
                                  }
                                  await vm.loadProductsForSelectedCategory();
                                  // أضف المنتج المؤقت للقائمة للعرض فقط
                                  final temp = vm
                                      .buildTemporaryProductForArrange();
                                  vm.productsInSelectedCategory = [
                                    ...vm.productsInSelectedCategory,
                                    temp,
                                  ];
                                  if (!mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ArrangeProductPage(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 صفحة السؤال مع حركة اهتزاز
class QuestionPage extends StatelessWidget {
  final String question;
  final Widget child;

  const QuestionPage({Key? key, required this.question, required this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16.0), child: child)
              .animate()
              .shake(duration: 600.ms, hz: 3, offset: const Offset(8, 0)),
        ],
      ),
    );
  }
}
