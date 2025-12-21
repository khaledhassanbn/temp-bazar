import 'package:flutter/material.dart';
import '../../../theme/app_color.dart';

class RegularProductCard extends StatelessWidget {
  final String productName;
  final String productDescription;
  final String? imageUrl;
  final double? price;
  final double? discountPrice;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;
  final double topMargin;

  const RegularProductCard({
    super.key,
    required this.productName,
    required this.productDescription,
    this.imageUrl,
    this.price,
    this.discountPrice,
    this.onAdd,
    this.onTap,
    this.topMargin = 6,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount =
        discountPrice != null && discountPrice! < (price ?? 0);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: topMargin,
            left: 12,
            right: 12,
            bottom: 6,
          ),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              // الخلفية شفافة بدون ظل
              color: Colors.transparent,
              // 🔽 يمكنك التحكم في الطول والعرض من هنا:
              constraints: const BoxConstraints(
                minHeight: 130, // 👈 غيّر الرقم لتكبير أو تصغير الارتفاع
                minWidth: double.infinity, // 👈 يمتد بعرض الشاشة
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ صورة المنتج
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl ??
                              'https://images.pexels.com/photos/70497/pexels-photo-70497.jpeg?auto=compress&cs=tinysrgb&w=400',
                          height:
                              160, // 👈 غيّر الرقم لتكبير أو تصغير ارتفاع الصورة
                          width:
                              160, // 👈 غيّر الرقم لتكبير أو تصغير عرض الصورة
                          fit: BoxFit.cover,
                        ),
                      ),

                      // ✅ زر الإضافة
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.mainColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // ✅ التفاصيل النصية
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            productName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            productDescription,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),

                          // ✅ السعر
                          Align(
                            alignment: Alignment.centerRight,
                            child: hasDiscount
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${price?.toStringAsFixed(2) ?? '0.00'} ج.م",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "${discountPrice?.toStringAsFixed(2)} ج.م",
                                        style: const TextStyle(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    "${price?.toStringAsFixed(2) ?? '99.00'} ج.م",
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ خط فاصل رمادي فاتح بين كل منتج واللي بعده
        Container(
          height: 1,
          color: Colors.grey.shade300, // 👈 لون الخط الفاصل
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ],
    );
  }
}
