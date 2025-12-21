import 'package:flutter/material.dart';
import '../../../theme/app_color.dart';
//دا الكلاس بتاع gird الاكثر مبيعاً

class ChoiceProductCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final double? price;
  final double? originalPrice;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  const ChoiceProductCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.price,
    this.originalPrice,
    this.onAdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount =
        originalPrice != null &&
        price != null &&
        price! < originalPrice! &&
        originalPrice! > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min, // ✅ يمنع التمدد اللانهائي
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ صورة المنتج
              Flexible(
                fit: FlexFit.loose, // ✅ بديل آمن لـ Expanded
                child: AspectRatio(
                  aspectRatio: 1, // يجعل الصورة مربعة ومتناسقة في GridView
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl ??
                                'https://images.pexels.com/photos/1893555/pexels-photo-1893555.jpeg?auto=compress&cs=tinysrgb&w=400',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // ✅ زر الإضافة
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: InkWell(
                          onTap: onAdd,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              color: AppColors.mainColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ✅ الاسم والسعر
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasDiscount)
                      Row(
                        children: [
                          Text(
                            "${originalPrice!.toStringAsFixed(2)} ج.م",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${price!.toStringAsFixed(2)} ج.م",
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        price != null
                            ? "${price!.toStringAsFixed(2)} ج.م"
                            : "70.00 ج.م",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
