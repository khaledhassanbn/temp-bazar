import 'package:bazar_suez/theme/app_color.dart';
import 'package:flutter/material.dart';

class AppDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final bool required;
  final ValueChanged<String?>? onChanged;

  const AppDropdownField({
    Key? key,
    required this.label,
    required this.items,
    this.value,
    this.required = false,
    this.onChanged,
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
              color: AppColors.mainColor,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 6),
          Container(
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
            child: DropdownButtonFormField<String>(
              value: value != null && items.contains(value) ? value : null,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              icon: const Icon(Icons.arrow_drop_down),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, textAlign: TextAlign.right),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              validator: (val) {
                if (required && (val == null || val.isEmpty)) {
                  return 'هذا الحقل مطلوب';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
