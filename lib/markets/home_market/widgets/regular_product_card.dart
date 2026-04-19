import 'package:cached_network_image/cached_network_image.dart';
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

    return RepaintBoundary(
      child: Column(
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
                color: Colors.transparent,
                constraints: const BoxConstraints(
                  minHeight: 130,
                  minWidth: double.infinity,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ صورة المنتج مع cache
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl ?? '',
                            height: 160,
                            width: 160,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 160,
                              width: 160,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.mainColor,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 160,
                              width: 160,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            ),
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
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ],
      ),
    );
  }
}
