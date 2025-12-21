import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';

class SectionTitleWidget extends StatelessWidget {
  final String title;

  const SectionTitleWidget({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.mainColor,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}
