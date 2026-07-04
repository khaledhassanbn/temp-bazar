import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_color.dart';
import '../viewmodels/my_ads_viewmodel.dart';
import '../widgets/loading_snackbar.dart';

class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyAdsViewModel()..loadAll(),
      child: const _MyAdsView(),
    );
  }
}

class _MyAdsView extends StatelessWidget {
  const _MyAdsView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'إعلاناتي',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.mainColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'طلب إعلان جديد',
              onPressed: () => context.push('/request-ads'),
            ),
          ],
        ),
        body: Consumer<MyAdsViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                LoadingSnackBar.showError(context, vm.errorMessage!);
                vm.clearError();
              });
            }

            return RefreshIndicator(
              onRefresh: () => vm.loadAll(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionTitle(title: 'الطلبات', icon: Icons.pending_actions),
                  if (vm.requests.isEmpty)
                    _EmptyHint(text: 'لا توجد طلبات إعلان')
                  else
                    ...vm.requests.map(
                      (req) => _RequestTile(request: req, vm: vm),
                    ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'إعلانات نشطة', icon: Icons.campaign),
                  if (vm.activeAds.isEmpty)
                    _EmptyHint(text: 'لا توجد إعلانات نشطة')
                  else
                    ...vm.activeAds.map(
                      (ad) => _ActiveAdCard(ad: ad, vm: vm),
                    ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'إعلانات منتهية', icon: Icons.history),
                  if (vm.expiredAds.isEmpty)
                    _EmptyHint(text: 'لا توجد إعلانات منتهية')
                  else
                    ...vm.expiredAds.map(
                      (ad) => _ExpiredAdTile(ad: ad),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mainColor, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(text, style: TextStyle(color: Colors.grey[600])),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final dynamic request;
  final MyAdsViewModel vm;

  const _RequestTile({required this.request, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: request.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  request.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.image),
        title: Text(request.storeName ?? 'طلب إعلان'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vm.getStatusText(request.status)),
            if (request.rejectionReason != null)
              Text(
                'السبب: ${request.rejectionReason}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            if (request.status == 'rejected')
              Text(
                request.refunded ? 'تم استرداد المبلغ ✅' : 'لم يُسترد المبلغ',
                style: TextStyle(
                  fontSize: 12,
                  color: request.refunded ? Colors.green : Colors.orange,
                ),
              ),
          ],
        ),
        trailing: Text('${request.totalPrice.toStringAsFixed(0)} ج'),
      ),
    );
  }
}

class _ActiveAdCard extends StatelessWidget {
  final dynamic ad;
  final MyAdsViewModel vm;

  const _ActiveAdCard({required this.ad, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ad.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  ad.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              vm.formatRemaining(ad),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.mainColor,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: vm.remainingProgress(ad),
              backgroundColor: Colors.grey[200],
              color: AppColors.mainColor,
            ),
            const SizedBox(height: 8),
            if (ad.startTime != null && ad.expiryDate != null)
              Text(
                'من ${_formatDate(ad.startTime!)} إلى ${_formatDate(ad.expiryDate!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      LoadingSnackBar.show(context, 'جاري رفع الصورة...');
                      final ok = await vm.changeAdImage(ad.slotId);
                      LoadingSnackBar.hide(context);
                      if (context.mounted) {
                        LoadingSnackBar.showSuccess(
                          context,
                          ok ? 'تم تحديث الصورة' : 'فشل تحديث الصورة',
                        );
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('تغيير الصورة'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context, ad.slotId, vm),
                    icon: const Icon(Icons.delete),
                    label: const Text('حذف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    int slotId,
    MyAdsViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ تحذير: حذف الإعلان نهائي'),
        content: const Text(
          'سيتم حذف إعلانك فوراً ولن تتمكن من استرجاع المبلغ المدفوع.\n\nهل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائياً'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await vm.deleteAd(slotId);
    }
  }
}

class _ExpiredAdTile extends StatelessWidget {
  final dynamic ad;

  const _ExpiredAdTile({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ad.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ad.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(Icons.history),
        title: Text(ad.ownerName ?? 'إعلان منتهي'),
        subtitle: ad.expiryDate != null
            ? Text('انتهى ${_formatDate(ad.expiryDate!)}')
            : null,
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
