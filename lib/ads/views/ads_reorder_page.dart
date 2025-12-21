import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_color.dart';
import '../viewmodels/ads_reorder_viewmodel.dart';
import '../widgets/reorderable_ad_card.dart';
import '../widgets/loading_snackbar.dart';

class AdsReorderPage extends StatelessWidget {
  const AdsReorderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdsReorderViewModel()..loadAds(),
      child: const _AdsReorderView(),
    );
  }
}

class _AdsReorderView extends StatelessWidget {
  const _AdsReorderView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'ترتيب الإعلانات',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
          elevation: 0,
        ),
        body: Consumer<AdsReorderViewModel>(
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
              return const Center(child: Text('لا توجد إعلانات نشطة'));
            }

            if (viewModel.isSaving) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LoadingSnackBar.show(context, 'جاري حفظ الترتيب...');
              });
            } else {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LoadingSnackBar.hide(context);
              });
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.ads.length,
              onReorder: viewModel.reorderAds,
              itemBuilder: (context, index) {
                final ad = viewModel.ads[index];
                return ReorderableAdCard(
                  key: ValueKey('reorder_ad_${ad.slotId}_$index'),
                  ad: ad,
                  index: index,
                );
              },
            );
          },
        ),
      ),
    );
  }
}



