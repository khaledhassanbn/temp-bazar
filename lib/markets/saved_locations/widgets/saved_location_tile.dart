import 'package:flutter/material.dart';
import '../../../models/saved_location_model.dart';
import '../../../theme/app_color.dart';

/// ويدجت لعرض عنصر عنوان واحد
class SavedLocationTile extends StatelessWidget {
  final SavedLocation location;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  const SavedLocationTile({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
  });

  IconData _getIcon() {
    switch (location.iconName) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'store':
        return Icons.store_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  Color _getIconColor() {
    switch (location.iconName) {
      case 'home':
        return Colors.blue;
      case 'work':
        return Colors.orange;
      case 'store':
        return Colors.purple;
      default:
        return AppColors.mainColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? AppColors.mainColor.withOpacity(0.05) : null,
        child: Row(
          children: [
            // أيقونة نوع العنوان
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getIconColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(),
                color: _getIconColor(),
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // معلومات العنوان
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        location.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      if (location.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'افتراضي',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.mainColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Radio للاختيار
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.mainColor,
            ),

            // قائمة الخيارات
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              onSelected: (value) {
                if (value == 'default') {
                  onSetDefault();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                if (!location.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.star_outline, size: 20),
                        SizedBox(width: 8),
                        Text('تعيين كافتراضي'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
