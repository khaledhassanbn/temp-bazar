import 'package:flutter/material.dart';
import '../../../theme/app_color.dart';
import '../services/stores_service.dart';

class RenewalDialog {
  static Future<void> show(
    BuildContext context,
    String storeId,
    StoresService service,
  ) async {
    final packagesSnapshot = await service.getPackages();

    if (packagesSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا توجد باقات متاحة')));
      return;
    }

    String? selectedPackageId;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh, color: AppColors.mainColor),
              ),
              const SizedBox(width: 12),
              const Text('اختر الباقة للتجديد', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: packagesSnapshot.docs.length,
              itemBuilder: (context, index) {
                final packageDoc = packagesSnapshot.docs[index];
                final packageData = packageDoc.data() as Map<String, dynamic>?;
                final packageId = packageDoc.id;
                final packageName =
                    packageData?['name'] as String? ?? 'بدون اسم';
                final days = packageData?['days'] as int? ?? 0;
                final price = packageData?['price'] as num? ?? 0;
                final isSelected = selectedPackageId == packageId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mainColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.mainColor
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.mainColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.card_membership,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    title: Text(
                      packageName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('$days يوم'),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.grey,
                          ),
                          Text('$price ج.م'),
                        ],
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.mainColor,
                            size: 28,
                          )
                        : const Icon(
                            Icons.circle_outlined,
                            color: Colors.grey,
                            size: 28,
                          ),
                    onTap: () {
                      setDialogState(() {
                        selectedPackageId = packageId;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: selectedPackageId == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await RenewalDialog.renewSubscription(
                        context,
                        storeId,
                        selectedPackageId!,
                        service,
                      );
                    },
              icon: const Icon(Icons.check),
              label: const Text('تجديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> renewSubscription(
    BuildContext context,
    String storeId,
    String packageId,
    StoresService service,
  ) async {
    _showLoadingDialog(context);

    final result = await service.renewSubscription(storeId, packageId);

    if (context.mounted) {
      Navigator.pop(context);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result['success'] == true ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(result['message'])),
            ],
          ),
          backgroundColor: result['success'] == true
              ? Colors.green
              : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.mainColor),
                SizedBox(height: 16),
                Text('جاري التجديد...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
