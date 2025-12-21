import 'package:flutter/material.dart';
import '../../../theme/app_color.dart';

class OfferProductCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final double? price;
  final double? originalPrice;
  final String? discountText;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  const OfferProductCard({
    super.key,
    required this.title,
    this.imageUrl,
    this.price,
    this.originalPrice,
    this.discountText,
    this.onAdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 160, // عرض ثابت للحركة الأفقية
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // صورة المنتج مع زوايا مدورة
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: imageUrl == null
                            ? Image.network(
                                'https://images.pexels.com/photos/1893555/pexels-photo-1893555.jpeg?auto=compress&cs=tinysrgb&w=400',
                                fit: BoxFit.cover,
                              )
                            : Image.network(imageUrl!, fit: BoxFit.cover),
                      ),
                    ),

                    // شارة الخصم
                    if (discountText != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            discountText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // زر الإضافة في اليسار من تحت
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

              // الاسم والسعر
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // السعر مع الخصم
                    if (originalPrice != null && price != null)
                      Row(
                        children: [
                          Text(
                            "${price!.toStringAsFixed(2)} ج.م",
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${originalPrice!.toStringAsFixed(2)} ج.م",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        price != null
                            ? "${price!.toStringAsFixed(2)} ج.م"
                            : "99.00 ج.م",
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color.fromARGB(255, 0, 0, 0),
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
