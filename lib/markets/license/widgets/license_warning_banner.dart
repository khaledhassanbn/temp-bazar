import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../create_market/models/store_model.dart';

/// بانر تحذيري يظهر أسفل الـ AppBar مباشرة
/// يظهر دائماً عندما يتبقى 3 أيام أو أقل على انتهاء الترخيص
class LicenseWarningBanner extends StatelessWidget {
  final StoreModel store;
  final VoidCallback? onRenewTap;

  const LicenseWarningBanner({
    super.key,
    required this.store,
    this.onRenewTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = store.daysUntilExpiry;
    final isExpired = store.isLicenseExpired;

    // يظهر فقط إذا كان باقي 3 أيام أو أقل أو منتهي
    if (!isExpired && daysLeft > 3) {
      return const SizedBox.shrink();
    }

    String message;
    if (isExpired) {
      message = 'انتهى ترخيص متجرك "${store.name}"';
    } else if (daysLeft == 0) {
      message = 'ينتهي ترخيص متجرك "${store.name}" اليوم!';
    } else if (daysLeft == 1) {
      message = 'يتبقى في ترخيص "${store.name}" يوم واحد';
    } else {
      message = 'يتبقى في ترخيص "${store.name}" $daysLeft أيام';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFE53935), // أحمر
      ),
      child: Row(
        children: [
          // زر إغلاق (X)
          GestureDetector(
            onTap: () {
              // يمكن إضافة منطق لإخفاء البانر مؤقتاً
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          // النص
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isExpired ? 'انتهى ترخيص متجرك' : 'اقترب موعد تجديد المتجر',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // زر تجديد المتجر
          GestureDetector(
            onTap: onRenewTap ?? () {
              context.push('/license-status');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'تجديد المتجر',
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overlay يحجب الصفحة بالكامل عند انتهاء الترخيص
/// يمنع أي تفاعل مع الصفحة ويعرض رسالة مع زر التجديد
class LicenseExpiredOverlay extends StatelessWidget {
  final StoreModel store;
  final VoidCallback? onRenewTap;

  const LicenseExpiredOverlay({
    super.key,
    required this.store,
    this.onRenewTap,
  });

  @override
  Widget build(BuildContext context) {
    // لا يظهر إذا الترخيص ساري
    if (!store.isLicenseExpired) {
      return const SizedBox.shrink();
    }

    final expiryDate = store.licenseEndAt != null
        ? '${store.licenseEndAt!.day}/${store.licenseEndAt!.month}/${store.licenseEndAt!.year}'
        : 'غير محدد';

    return Stack(
      children: [
        // ModalBarrier لمنع التفاعل
        const ModalBarrier(
          dismissible: false,
          color: Colors.black54,
        ),
        // محتوى الـ Overlay
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer_off_outlined,
                    size: 60,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                // العنوان
                const Text(
                  'انتهى ترخيص متجرك',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                // التفاصيل
                Text(
                  'انتهى الترخيص في: $expiryDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لن يظهر متجرك للعملاء حتى تقوم بتجديد الترخيص',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                // زر التجديد
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRenewTap ?? () {
                      context.push('/license-status');
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'تجديد الترخيص الآن',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact version for use in smaller spaces
class LicenseWarningChip extends StatelessWidget {
  final StoreModel store;

  const LicenseWarningChip({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final daysLeft = store.daysUntilExpiry;
    final isExpired = store.isLicenseExpired;

    if (!isExpired && daysLeft > 3) {
      return const SizedBox.shrink();
    }

    Color color;
    String label;

    if (isExpired) {
      color = Colors.red;
      label = 'منتهي';
    } else if (daysLeft <= 1) {
      color = Colors.red;
      label = daysLeft == 0 ? 'اليوم' : 'غداً';
    } else {
      color = Colors.orange;
      label = '$daysLeft أيام';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
