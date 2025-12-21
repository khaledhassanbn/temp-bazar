import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool required;
  final TextInputType keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextEditingController? controller;
  final int maxLines;

  const AppTextField({
    Key? key,
    required this.label,
    this.hint,
    this.required = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
    this.inputFormatters,
    this.controller,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.mainColor, // ✅ اللون من AppColors
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 3),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.2), // ✅ ظل من AppColors
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              maxLength: maxLength,
              keyboardType: keyboardType,
              maxLines: maxLines,
              inputFormatters: inputFormatters,
              validator: (value) {
                if (required && (value == null || value.trim().isEmpty)) {
                  return 'هذا الحقل مطلوب';
                }
                return null;
              },
              onChanged: onChanged,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                counterText: "",
                filled: true,
                fillColor: AppColors.white, // ✅ خلفية من AppColors
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
        ],
      ),
    );
  }
}
