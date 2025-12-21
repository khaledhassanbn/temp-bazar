import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/saved_location_model.dart';
import '../../../services/saved_locations_service.dart';

/// ViewModel لإدارة العناوين المحفوظة
class SavedLocationsViewModel extends ChangeNotifier {
  final SavedLocationsService _service = SavedLocationsService();
  final String _apiKey = "AIzaSyA9bJxVt4G17WqaUeIHmpaHfmcOhsJddYA";

  List<SavedLocation> _savedLocations = [];
  SavedLocation? _selectedLocation;
  bool _isLoading = false;
  String? _error;
  bool _hasLocation = false;
  bool _locationPermissionDenied = false;
  bool _isInitializing = true;

  // الموقع الحالي (من GPS)
  GeoPoint? _currentLocation;
  String? _currentAddress;

  // Getters
  List<SavedLocation> get savedLocations => _savedLocations;
  SavedLocation? get selectedLocation => _selectedLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _hasLocation || _selectedLocation != null || _currentLocation != null;
  bool get hasLocations => _savedLocations.isNotEmpty;
  bool get locationPermissionDenied => _locationPermissionDenied;
  bool get isInitializing => _isInitializing;
  GeoPoint? get currentLocation => _currentLocation;
  String? get currentAddress => _currentAddress;

  /// العنوان المعروض في الـ AppBar
  String get displayAddress {
    if (_selectedLocation != null) {
      return _selectedLocation!.address;
    }
    if (_currentAddress != null) {
      return _currentAddress!;
    }
    return 'اختر موقع التوصيل';
  }

  /// الموقع المختار للاستخدام في الطلبات
  GeoPoint? get activeLocation {
    if (_selectedLocation != null) {
      return _selectedLocation!.location;
    }
    return _currentLocation;
  }

  String? get activeAddress {
    if (_selectedLocation != null) {
      return _selectedLocation!.address;
    }
    return _currentAddress;
  }

  /// تهيئة الـ ViewModel
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    try {
      await loadSavedLocations();
      await loadDefaultLocation();
      
      // إذا لم يكن هناك عنوان محفوظ، حاول الحصول على الموقع الحالي
      if (_selectedLocation == null) {
        await detectCurrentLocation();
      }
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// الكشف التلقائي عن الموقع الحالي
  Future<void> detectCurrentLocation() async {
    try {
      // التحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationPermissionDenied = true;
        notifyListeners();
        return;
      }

      // التحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationPermissionDenied = true;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationPermissionDenied = true;
        notifyListeners();
        return;
      }

      // الحصول على الموقع الحالي
      _isLoading = true;
      notifyListeners();

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLocation = GeoPoint(position.latitude, position.longitude);
      
      // جلب العنوان من الإحداثيات
      await _fetchAddressFromCoordinates(position.latitude, position.longitude);

      _hasLocation = true;
      _locationPermissionDenied = false;
      _isLoading = false;
      notifyListeners();

    } catch (e) {
      debugPrint('خطأ في الكشف عن الموقع: $e');
      _locationPermissionDenied = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// جلب العنوان من الإحداثيات باستخدام Google Geocoding API
  Future<void> _fetchAddressFromCoordinates(double lat, double lng) async {
    try {
      final url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&language=ar&key=$_apiKey";
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);

      if (data["status"] == "OK" && data["results"].isNotEmpty) {
        final results = data["results"] as List;

        // نحاول نلاقي اسم الحي
        String? neighborhoodName;
        for (var r in results) {
          final types = (r["types"] as List?)?.cast<String>() ?? [];
          if (types.contains("neighborhood")) {
            final comps = (r["address_components"] as List)
                .cast<Map<String, dynamic>>();
            for (var c in comps) {
              final cTypes = (c["types"] as List?)?.cast<String>() ?? [];
              if (cTypes.contains("neighborhood")) {
                neighborhoodName = c["short_name"] ?? c["long_name"];
                break;
              }
            }
            break;
          }
        }

        _currentAddress = neighborhoodName ?? data["results"][0]["formatted_address"];
      }
    } catch (e) {
      debugPrint('خطأ في جلب العنوان: $e');
      _currentAddress = 'موقعك الحالي';
    }
  }

  /// تحميل العناوين المحفوظة
  Future<void> loadSavedLocations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _savedLocations = await _service.getSavedLocations();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'فشل تحميل العناوين';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحميل العنوان الافتراضي
  Future<void> loadDefaultLocation() async {
    try {
      _selectedLocation = await _service.getDefaultLocation();
      if (_selectedLocation != null) {
        _hasLocation = true;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في تحميل العنوان الافتراضي: $e');
    }
  }

  /// إضافة عنوان جديد
  Future<bool> addLocation({
    required String name,
    required String address,
    required GeoPoint location,
    bool setAsDefault = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newLocation = await _service.addLocation(
        name: name,
        address: address,
        location: location,
        setAsDefault: setAsDefault,
      );

      if (newLocation != null) {
        await loadSavedLocations();
        
        if (setAsDefault || _selectedLocation == null) {
          _selectedLocation = newLocation;
        }
        
        _hasLocation = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل إضافة العنوان';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// حفظ الموقع الحالي كعنوان
  Future<bool> saveCurrentLocationAsAddress(String name) async {
    if (_currentLocation == null || _currentAddress == null) return false;

    return await addLocation(
      name: name,
      address: _currentAddress!,
      location: _currentLocation!,
      setAsDefault: true,
    );
  }

  /// تعديل عنوان
  Future<bool> updateLocation(SavedLocation location) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.updateLocation(location);
      if (success) {
        await loadSavedLocations();
        
        if (_selectedLocation?.id == location.id) {
          _selectedLocation = location;
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'فشل تعديل العنوان';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// حذف عنوان
  Future<bool> deleteLocation(String locationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.deleteLocation(locationId);
      if (success) {
        await loadSavedLocations();
        
        if (_selectedLocation?.id == locationId) {
          await loadDefaultLocation();
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'فشل حذف العنوان';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// تعيين عنوان كافتراضي
  Future<bool> setDefaultLocation(String locationId) async {
    try {
      final success = await _service.setDefaultLocation(locationId);
      if (success) {
        await loadSavedLocations();
        await loadDefaultLocation();
      }
      return success;
    } catch (e) {
      debugPrint('خطأ في تعيين العنوان الافتراضي: $e');
      return false;
    }
  }

  /// اختيار عنوان (للاستخدام الحالي)
  void selectLocation(SavedLocation location) {
    _selectedLocation = location;
    _hasLocation = true;
    notifyListeners();
  }

  /// استخدام الموقع الحالي
  void useCurrentLocation() {
    _selectedLocation = null; // استخدم الموقع الحالي بدلاً من المحفوظ
    if (_currentLocation != null) {
      _hasLocation = true;
    }
    notifyListeners();
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
