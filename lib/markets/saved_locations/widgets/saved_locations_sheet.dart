import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_color.dart';
import '../../../models/saved_location_model.dart';
import '../viewmodels/saved_locations_viewmodel.dart';
import '../../cart/pages/MapPickerPage.dart';

/// DraggableScrollableSheet لعرض العناوين المحفوظة - تصميم مثل Talabat
class SavedLocationsSheet extends StatelessWidget {
  const SavedLocationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // مقبض السحب
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // زر الإغلاق
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // العنوان
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'اختر موقع التوصيل',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // قائمة العناوين المحفوظة
                Consumer<SavedLocationsViewModel>(
                  builder: (context, viewModel, child) {
                    if (viewModel.savedLocations.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'العناوين المحفوظة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // قائمة العناوين
                Expanded(
                  child: Consumer<SavedLocationsViewModel>(
                    builder: (context, viewModel, child) {
                      return ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          // العناوين المحفوظة
                          ...viewModel.savedLocations.map((location) {
                            return _buildAddressTile(
                              context,
                              location,
                              viewModel,
                            );
                          }),

                          const SizedBox(height: 8),
                          Divider(color: Colors.grey[200], height: 1),
                          const SizedBox(height: 8),

                          // خيار التوصيل لموقع مختلف
                          _buildOptionTile(
                            icon: Icons.location_on_outlined,
                            title: 'التوصيل لموقع مختلف',
                            subtitle: 'اختر الموقع من الخريطة',
                            onTap: () => _pickLocationFromMap(context),
                          ),

                          // خيار التوصيل للموقع الحالي
                          _buildOptionTile(
                            icon: Icons.navigation_outlined,
                            iconColor: Colors.black87,
                            title: 'التوصيل لموقعك الحالي',
                            subtitle: 'اسمح لـ بازار بالوصول لموقعك',
                            onTap: () => _useCurrentLocation(context),
                          ),

                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressTile(
    BuildContext context,
    SavedLocation location,
    SavedLocationsViewModel viewModel,
  ) {
    final isSelected = viewModel.selectedLocation?.id == location.id;

    return InkWell(
      onTap: () {
        viewModel.selectLocation(location);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: isSelected ? AppColors.mainColor.withOpacity(0.05) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة الموقع
            Icon(
              Icons.location_on_outlined,
              color: Colors.grey[600],
              size: 22,
            ),
            const SizedBox(width: 12),
            
            // معلومات العنوان
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
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

            // علامة الاختيار
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.mainColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.grey[700],
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocationFromMap(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null && result is Map && context.mounted) {
      // حفظ الموقع المختار مباشرة
      final viewModel = context.read<SavedLocationsViewModel>();
      await viewModel.addLocation(
        name: 'عنوان جديد',
        address: result["address"] ?? 'عنوان غير معروف',
        location: result["location"],
        setAsDefault: true,
      );
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _useCurrentLocation(BuildContext context) async {
    final viewModel = context.read<SavedLocationsViewModel>();
    await viewModel.detectCurrentLocation();
    
    if (viewModel.hasLocation) {
      viewModel.useCurrentLocation();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
