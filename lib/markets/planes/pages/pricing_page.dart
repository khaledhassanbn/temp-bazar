import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodels/pricing_viewmodel.dart';
import '../models/package.dart';
import '../services/pending_payment_service.dart';
import '../../wallet/services/wallet_service.dart';
import '../../../theme/app_color.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  int highlightedIndex = 0;
  final TextEditingController _discountController = TextEditingController();
  late final PricingViewModel _viewModel;

  @override
  void dispose() {
    _discountController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _viewModel = PricingViewModel();
    _viewModel.fetchPackages();
    _checkPendingPaymentAndRedirect();
  }

  // التحقق من وجود دفع معلق وفتح صفحة إنشاء المتجر تلقائياً
  Future<void> _checkPendingPaymentAndRedirect() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final pendingPaymentService = PendingPaymentService();
      final pendingPayment = await pendingPaymentService.getPendingPayment(
        user.uid,
      );

      if (pendingPayment != null && pendingPayment.isValid && mounted) {
        // الانتظار حتى يتم بناء الصفحة بالكامل ثم التوجيه التلقائي
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            // انتظار قصير للتأكد من اكتمال بناء الصفحة
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              // التوجيه التلقائي لصفحة إنشاء المتجر مع بيانات الباقة
              context.go(
                '/create-store?packageId=${pendingPayment.packageId}&days=${pendingPayment.days}',
              );
            }
          }
        });
      }
    } catch (e) {
      // في حالة حدوث خطأ، لا نفعل شيئاً ونترك المستخدم في صفحة الباقات
      print('خطأ في التحقق من الدفع المعلق: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "خطط الاشتراك",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: AppColors.mainColor,
        ),
        body: Consumer<PricingViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.packages.isEmpty) {
              return const Center(child: Text("لا توجد باقات متاحة"));
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo.metrics.pixels >= 0) {
                  final index = (scrollInfo.metrics.pixels / 200).floor();
                  if (index != highlightedIndex &&
                      index < viewModel.packages.length) {
                    setState(() {
                      highlightedIndex = index;
                    });
                  }
                }
                return true;
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.packages.length + 1,
                itemBuilder: (context, index) {
                  if (index < viewModel.packages.length) {
                    final package = viewModel.packages[index];
                    return PackageCard(
                      package: package,
                      isHighlighted: index == highlightedIndex,
                    );
                  }
                  // حقل كود الخصم + زر "ابدأ" بعد الباقات
                  return Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _discountController,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              hintText: "كود الخصم",
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Colors.black12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final code = _discountController.text.trim();
                            FocusScope.of(context).unfocus();

                            if (code.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("من فضلك أدخل كود الخصم"),
                                ),
                              );
                              return;
                            }

                            // في حالة وجود كود خصم، ننتقل إلى صفحة إنشاء المتجر مع الخطة الافتراضية
                            // يمكن تعديل هذا لاحقاً لاستخدام خطة مختلفة بناء على كود الخصم
                            context.go('/create-store');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.mainColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "ابدأ",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class PackageCard extends StatelessWidget {
  final Package package;
  final bool isHighlighted;

  const PackageCard({
    super.key,
    required this.package,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = this.isHighlighted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.mainColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // اسم الباقة
          Text(
            package.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : AppColors.mainColor,
            ),
          ),
          const SizedBox(height: 10),

          // عدد الأيام
          Text(
            "${package.days} يوم",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isHighlighted ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          // السعر
          Text(
            "${package.price.toStringAsFixed(0)} ج.م",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Colors.white : AppColors.mainColor,
            ),
          ),
          const SizedBox(height: 20),

          // عرض المميزات
          if (package.features.isNotEmpty) ...[
            ...package.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: isHighlighted ? Colors.white : AppColors.mainColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 14,
                          color: isHighlighted ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // زر الاختيار
          ElevatedButton(
            onPressed: () => _handlePackageSelection(context, package),
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighlighted
                  ? Colors.white
                  : AppColors.mainColor,
              foregroundColor: isHighlighted
                  ? AppColors.mainColor
                  : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text("اختر الباقة", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePackageSelection(
    BuildContext context,
    Package package,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب تسجيل الدخول')));
      return;
    }

    final walletService = WalletService();
    final pendingPaymentService = PendingPaymentService();

    // التحقق من وجود دفع معلق نشط
    final existingPayment = await pendingPaymentService.getPendingPayment(
      user.uid,
    );

    if (existingPayment != null && existingPayment.isValid) {
      // إذا كان هناك دفع معلق لنفس الباقة، افتح صفحة إنشاء المتجر مباشرة
      if (existingPayment.packageId == package.id) {
        // الانتقال مباشرة بدون loading
        if (context.mounted) {
          context.go('/create-store');
        }
        return;
      }

      // إذا كان هناك دفع معلق لباقة مختلفة، اسأل المستخدم
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('دفع معلق موجود'),
          content: Text(
            'لديك دفع معلق لباقة "${existingPayment.packageName}".\n\n'
            'هل تريد إلغاء الدفع المعلق والانتقال لباقة "${package.name}"؟',
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
              child: const Text('متابعة'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        // إذا اختار المستخدم عدم المتابعة، افتح صفحة إنشاء المتجر بالدفع المعلق الحالي
        if (context.mounted) {
          context.go('/create-store');
        }
        return;
      }

      // إلغاء الدفع المعلق القديم
      try {
        await pendingPaymentService.cancelPendingPayment(
          existingPayment.id,
          user.uid,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إلغاء الدفع المعلق: ${e.toString()}')),
        );
        return;
      }
    }

    // فحص الرصيد
    final balance = await walletService.getWalletBalance(user.uid);
    if (balance < package.price) {
      // إظهار رسالة وإعادة التوجيه للمحفظة
      final shouldGoToWallet = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('رصيد غير كافٍ'),
          content: Text(
            'رصيدك الحالي: ${balance.toStringAsFixed(2)} جنيه\n'
            'المبلغ المطلوب: ${package.price.toStringAsFixed(2)} جنيه\n\n'
            'يرجى شحن محفظتك أولاً',
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
              child: const Text('شحن المحفظة'),
            ),
          ],
        ),
      );

      if (shouldGoToWallet == true) {
        context.go('/wallet');
      }
      return;
    }

    // إظهار رسالة تأكيد
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الدفع'),
        content: Text(
          'هل أنت متأكد من خصم ${package.price.toStringAsFixed(2)} جنيه من محفظتك لشراء باقة "${package.name}"؟\n\n'
          'بعد الدفع، سيتم توجيهك لصفحة إنشاء المتجر.',
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

    if (confirmed != true) return;

    // إظهار loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // إنشاء الدفع المعلق وخصم المبلغ
      await pendingPaymentService.createPendingPayment(
        userId: user.uid,
        packageId: package.id,
        packageName: package.name,
        amount: package.price,
        days: package.days,
      );

      if (!context.mounted) return;

      // إغلاق جميع dialogs المفتوحة
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // الانتظار قليلاً للتأكد من إغلاق dialog
      await Future.delayed(const Duration(milliseconds: 150));

      // الانتقال مباشرة لصفحة إنشاء المتجر بدون dialog
      if (context.mounted) {
        context.go('/create-store');
      }
    } catch (e) {
      if (!context.mounted) return;
      // إغلاق جميع dialogs المفتوحة
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (e.toString().contains('رصيدك غير كافٍ')) {
        final shouldGoToWallet = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('رصيد غير كافٍ'),
            content: const Text('رصيدك غير كافٍ. يرجى شحن محفظتك أولاً.'),
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
                child: const Text('شحن المحفظة'),
              ),
            ],
          ),
        );

        if (shouldGoToWallet == true) {
          context.go('/wallet');
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الدفع: ${e.toString()}')));
      }
    }
  }
}
