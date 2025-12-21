import 'package:flutter/material.dart';

class CustomBackIcon extends StatelessWidget {
  final VoidCallback onTap;

  const CustomBackIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        // 🔹 نستخدم Transform علشان السهم يفضل ناحيه اليسار دايمًا
        child: Transform.rotate(
          angle: 0, // ممكن نحط pi لتبديل الاتجاه، بس هنا هنخليه ثابت
          child: const Icon(
            Icons.arrow_back, // ✅ السهم الكلاسيكي
            color: Colors.black87,
            size: 23,
            textDirection: TextDirection.ltr, // دايمًا لليسار
          ),
        ),
      ),
    );
  }
}
