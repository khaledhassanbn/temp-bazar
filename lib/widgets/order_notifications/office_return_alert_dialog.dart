import 'package:flutter/material.dart';
import 'package:bazar_suez/router/app_navigation.dart';

/// تنبيه التاجر عندما يرجع المكتب الطلب — نفس أسلوب [NewOrderAlertDialog] مبسّط.
class OfficeReturnAlertDialog extends StatelessWidget {
  final String orderDocumentId;
  final String storeId;

  const OfficeReturnAlertDialog({
    super.key,
    required this.orderDocumentId,
    required this.storeId,
  });

  static const Color accent = Color(0xFFB45309);
  static const Color accentDark = Color(0xFF92400E);
  static const Color surface = Color(0xFFFFF7ED);

  @override
  Widget build(BuildContext context) {
    void openOrdersPage() {
      Navigator.of(context).pop();
      navigateToStoreOrders(storeId, orderId: orderDocumentId);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.2),
              blurRadius: 32,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.store_mall_directory_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المكتب رفض الطلب',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'يمكنك اختيار مكتب آخر أو التسليم بنفسك من صفحة الطلبات',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: openOrdersPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accent.withOpacity(0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag_rounded, color: accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'رقم الطلب: $orderDocumentId',
                          style: const TextStyle(
                            color: accentDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: accent, size: 14),
                    ],
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: openOrdersPage,
                    icon: const Icon(Icons.open_in_new_rounded,
                        size: 18, color: accent),
                    label: const Text(
                      'عرض الطلب',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حسناً',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
