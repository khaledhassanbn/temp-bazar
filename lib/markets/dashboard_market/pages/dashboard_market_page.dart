import 'dart:ui' as ui;

import 'package:bazar_suez/markets/license/services/license_service.dart';
import 'package:bazar_suez/markets/planes/models/package.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_color.dart';
import '../models/dashboard_market_model.dart';
import '../viewmodels/dashboard_market_viewmodel.dart';
import '../widgets/top_products_chart.dart';

class DashboardMarketPage extends StatefulWidget {
  final String? marketId;

  const DashboardMarketPage({super.key, this.marketId});

  @override
  State<DashboardMarketPage> createState() => _DashboardMarketPageState();
}

class _DashboardMarketPageState extends State<DashboardMarketPage> {
  late final DashboardMarketViewModel _viewModel;
  final LicenseService _licenseService = LicenseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _processingPackageId;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardMarketViewModel()..load(marketId: widget.marketId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('لوحة تحكم المتجر'),
            backgroundColor: AppColors.mainColor,
          ),
          body: Consumer<DashboardMarketViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.errorMessage != null) {
                return _ErrorView(
                  message: vm.errorMessage!,
                  onRetry: () => vm.load(marketId: widget.marketId),
                );
              }
              final data = vm.data;
              if (data == null) {
                return const Center(child: Text('لا توجد بيانات متاحة'));
              }
              return RefreshIndicator(
                onRefresh: () => vm.load(marketId: widget.marketId),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _PackageCard(data: data),
                    const SizedBox(height: 12),
                    _StatsGrid(data: data),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'المنتجات والمبيعات',
                      child: TopProductsChart(points: data.topProducts),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'الباقات المتاحة',
                      child: Column(
                        children: data.availablePackages.map((pkg) {
                          final isProcessing = _processingPackageId == pkg.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pkg.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text('${pkg.days} يوم'),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${pkg.price.toStringAsFixed(0)} ج.م',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.mainColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: isProcessing
                                      ? null
                                      : () => _subscribeFromDashboard(
                                          package: pkg,
                                          marketId: data.marketId,
                                        ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.mainColor,
                                  ),
                                  child: isProcessing
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('اشترك'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _subscribeFromDashboard({
    required Package package,
    required String marketId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يجب تسجيل الدخول أولاً')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الاشتراك'),
        content: Text(
          'هل تريد الاشتراك في باقة "${package.name}" بقيمة ${package.price.toStringAsFixed(2)} ج.م؟',
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
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingPackageId = package.id);
    try {
      await _licenseService.renewWithPackage(
        marketId: marketId,
        package: package,
        userId: user.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم الاشتراك في باقة ${package.name} بنجاح')),
      );
      await _viewModel.load(marketId: widget.marketId);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      if (message.contains('رصيدك غير كافٍ')) {
        final goToWallet = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('رصيد غير كافٍ'),
            content: const Text(
              'رصيد المحفظة غير كافٍ. هل تريد الانتقال لشحن المحفظة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لاحقاً'),
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
        if (goToWallet == true && mounted) {
          context.go('/wallet');
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشل الاشتراك: $message')));
      }
    } finally {
      if (mounted) {
        setState(() => _processingPackageId = null);
      }
    }
  }
}

class _PackageCard extends StatelessWidget {
  final DashboardMarketModel data;
  const _PackageCard({required this.data});

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return DateFormat('dd MMM yyyy', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mainColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'معلومات الباقة الحالية',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.currentPackageName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تاريخ البدء: ${_formatDate(data.packageStartAt)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'تاريخ الانتهاء: ${_formatDate(data.packageEndAt)}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأيام المتبقية: ${data.remainingDays}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                data.isPackageActive ? 'الحالة: نشط' : 'الحالة: غير نشط',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: data.packageProgress,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'النسبة: ${(data.packageProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white),
          ),
          const Divider(color: Colors.white30),
          Text(
            'الرصيد الحالي للتطبيق: ${data.walletBalance.toStringAsFixed(2)} ج.م',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/wallet'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('شحن المحفظة'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardMarketModel data;
  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 1.5,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _StatCard(
          title: 'إجمالي المنتجات',
          value: data.totalProducts.toString(),
          icon: Icons.inventory_2_outlined,
        ),
        _StatCard(
          title: 'مبيعات الأسبوع',
          value: data.weeklySalesCount.toString(),
          icon: Icons.shopping_cart_checkout_outlined,
        ),
        _StatCard(
          title: 'إجمالي الإيرادات الشهرية',
          value: '${data.monthlyRevenue.toStringAsFixed(0)} ج.م',
          icon: Icons.payments_outlined,
        ),
        _StatCard(
          title: 'التقييم',
          value: data.rating.toStringAsFixed(1),
          icon: Icons.star_outline,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.mainColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
