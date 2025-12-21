import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_color.dart';
import '../../cart/pages/MapPickerPage.dart';
import '../viewmodels/saved_locations_viewmodel.dart';

/// صفحة إعداد الموقع لأول مرة
class LocationSetupPage extends StatefulWidget {
  const LocationSetupPage({super.key});

  @override
  State<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends State<LocationSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  GeoPoint? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  final List<String> _suggestedNames = ['البيت', 'العمل', 'المتجر'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result != null && result is Map) {
      setState(() {
        _selectedLocation = result["location"] as GeoPoint?;
        _selectedAddress = result["address"] as String?;
      });
    }
  }

  Future<void> _saveLocation() async {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم للعنوان'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedLocation == null || _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار الموقع من الخريطة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final viewModel = context.read<SavedLocationsViewModel>();
      final success = await viewModel.addLocation(
        name: name,
        address: _selectedAddress!,
        location: _selectedLocation!,
        setAsDefault: true,
      );

      if (success && mounted) {
        // الانتقال للصفحة الرئيسية
        context.go('/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل حفظ العنوان، يرجى المحاولة مرة أخرى'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // أيقونة الموقع
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    size: 50,
                    color: AppColors.mainColor,
                  ),
                ),

                const SizedBox(height: 32),

                // العنوان الرئيسي
                Text(
                  'أين تريد التوصيل؟',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // الوصف
                Text(
                  'حدد موقعك الافتراضي للتوصيل.\nيمكنك إضافة عناوين أخرى لاحقًا.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // اسم العنوان
                Text(
                  'اسم العنوان',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'مثال: البيت، العمل',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // اختصارات للأسماء
                Wrap(
                  spacing: 8,
                  children: _suggestedNames.map((name) {
                    return ActionChip(
                      label: Text(name),
                      backgroundColor: Colors.grey[200],
                      onPressed: () {
                        _nameController.text = name;
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // زر اختيار الموقع
                InkWell(
                  onTap: _pickLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedLocation != null
                            ? Colors.green
                            : Colors.grey[300]!,
                        width: _selectedLocation != null ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _selectedLocation != null
                                ? Icons.check_circle
                                : Icons.map_outlined,
                            color: _selectedLocation != null
                                ? Colors.green
                                : AppColors.mainColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedLocation != null
                                    ? 'تم اختيار الموقع'
                                    : 'اختيار الموقع من الخريطة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (_selectedAddress != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _selectedAddress!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_left,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // زر الحفظ
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.mainColor.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'حفظ والمتابعة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
