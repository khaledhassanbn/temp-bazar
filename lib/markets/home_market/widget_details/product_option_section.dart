import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';

class ProductOptionSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final bool isRequired;
  final Map<String, String?> selectedOptions;
  final void Function(String title, String name, double price, bool selected)
  onSelect;

  const ProductOptionSection({
    super.key,
    required this.title,
    required this.options,
    required this.isRequired,
    required this.selectedOptions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 🔹 العنوان وشارة "مطلوب / اختياري"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isRequired
                      ? const Color.fromARGB(255, 143, 143, 143)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color.fromARGB(255, 175, 175, 175),
                  ),
                ),
                child: Text(
                  isRequired ? "مطلوب" : "اختياري",
                  style: TextStyle(
                    color: isRequired ? Colors.white : Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 🔹 خيارات المنتج
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: options.map((option) {
              final String name = option['name']?.toString() ?? '';
              final double price = (option['price'] is num)
                  ? (option['price'] as num).toDouble()
                  : 0.0;

              bool isSelected = false;
              if (isRequired) {
                isSelected = selectedOptions[title] == name;
              } else {
                final selectedList = selectedOptions[title]?.split(',') ?? [];
                isSelected = selectedList.contains(name);
              }

              return ChoiceChip(
                label: Text(
                  "$name (+${price.toStringAsFixed(0)} ج.م)",
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.mainColor,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    color: Color.fromARGB(255, 209, 209, 209),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (selected) {
                  onSelect(title, name, price, selected);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
