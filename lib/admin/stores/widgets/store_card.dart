import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_color.dart';
import '../services/stores_service.dart';
import 'store_info_card.dart';
import 'store_actions_button.dart';

class StoreCard extends StatelessWidget {
  final String marketId;
  final Map<String, dynamic> data;
  final StoresService service;

  const StoreCard({
    super.key,
    required this.marketId,
    required this.data,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: service.getUserDataByMarketId(marketId),
      builder: (context, userSnapshot) {
        return FutureBuilder<int>(
          future: service.getProductCount(marketId, data),
          builder: (context, productSnapshot) {
            final userData = userSnapshot.data;
            final productCount = productSnapshot.data ?? 0;

            // حساب الأيام المتبقية
            int daysRemaining = 0;
            bool isActive = data['isActive'] == true;
            DateTime? licenseEndAt;

            if (data['licenseEndAt'] != null) {
              licenseEndAt = (data['licenseEndAt'] as Timestamp).toDate();
              final now = DateTime.now();
              if (licenseEndAt.isAfter(now)) {
                daysRemaining = licenseEndAt.difference(now).inDays;
              } else {
                daysRemaining = 0;
              }
            }

            // الحصول على اسم الباقة
            String planName = data['currentPackageName'] ?? 'غير محدد';

            // تحديد لون الحالة
            Color statusColor = isActive ? Colors.green : Colors.red;
            Color daysColor = daysRemaining > 7
                ? Colors.green
                : daysRemaining > 3
                ? Colors.orange
                : Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      isActive
                          ? Colors.green.withOpacity(0.05)
                          : Colors.red.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رأس البطاقة
                      Row(
                        children: [
                          // أيقونة المتجر
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.store,
                              color: AppColors.mainColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // اسم المتجر والحالة
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'بدون اسم',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userData?['firstName'] != null &&
                                          userData?['lastName'] != null
                                      ? '${userData!['firstName']} ${userData['lastName']}'
                                      : userData?['email'] ?? 'غير محدد',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // شارة الحالة
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.cancel,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isActive ? 'مفعل' : 'غير مفعل',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      // معلومات المتجر
                      Row(
                        children: [
                          Expanded(
                            child: StoreInfoCard(
                              icon: Icons.phone,
                              label: 'الهاتف',
                              value: data['phone'] ?? 'غير محدد',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StoreInfoCard(
                              icon: Icons.inventory,
                              label: 'المنتجات',
                              value: '$productCount',
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: StoreInfoCard(
                              icon: Icons.card_membership,
                              label: 'الباقة',
                              value: planName,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StoreInfoCard(
                              icon: Icons.calendar_today,
                              label: 'الأيام المتبقية',
                              value: '$daysRemaining يوم',
                              color: daysColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // زر الإجراءات
                      StoreActionsButton(marketId: marketId, service: service),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
