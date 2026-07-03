import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';

class DriverPicker extends StatelessWidget {
  final List<Map<String, dynamic>> drivers;
  final String? selectedDriverId;
  final Function(String id, String name) onSelected;

  const DriverPicker({
    super.key,
    required this.drivers,
    required this.selectedDriverId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (drivers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'لم يتم العثور على مناديب مسجلين مؤخراً في طلباتك. سيتم رفع طلبك كشكوى عامة بخصوص المندوب.',
                style: TextStyle(
                  fontFamily: 'NotoSansArabic',
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اختر المندوب المعني من تعاملاتك الأخيرة:',
          style: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: drivers.length,
          itemBuilder: (context, index) {
            final driver = drivers[index];
            final id = driver['id'] as String;
            final name = driver['name'] as String;
            final isSelected = selectedDriverId == id;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.mainColor.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.mainColor : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected ? AppColors.mainColor : Colors.grey.shade100,
                    child: Icon(
                      Icons.delivery_dining,
                      color: isSelected ? Colors.white : AppColors.mainColor,
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'NotoSansArabic',
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.mainColor : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.mainColor)
                      : const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
                  onTap: () => onSelected(id, name),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
