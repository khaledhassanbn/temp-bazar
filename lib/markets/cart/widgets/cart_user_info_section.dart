import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../saved_locations/viewmodels/saved_locations_viewmodel.dart';
import '../../saved_locations/widgets/saved_locations_sheet.dart';
import '../pages/MapPickerPage.dart';

/// يُستدعى عند جاهزية أو تغيّر إحداثيات التوصيل (لإعادة حساب رسوم التوصيل في السلة).
typedef DeliveryLocationChangedCallback = void Function(GeoPoint? location);

class CartUserInfoSection extends StatefulWidget {
  const CartUserInfoSection({
    super.key,
    this.onDeliveryLocationChanged,
  });

  final DeliveryLocationChangedCallback? onDeliveryLocationChanged;

  @override
  State<CartUserInfoSection> createState() => CartUserInfoSectionState();
}

class CartUserInfoSectionState extends State<CartUserInfoSection>
    with SingleTickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  GeoPoint? selectedLocation;
  String? address;
  String? locationName;
  bool _useCustomLocation = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween(
      begin: -10.0,
      end: 10.0,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    // تحميل العنوان الافتراضي من العناوين المحفوظة
    _loadDefaultLocation();
  }

  Future<void> _loadDefaultLocation() async {
    final viewModel = context.read<SavedLocationsViewModel>();
    await viewModel.loadDefaultLocation();

    if (!mounted) return;

    GeoPoint? loc;
    if (viewModel.selectedLocation != null) {
      loc = viewModel.selectedLocation!.location;
      setState(() {
        selectedLocation = loc;
        address = viewModel.selectedLocation!.address;
        locationName = viewModel.selectedLocation!.name;
        _useCustomLocation = false;
      });
    } else if (viewModel.activeLocation != null) {
      loc = viewModel.activeLocation;
      setState(() {
        selectedLocation = loc;
        address = viewModel.activeAddress ?? 'موقعك الحالي';
        locationName = 'موقعك الحالي';
        _useCustomLocation = false;
      });
    }

    widget.onDeliveryLocationChanged?.call(loc);
  }

  /// اسم مختصر للعرض في قائمة العناوين المحفوظة
  String _deriveSavedLocationName(String rawAddress) {
    final trimmed = rawAddress.trim();
    if (trimmed.isEmpty) return 'عنوان من الخريطة';
    if (trimmed.length <= 48) return trimmed;
    return '${trimmed.substring(0, 45)}…';
  }

  @override
  void dispose() {
    _shakeController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  /// Validates if phone and address are filled
  bool get isValid {
    final phoneNumber = phoneController.text.trim();
    return phoneNumber.isNotEmpty &&
        phoneNumber.length == 11 &&
        address != null &&
        selectedLocation != null;
  }

  /// Get phone number
  String? get phoneNumber => phoneController.text.trim().isNotEmpty
      ? phoneController.text.trim()
      : null;

  /// Get selected address
  String? get selectedAddress => address;

  /// Get selected location
  GeoPoint? get selectedLocationValue => selectedLocation;

  /// Trigger shake animation
  void shake() {
    _shakeController.forward(from: 0);
  }

  void _showLocationsSheet() {
    // حفظ مرجع الـ ViewModel قبل فتح الـ sheet
    final viewModel = context.read<SavedLocationsViewModel>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const SavedLocationsSheet(),
    ).then((_) {
      // التحقق من أن الـ widget لا يزال موجوداً
      if (!mounted) return;

      GeoPoint? loc;

      // عنوان محفوظ مختار
      if (viewModel.selectedLocation != null) {
        loc = viewModel.selectedLocation!.location;
        setState(() {
          selectedLocation = loc;
          address = viewModel.selectedLocation!.address;
          locationName = viewModel.selectedLocation!.name;
          _useCustomLocation = false;
        });
      } else if (viewModel.activeLocation != null) {
        // «التوصيل لموقعك الحالي» يمسح المحفوظ ويستخدم GPS
        loc = viewModel.activeLocation;
        setState(() {
          selectedLocation = loc;
          address = viewModel.activeAddress ?? 'موقعك الحالي';
          locationName = 'موقعك الحالي';
          _useCustomLocation = false;
        });
      }

      widget.onDeliveryLocationChanged?.call(loc);
    });
  }

  Future<void> _pickCustomLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (result == null || result is! Map || !mounted) return;

    final geo = result['location'] as GeoPoint?;
    final addr = result['address'] as String?;
    if (geo == null) return;

    final vm = context.read<SavedLocationsViewModel>();
    final loggedIn = FirebaseAuth.instance.currentUser != null;

    if (loggedIn && addr != null) {
      final saved = await vm.addLocation(
        name: _deriveSavedLocationName(addr),
        address: addr,
        location: geo,
        setAsDefault: true,
      );
      if (!mounted) return;

      if (saved && vm.selectedLocation != null) {
        setState(() {
          selectedLocation = vm.selectedLocation!.location;
          address = vm.selectedLocation!.address;
          locationName = vm.selectedLocation!.name;
          _useCustomLocation = false;
        });
      } else {
        setState(() {
          selectedLocation = geo;
          address = addr;
          locationName = null;
          _useCustomLocation = true;
        });
      }
    } else {
      setState(() {
        selectedLocation = geo;
        address = addr;
        locationName = null;
        _useCustomLocation = true;
      });
    }

    widget.onDeliveryLocationChanged?.call(geo);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Phone Number Section
              _buildPhoneSection(),
              const SizedBox(height: 16),

              // Address Section
              _buildAddressSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رقم الهاتف',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ادخل رقم الهاتف (11 رقم)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: const Icon(
                Icons.phone_outlined,
                color: Color(0xFF4E99B4),
              ),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عنوان التوصيل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          // Saved Addresses Button
          Consumer<SavedLocationsViewModel>(
            builder: (context, viewModel, child) {
              return InkWell(
                onTap: _showLocationsSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedLocation != null && !_useCustomLocation
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedLocation != null && !_useCustomLocation
                          ? Colors.green
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedLocation != null && !_useCustomLocation
                            ? Icons.check_circle
                            : Icons.bookmark_border,
                        color: selectedLocation != null && !_useCustomLocation
                            ? Colors.green
                            : const Color(0xFF4E99B4),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedLocation != null && !_useCustomLocation
                                  ? 'التوصيل إلى: ${locationName ?? "العنوان المحفوظ"}'
                                  : 'اختر من العناوين المحفوظة',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            if (selectedLocation != null &&
                                !_useCustomLocation &&
                                address != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                address!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'أو',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
          ),

          // Map Location Button
          InkWell(
            onTap: _pickCustomLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _useCustomLocation && selectedLocation != null
                    ? Colors.green.withOpacity(0.1)
                    : const Color(0xFF4E99B4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _useCustomLocation && selectedLocation != null
                      ? Colors.green
                      : const Color(0xFF4E99B4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _useCustomLocation && selectedLocation != null
                        ? Icons.check_circle
                        : Icons.map_outlined,
                    color: _useCustomLocation && selectedLocation != null
                        ? Colors.green
                        : const Color(0xFF4E99B4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _useCustomLocation && selectedLocation != null
                              ? 'موقع مخصص'
                              : 'اختيار موقع آخر من الخريطة',
                          style: TextStyle(
                            fontSize: 15,
                            color: _useCustomLocation && selectedLocation != null
                                ? Colors.black87
                                : const Color(0xFF4E99B4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_useCustomLocation && address != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            address!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios,
                    size: 16,
                    color: _useCustomLocation && selectedLocation != null
                        ? Colors.grey[400]
                        : const Color(0xFF4E99B4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
