import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MerchantPicker extends StatelessWidget {
  final List<Map<String, dynamic>> merchants;
  final String? selectedMerchantId;
  final Function(String id, String name) onSelected;

  const MerchantPicker({
    super.key,
    required this.merchants,
    required this.selectedMerchantId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (merchants.isEmpty) {
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
                'لم يتم العثور على متاجر قمت بالشراء منها مؤخراً. سيتم رفع الطلب كبلاغ عام للمتجر.',
                style: TextStyle(
                  fontFamily: 'Tajawal',
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
          'اختر المتجر المعني من تعاملاتك الأخيرة:',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: merchants.length,
            itemBuilder: (context, index) {
              final merchant = merchants[index];
              final id = merchant['id'] as String;
              final name = merchant['name'] as String;
              final imageUrl = merchant['imageUrl'] as String;
              final isSelected = selectedMerchantId == id;

              return Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: GestureDetector(
                  onTap: () => onSelected(id, name),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.mainColor : Colors.grey.shade300,
                                width: isSelected ? 3 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.mainColor.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: imageUrl.isNotEmpty
                                ? CachedNetworkImageProvider(imageUrl)
                                : null,
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.store, color: AppColors.mainColor, size: 28)
                                : null,
                          ),
                          if (isSelected)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.mainColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 75,
                        child: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.mainColor : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
