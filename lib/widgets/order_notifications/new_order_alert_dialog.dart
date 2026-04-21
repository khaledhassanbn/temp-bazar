import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bazar_suez/router/app_navigation.dart';

/// مربع حوار طلب جديد — تصميم حديث بلون primary
class NewOrderAlertDialog extends StatelessWidget {
  final String orderId;
  final String storeId;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const NewOrderAlertDialog({
    super.key,
    required this.orderId,
    required this.storeId,
    required this.onAccept,
    required this.onReject,
  });

  static const Color primary = Color(0xFF4E99B4);
  static const Color primaryDark = Color(0xFF3A7A91);
  static const Color primaryLight = Color(0xFFE8F4F8);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEF2F2);

  @override
  Widget build(BuildContext context) {
    Future<Map<String, dynamic>?> loadOrder() async {
      final doc = await FirebaseFirestore.instance
          .collection('markets')
          .doc(storeId)
          .collection('present_order')
          .doc(orderId)
          .get();
      return doc.data();
    }

    void openOrdersPage() {
      Navigator.of(context).pop();
      navigateToStoreOrders(storeId, orderId: orderId);
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
              color: primary.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primaryDark],
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
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب جديد! 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'يتطلب مراجعتك الآن',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live dot indicator
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Order ID chip
                  GestureDetector(
                    onTap: openOrdersPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primary.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tag_rounded,
                              color: primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'رقم الطلب: $orderId',
                              style: const TextStyle(
                                color: primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: primary, size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Products section
                  FutureBuilder<Map<String, dynamic>?>(
                    future: loadOrder(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return _LoadingPlaceholder();
                      }

                      final items =
                          (snap.data?['items'] as List?)?.cast<dynamic>() ??
                              const [];

                      if (items.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.grey.shade400, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'تفاصيل المنتجات غير متاحة حالياً',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }

                      final preview = items.take(4).toList();
                      final extra = items.length - preview.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section label
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'المنتجات المطلوبة',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Items
                          ...preview.map((raw) {
                            final map = raw is Map ? raw : null;
                            final name =
                                map?['productName']?.toString().trim();
                            final qty = map?['quantity'];
                            final qtyText = (qty is num)
                                ? qty.toString()
                                : (qty?.toString() ?? '1');
                            final label = (name != null && name.isNotEmpty)
                                ? name
                                : 'منتج';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: primaryLight,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: primary,
                                        size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [primary, primaryDark],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '× $qtyText',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          if (extra > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '+ $extra منتجات أخرى...',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Divider ─────────────────────────────────────────
            Divider(height: 1, color: Colors.grey.shade100),

            // ── Actions ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  // View button
                  TextButton.icon(
                    onPressed: openOrdersPage,
                    icon: const Icon(Icons.open_in_new_rounded,
                        size: 16, color: primary),
                    label: const Text(
                      'عرض',
                      style: TextStyle(
                          color: primary, fontWeight: FontWeight.w700),
                    ),
                  ),

                  const Spacer(),

                  // Reject button
                  OutlinedButton(
                    onPressed: () async => onReject(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: danger,
                      side: const BorderSide(color: danger, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('رفض',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Accept button
                  ElevatedButton(
                    onPressed: () async => onAccept(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('قبول',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
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

/// Skeleton loading placeholder
class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}