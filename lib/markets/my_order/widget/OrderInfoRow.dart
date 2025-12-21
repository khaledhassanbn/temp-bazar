import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';

class OrderInfoRow extends StatelessWidget {
  final String title;
  final String value;
  const OrderInfoRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$title ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.mainColor,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
