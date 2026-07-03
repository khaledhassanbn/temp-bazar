import 'package:flutter/material.dart';
import 'instashop_ground_shadow.dart';

/// ويدجت توضيحية تعرض كيفية دمج واستخدام ظل المنتجات الاحترافي أسفل صورة المنتج.
/// An example widget demonstrating how to integrate and use the contact shadow under a product image.
class ExampleProductWithShadow extends StatelessWidget {
  const ExampleProductWithShadow({super.key});

  @override
  Widget build(BuildContext context) {
    // تحديد أبعاد الصورة والظل المناسبة للمنتج
    // Define appropriate dimensions for the product image and shadow
    const double imageSize = 160.0;
    const double shadowWidth = imageSize * 0.95; // جعل عرض الظل متناسبًا مع حجم المنتج

    return Center(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // استخدام Stack لوضع الظل خلف الصورة وفي الأسفل تماماً
            // Using Stack to place the shadow behind the image and precisely at the bottom
            SizedBox(
              width: imageSize,
              height: imageSize + 15, // إضافة مساحة إضافية للظل في الأسفل
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 1. وضع الظل أولاً ليكون خلف الصورة (في الخلفية)
                  // 1. Place the shadow first so it renders behind the image
                  const Positioned(
                    bottom: 0, // وضعه في الأسفل تماماً
                    child: InstashopGroundShadow(
                      width: shadowWidth,
                      tint: Colors.black,
                      intensity: 0.85, // التحكم في شفافية وقوة الظل
                    ),
                  ),

                  // 2. وضع صورة المنتج فوق الظل
                  // 2. Place the product image on top of the shadow
                  Positioned(
                    bottom: 10, // رفعه قليلاً لأعلى حتى يظهر الظل تحته مباشرة
                    child: Image.asset(
                      'assets/images/logo.png', // استبدل هذا المسار بمسار صورة منتجك الفعلي (e.g. assets/images/product.png)
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.contain,
                      // معالج للأخطاء في حالة عدم وجود الصورة لتجنب انهيار التطبيق أثناء تجربة الكود
                      // Error builder in case the asset does not exist to avoid crashes during development
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: imageSize * 0.4,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            // تفاصيل منتج تجريبية
            // Dummy product details
            const Text(
              'منتج تجريبي مميز',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              '99.99 \$',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
