import 'package:flutter/material.dart';
import '../../../theme/app_color.dart';
import '../services/stores_service.dart';

class SuspendDialog {
  static Future<void> show(
    BuildContext context,
    String storeId,
    StoresService service,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.block, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('إيقاف الترخيص', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من إيقاف الترخيص؟ سيتم ضبط الأيام المتبقية على 0.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _suspend(context, storeId, service);
            },
            icon: const Icon(Icons.block),
            label: const Text('إيقاف'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _suspend(
    BuildContext context,
    String storeId,
    StoresService service,
  ) async {
    _showLoadingDialog(context);

    final result = await service.suspendSubscription(storeId);

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
                Text('جاري إيقاف الترخيص...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
