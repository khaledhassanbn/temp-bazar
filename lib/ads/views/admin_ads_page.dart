import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/guards/AuthGuard.dart';
import '../../theme/app_color.dart';
import '../viewmodels/admin_ads_viewmodel.dart';
import '../widgets/ad_slot_card.dart';
import '../widgets/loading_snackbar.dart';
import 'ads_reorder_page.dart';

class AdminAdsPage extends StatelessWidget {
  const AdminAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authGuard = context.watch<AuthGuard>();

    if (authGuard.userStatus != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('غير مصرح'),
          backgroundColor: AppColors.mainColor,
        ),
        body: const Center(child: Text('غير مصرح لك بالوصول إلى هذه الصفحة')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => AdminAdsViewModel()..loadData(),
      child: const _AdminAdsView(),
    );
  }
}

class _AdminAdsView extends StatelessWidget {
  const _AdminAdsView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'إدارة الإعلانات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_vert),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdsReorderPage(),
                  ),
                ).then((_) {
                  context.read<AdminAdsViewModel>().loadData();
                });
              },
              tooltip: 'ترتيب الإعلانات',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _handleAddNewAd(context),
              tooltip: 'إضافة إعلان جديد',
            ),
          ],
        ),
        body: Consumer<AdminAdsViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LoadingSnackBar.showError(context, viewModel.errorMessage!);
                viewModel.clearError();
              });
            }

            if (viewModel.ads.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => viewModel.loadData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد إعلانات فعالة',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _handleAddNewAd(context),
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة إعلان جديد'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => viewModel.loadData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.ads.length,
                itemBuilder: (context, index) {
                  final ad = viewModel.ads[index];
                  return AdSlotCard(
                    key: ValueKey('ad_${ad.slotId}_$index'),
                    ad: ad,
                    stores: viewModel.stores,
                    onPickImage: () => _handlePickImage(context, ad.slotId),
                    onSave: (updatedAd) => _handleSaveAd(context, updatedAd),
                    onDelete: () => _handleDeleteAd(context, ad.slotId),
                    onToggleStatus: () =>
                        _handleToggleStatus(context, ad.slotId, ad.isActive),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAddNewAd(BuildContext context) async {
    final viewModel = context.read<AdminAdsViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة إعلان جديد'),
        content: const Text('هل تريد إضافة إعلان جديد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LoadingSnackBar.show(context, 'جاري إضافة الإعلان...');
      final success = await viewModel.addNewAd();
      LoadingSnackBar.hide(context);

      if (success) {
        LoadingSnackBar.showSuccess(context, 'تم إضافة الإعلان بنجاح');
      } else {
        LoadingSnackBar.showError(
          context,
          viewModel.errorMessage ?? 'فشل إضافة الإعلان',
        );
      }
    }
  }

  Future<void> _handleDeleteAd(BuildContext context, int slotId) async {
    final viewModel = context.read<AdminAdsViewModel>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الإعلان'),
        content: const Text('هل أنت متأكد من حذف هذا الإعلان؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LoadingSnackBar.show(context, 'جاري حذف الإعلان...');
      final success = await viewModel.deleteAd(slotId);
      LoadingSnackBar.hide(context);

      if (success) {
        LoadingSnackBar.showSuccess(context, 'تم حذف الإعلان بنجاح');
      } else {
        LoadingSnackBar.showError(
          context,
          viewModel.errorMessage ?? 'فشل حذف الإعلان',
        );
      }
    }
  }

  Future<void> _handleToggleStatus(
    BuildContext context,
    int slotId,
    bool isActive,
  ) async {
    final viewModel = context.read<AdminAdsViewModel>();

    LoadingSnackBar.show(context, 'جاري تحديث حالة الإعلان...');
    final success = await viewModel.toggleAdStatus(slotId, isActive);
    LoadingSnackBar.hide(context);

    if (success) {
      LoadingSnackBar.showSuccess(
        context,
        isActive ? 'تم إيقاف الإعلان' : 'تم تفعيل الإعلان',
      );
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل تغيير حالة الإعلان',
      );
    }
  }

  Future<void> _handlePickImage(BuildContext context, int slotId) async {
    final viewModel = context.read<AdminAdsViewModel>();

    LoadingSnackBar.show(context, 'جاري رفع الصورة...');
    final imageUrl = await viewModel.pickAndUploadImage(slotId);
    LoadingSnackBar.hide(context);

    if (imageUrl != null) {
      LoadingSnackBar.showSuccess(context, 'تم رفع الصورة بنجاح');
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل رفع الصورة',
      );
    }
  }

  Future<void> _handleSaveAd(BuildContext context, ad) async {
    final viewModel = context.read<AdminAdsViewModel>();

    LoadingSnackBar.show(context, 'جاري حفظ الإعلان...');
    final success = await viewModel.saveAd(ad);
    LoadingSnackBar.hide(context);

    if (success) {
      LoadingSnackBar.showSuccess(context, 'تم حفظ الإعلان بنجاح');
    } else {
      LoadingSnackBar.showError(
        context,
        viewModel.errorMessage ?? 'فشل حفظ الإعلان',
      );
    }
  }
}



