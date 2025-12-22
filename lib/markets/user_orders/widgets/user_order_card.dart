import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bazar_suez/theme/app_color.dart';
import '../services/user_orders_service.dart';
import 'store_rating_dialog.dart';
import 'delivery_rating_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:bazar_suez/services/review_service.dart';

/// كارت عرض طلب المستخدم
class UserOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String orderId;
  final VoidCallback onRatingSubmitted;

  const UserOrderCard({
    super.key,
    required this.order,
    required this.orderId,
    required this.onRatingSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final statusArabic = UserOrdersService.getStatusArabic(status);
    final statusColor = Color(UserOrdersService.getStatusColor(status));

    final createdAt = order['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('d MMMM • h:mm a', 'ar').format(createdAt.toDate())
        : '';

    // اسم المتجر - نحاول جلبه من items أو من حقل منفصل
    final items = order['items'] as List<dynamic>? ?? [];
    String marketName = 'متجر';
    String? marketLogo;
    String marketId = ''; // default empty
    
    // محاولة جلب معلومات المتجر من المنتج الأول
    if (items.isNotEmpty) {
      final firstItem = items[0] as Map<String, dynamic>?;
      marketLogo = firstItem?['productImage'] as String?;
      
      // البحث عن storeId في المنتج
      marketId = firstItem?['storeId'] as String? ??
          firstItem?['marketId'] as String? ??
          firstItem?['marketLink'] as String? ??
          '';
    }
    
    // البحث عن اسم المتجر في الحقول المختلفة
    marketName = order['storeName'] as String? ??
        order['marketName'] as String? ??
        'متجر';
    
    // البحث عن storeId في الطلب نفسه (أولوية أعلى)
    if (order['storeId'] != null && (order['storeId'] as String).isNotEmpty) {
      marketId = order['storeId'] as String;
    } else if (order['marketId'] != null && (order['marketId'] as String).isNotEmpty) {
      marketId = order['marketId'] as String;
    } else if (order['marketLink'] != null && (order['marketLink'] as String).isNotEmpty) {
      marketId = order['marketLink'] as String;
    }

    final totalAmount = (order['totalAmount'] ?? 0.0) as num;

    final storeRating = order['storeRating'] as Map<String, dynamic>?;
    final hasRated = storeRating != null;
    final userRating = storeRating?['rating'] as int?;

    final isCompleted = status.toLowerCase() == 'completed';
    
    // التحقق من إمكانية التقييم (يجب أن يكون هناك storeId)
    final canRate = isCompleted && marketId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - الحالة والتاريخ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusArabic,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // معلومات المتجر
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // شعار المتجر
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[100],
                  ),
                  child: marketLogo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            marketLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.store,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(Icons.store, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                // اسم المتجر ورمز الطلب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marketName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رمز الطلب: ${order['orderId'] ?? orderId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // عدد المنتجات
                Column(
                  children: [
                    Icon(Icons.expand_more, color: Colors.grey[400]),
                    Text(
                      '${items.length} منتج',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // قائمة المنتجات (أول 2 فقط)
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: items.take(2).map((item) {
                  final itemData = item as Map<String, dynamic>;
                  final quantity = itemData['quantity'] ?? 1;
                  final name = itemData['productName'] ?? 'منتج';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: itemData['productImage'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    itemData['productImage'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.fastfood,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.fastfood,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'x$quantity $name',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 1),

          // المبلغ الإجمالي
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // زر اطلب مجدداً
                OutlinedButton(
                  onPressed: marketId.isNotEmpty
                      ? () => context.push('/HomeMarketPage?marketLink=$marketId')
                      : null,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: const BorderSide(color: AppColors.mainColor),
                  ),
                  child: const Text(
                    'اطلب مجدداً',
                    style: TextStyle(
                      color: AppColors.mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // المبلغ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ج.م ${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'تفاصيل الدفع',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // التقييم أو زر التقييم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: hasRated
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'تقييمك $userRating/5',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : canRate
                    ? GestureDetector(
                        onTap: () => _showRatingDialog(context, marketId, marketName, marketLogo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'قيّم الطلب',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : isCompleted && marketId.isEmpty
                        ? Center(
                            child: Text(
                              'لا يمكن التقييم - معرف المتجر غير متوفر',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String storeId, String storeName, String? storeLogo) {
    final reviewService = ReviewService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoreRatingDialog(
        storeName: storeName,
        storeLogo: storeLogo,
        onSubmit: (rating, comment, tags) async {
          try {
            // حفظ تقييم المتجر
            await reviewService.submitStoreRating(
              orderId: orderId,
              storeId: storeId,
              rating: rating,
              comment: comment,
              tags: tags,
              storeName: storeName,
            );

            if (context.mounted) {
              Navigator.pop(context);

              // عرض نافذة تقييم الشحن
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => DeliveryRatingDialog(
                  onSubmit: (deliveryRating, deliveryComment) async {
                    try {
                      await reviewService.submitDeliveryRating(
                        orderId: orderId,
                        rating: deliveryRating,
                        comment: deliveryComment,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('شكراً لتقييمك!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        onRatingSubmitted();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('حدث خطأ: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('حدث خطأ: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
