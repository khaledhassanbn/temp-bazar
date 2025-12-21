import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_color.dart';
import '../viewmodels/saved_locations_viewmodel.dart';
import '../../../models/saved_location_model.dart';
import '../../cart/pages/MapPickerPage.dart';

/// صفحة عناوين التوصيل في إعدادات الحساب - تصميم مثل Talabat
class DeliveryAddressesPage extends StatelessWidget {
  const DeliveryAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
          title: const Text(
            'العناوين',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _showAddAddressDialog(context),
              child: Text(
                'أضف',
                style: TextStyle(
                  color: AppColors.mainColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: Consumer<SavedLocationsViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.savedLocations.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: viewModel.savedLocations.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey[200],
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final location = viewModel.savedLocations[index];
                return _buildAddressTile(context, location, viewModel);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد عناوين محفوظة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف عنوان لتسهيل عملية التوصيل',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAddressDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة عنوان'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile(
    BuildContext context,
    SavedLocation location,
    SavedLocationsViewModel viewModel,
  ) {
    return InkWell(
      onTap: () => _showEditAddressDialog(context, location),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات العنوان
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم العنوان والمنطقة
                  Row(
                    children: [
                      Text(
                        location.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // اسم المنطقة
                      Text(
                        _extractAreaName(location.address),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // العنوان الكامل
                  Text(
                    location.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isDefault) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'افتراضي',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // سهم التنقل
            Icon(
              Icons.chevron_left,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _extractAreaName(String address) {
    // استخراج اسم المنطقة من العنوان
    final parts = address.split(',');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return '';
  }

  void _showAddAddressDialog(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null && result is Map && context.mounted) {
      // إظهار dialog لإدخال اسم العنوان
      _showNameInputDialog(
        context,
        result["address"] ?? 'عنوان جديد',
        result["location"] as GeoPoint,
      );
    }
  }

  void _showNameInputDialog(
    BuildContext context,
    String address,
    GeoPoint location,
  ) {
    final controller = TextEditingController();
    final names = ['البيت', 'العمل', 'المتجر', 'صديق'];

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('اسم العنوان'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'مثال: البيت، العمل',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: names.map((name) {
                  return InkWell(
                    onTap: () => controller.text = name,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(name, style: const TextStyle(fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim().isEmpty
                    ? 'عنوان جديد'
                    : controller.text.trim();
                Navigator.pop(context);
                
                final viewModel = context.read<SavedLocationsViewModel>();
                await viewModel.addLocation(
                  name: name,
                  address: address,
                  location: location,
                  setAsDefault: viewModel.savedLocations.isEmpty,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
              ),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAddressDialog(BuildContext context, SavedLocation location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('تعيين كافتراضي'),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<SavedLocationsViewModel>()
                        .setDefaultLocation(location.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('حذف العنوان', 
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => Directionality(
                        textDirection: TextDirection.rtl,
                        child: AlertDialog(
                          title: const Text('حذف العنوان'),
                          content: Text(
                            'هل أنت متأكد من حذف "${location.name}"؟',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('إلغاء'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('حذف'),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      context.read<SavedLocationsViewModel>()
                          .deleteLocation(location.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
