import 'package:flutter/material.dart';
import '../../../theme/app_color.dart';

class StoreSortBar extends StatelessWidget {
  final String selectedSort;
  final bool isAscending;
  final Function(String) onSortChanged;
  final VoidCallback onToggleOrder;

  const StoreSortBar({
    super.key,
    required this.selectedSort,
    required this.isAscending,
    required this.onSortChanged,
    required this.onToggleOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Text(
            'فرز حسب:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('الاسم', 'name', Icons.sort_by_alpha),
                  _buildSortChip(
                    'تاريخ الانتهاء',
                    'expiryDate',
                    Icons.calendar_today,
                  ),
                  _buildSortChip('الفئات', 'productCount', Icons.category),
                  _buildSortChip('الحالة', 'status', Icons.toggle_on),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppColors.mainColor,
            ),
            onPressed: onToggleOrder,
            tooltip: isAscending ? 'تصاعدي' : 'تنازلي',
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = selectedSort == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) => onSortChanged(value),
        selectedColor: AppColors.mainColor.withOpacity(0.2),
        checkmarkColor: AppColors.mainColor,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.mainColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
