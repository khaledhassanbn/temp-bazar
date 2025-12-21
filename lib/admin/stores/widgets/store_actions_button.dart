import 'package:flutter/material.dart';
import '../../../theme/app_color.dart';
import '../services/stores_service.dart';
import '../dialogs/renewal_dialog.dart';
import '../dialogs/change_package_dialog.dart';
import '../dialogs/add_days_dialog.dart';
import '../dialogs/suspend_dialog.dart';

class StoreActionsButton extends StatelessWidget {
  final String marketId;
  final StoresService service;

  const StoreActionsButton({
    super.key,
    required this.marketId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'renew':
              RenewalDialog.show(context, marketId, service);
              break;
            case 'change':
              ChangePackageDialog.show(context, marketId, service);
              break;
            case 'addDays':
              AddDaysDialog.show(context, marketId, service);
              break;
            case 'suspend':
              SuspendDialog.show(context, marketId, service);
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.mainColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.mainColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.more_vert, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'إدارة الترخيص',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
            ],
          ),
        ),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'renew',
            child: Row(
              children: [
                Icon(Icons.refresh, color: AppColors.mainColor, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'تجديد',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'change',
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'تغيير الباقة',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'addDays',
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'إضافة أيام',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'suspend',
            child: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'إيقاف الترخيص',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.white,
      ),
    );
  }
}
