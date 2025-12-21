import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'restaurant_column.dart';
import 'restaurant_card.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // 🔹 موجة علوية خفيفة جدًا
    path.moveTo(0, 10);
    path.quadraticBezierTo(size.width * 0.25, 5, size.width * 0.5, 10);
    path.quadraticBezierTo(size.width * 0.75, 15, size.width, 10);

    // 🔹 الخط الجانبي
    path.lineTo(size.width, size.height - 10);

    // 🔹 موجة سفلية خفيفة جدًا
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 5,
      size.width * 0.5,
      size.height - 10,
    );
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 15,
      0,
      size.height - 10,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BestRestaurantsSection extends StatelessWidget {
  final String title;
  final List<List<RestaurantCard>> data;

  const BestRestaurantsSection({
    super.key,
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        width: double.infinity,
        height: 410,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.mainColor, AppColors.mainColor.withOpacity(0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 40,
                left: 12,
                right: 12,
                bottom: 8,
              ), // زيادة padding من الأعلى
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: data
                    .map((col) => RestaurantColumn(restaurants: col))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
