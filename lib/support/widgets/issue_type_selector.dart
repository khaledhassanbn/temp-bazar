import 'package:flutter/material.dart';
import 'package:bazar_suez/support/models/support_conversation.dart';
import 'package:bazar_suez/theme/app_color.dart';

class IssueTypeSelector extends StatelessWidget {
  final IssueType? selectedType;
  final ValueChanged<IssueType> onSelected;

  const IssueTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _IssueTypeItem(
        type: IssueType.storeIssue,
        label: 'مشكلة خاصة بمتجر',
        icon: Icons.store_outlined,
        description: 'تأخر الطلب، منتج تالف، مشكلة بالدفع أو استرجاع',
      ),
      _IssueTypeItem(
        type: IssueType.craftsmanIssue,
        label: 'مشكلة خاصة بصنايعي',
        icon: Icons.construction_outlined,
        description: 'جودة الخدمة، عدم الحضور، أو خلاف في السعر',
      ),
      _IssueTypeItem(
        type: IssueType.driverIssue,
        label: 'مشكلة خاصة بمندوب',
        icon: Icons.delivery_dining_outlined,
        description: 'تأخر التوصيل، سوء التعامل، أو تلف الطلب',
      ),
      _IssueTypeItem(
        type: IssueType.appIssue,
        label: 'مشكلة بالتطبيق',
        icon: Icons.phone_android_outlined,
        description: 'عطل فني، صعوبة تسجيل الدخول، أو خطأ بالنظام',
      ),
      _IssueTypeItem(
        type: IssueType.generalInquiry,
        label: 'استفسار عام',
        icon: Icons.help_outline,
        description: 'سؤال عن الخدمات، طرق الدفع، أو أي اقتراحات',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = selectedType == item.type;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.mainColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.mainColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.mainColor.withOpacity(0.1)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelected(item.type),
              borderRadius: BorderRadius.circular(20),
              splashColor: AppColors.mainColor.withOpacity(0.1),
              highlightColor: AppColors.mainColor.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.mainColor : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: isSelected ? Colors.white : AppColors.mainColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.mainColor : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        item.description,
                        style: TextStyle(
                          fontFamily: 'NotoSansArabic',
                          fontSize: 11,
                          color: isSelected ? AppColors.mainColor.withOpacity(0.8) : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IssueTypeItem {
  final IssueType type;
  final String label;
  final IconData icon;
  final String description;

  _IssueTypeItem({
    required this.type,
    required this.label,
    required this.icon,
    required this.description,
  });
}
