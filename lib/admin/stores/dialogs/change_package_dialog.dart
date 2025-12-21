import 'package:flutter/material.dart';
import '../services/stores_service.dart';
import 'renewal_dialog.dart';

class ChangePackageDialog {
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.swap_horiz, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('اختر الباقة الجديدة', style: TextStyle(fontSize: 18)),
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
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.grey.shade300,
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
                        color: isSelected ? Colors.orange : Colors.white,
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
                            color: Colors.orange,
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
              label: const Text('تغيير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
}
