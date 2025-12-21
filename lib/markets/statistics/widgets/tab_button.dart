import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';

class TabButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPickDate;

  const TabButton({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        onPickDate();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.mainColor
              : AppColors.mainColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
