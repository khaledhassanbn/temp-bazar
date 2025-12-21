import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSearch;

  const AppSearchField({
    Key? key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search, // ✅ يخلي زرار البحث يظهر
          onFieldSubmitted: (_) {
            if (onSearch != null) onSearch!();
          },
          onChanged: onChanged,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            counterText: "",
            filled: true,
            fillColor: AppColors.white,
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.mainColor,
            ), // ✅ أيقونة البحث
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
