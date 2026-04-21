import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  /// Flag to track if this ChangeNotifier has been disposed
  bool _isDisposed = false;
  
  /// Safe wrapper for notifyListeners that checks disposal state
  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

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
    _safeNotifyListeners();

    try {
      await loadSavedLocations();
      await loadDefaultLocation();
      
      // إذا لم يكن هناك عنوان محفوظ، حاول الحصول على الموقع الحالي
      if (_selectedLocation == null) {
        await detectCurrentLocation();
      }
    } finally {
      _isInitializing = false;
      _safeNotifyListeners();
    }
  }

  /// الكشف التلقائي عن الموقع الحالي (Progressive Location Strategy)
  Future<void> detectCurrentLocation() async {
    // 1️⃣ المستوى الأول: Cache محلي (فوري)
    final cached = await _loadFromCache();
    if (cached != null) {
      _currentLocation = cached['location'];
      _currentAddress = cached['address'];
      _hasLocation = true;
      _safeNotifyListeners(); // ✅ عرض فوري للمستخدم
      
      // حسّن في الخلفية بدون انتظار
      _refreshLocationInBackground();
      return;
    }

    // 2️⃣ المستوى الثاني: آخر موقع معروف (سريع جداً)
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _currentLocation = GeoPoint(lastKnown.latitude, lastKnown.longitude);
        _hasLocation = true;
        _safeNotifyListeners(); // ✅ عرض سريع
        
        // جلب العنوان والتحسين في الخلفية
        _fetchAddressInBackground(_currentLocation!);
        _refreshLocationInBackground();
        return;
      }
    } catch (_) {}

    // 3️⃣ المستوى الثالث: GPS مع Timeout محدود
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final permission = await _checkAndRequestPermission();
      if (!permission) {
        _isLoading = false;
        _safeNotifyListeners();
        return;
      }

      // ⚠️ الفرق الجوهري: timeout + accuracy أقل أولاً
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // أسرع من high
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('GPS timeout'),
      );

      _currentLocation = GeoPoint(position.latitude, position.longitude);
      _hasLocation = true;
      _isLoading = false;
      _safeNotifyListeners();

      // جلب العنوان في الخلفية
      _fetchAddressInBackground(_currentLocation!);

      // تحسين الدقة لاحقاً في الخلفية
      _improveAccuracyInBackground();

    } on TimeoutException {
      // ✅ مش كارثة - عرض الخريطة بدون موقع
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('خطأ في الكشف عن الموقع: $e');
      _locationPermissionDenied = true;
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // ================================================
  // Helpers
  // ================================================


Future<bool> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationPermissionDenied = true;
      _safeNotifyListeners(); // ← ضروري عشان الـ UI يتحدث
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationPermissionDenied = true;
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _locationPermissionDenied = true;
      return false;
    }
    
    _locationPermissionDenied = false;
    return true;
  }

  void _refreshLocationInBackground() {
    _improveAccuracyInBackground();
  }

  void _improveAccuracyInBackground() {
    Future.microtask(() async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 15));
        
        _currentLocation = GeoPoint(position.latitude, position.longitude);
        _hasLocation = true;
        _safeNotifyListeners();
        
        _fetchAddressInBackground(_currentLocation!);
      } catch (_) {}
    });
  }

  void _fetchAddressInBackground(GeoPoint location) {
    Future.microtask(() async {
      await _fetchAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
    });
  }

  Future<void> _fetchAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&language=ar&key=$_apiKey";
      
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4)); // ✅ timeout ضروري

      final data = json.decode(res.body);
      if (data["status"] == "OK" && data["results"].isNotEmpty) {
        _currentAddress = _extractNeighborhood(data["results"]);
        _safeNotifyListeners();
        
        if (_currentLocation != null) {
          await _saveToCache(_currentLocation!, _currentAddress!); // حفظ للمرة الجاية
        }
      }
    } on TimeoutException {
      if (_currentAddress == null) _currentAddress = 'موقعك الحالي';
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('خطأ في جلب العنوان: $e');
      if (_currentAddress == null) _currentAddress = 'موقعك الحالي';
      _safeNotifyListeners();
    }
  }

  String _extractNeighborhood(List<dynamic> results) {
    String? neighborhoodName;
    for (var r in results) {
      final types = (r["types"] as List?)?.cast<String>() ?? [];
      if (types.contains("neighborhood")) {
        final comps = (r["address_components"] as List).cast<Map<String, dynamic>>();
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
    return neighborhoodName ?? results[0]["formatted_address"] ?? 'موقعك الحالي';
  }

  Future<Map<String, dynamic>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('cached_lat');
      final lng = prefs.getDouble('cached_lng');
      final address = prefs.getString('cached_address');
      final timestamp = prefs.getInt('cached_timestamp') ?? 0;
      
      // Cache صالح لمدة 30 دقيقة فقط
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (lat != null && lng != null && address != null && age < 30 * 60 * 1000) {
        return {'location': GeoPoint(lat, lng), 'address': address};
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveToCache(GeoPoint location, String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_lat', location.latitude);
      await prefs.setDouble('cached_lng', location.longitude);
      await prefs.setString('cached_address', address);
      await prefs.setInt('cached_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// تحميل العناوين المحفوظة
  Future<void> loadSavedLocations() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _savedLocations = await _service.getSavedLocations();
      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _error = 'فشل تحميل العناوين';
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// تحميل العنوان الافتراضي
  Future<void> loadDefaultLocation() async {
    try {
      _selectedLocation = await _service.getDefaultLocation();
      if (_selectedLocation != null) {
        _hasLocation = true;
      }
      _safeNotifyListeners();
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
    _safeNotifyListeners();

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
        _safeNotifyListeners();
        return true;
      }

      _isLoading = false;
      _safeNotifyListeners();
      return false;
    } catch (e) {
      _error = 'فشل إضافة العنوان';
      _isLoading = false;
      _safeNotifyListeners();
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
    _safeNotifyListeners();

    try {
      final success = await _service.updateLocation(location);
      if (success) {
        await loadSavedLocations();
        
        if (_selectedLocation?.id == location.id) {
          _selectedLocation = location;
        }
      }

      _isLoading = false;
      _safeNotifyListeners();
      return success;
    } catch (e) {
      _error = 'فشل تعديل العنوان';
      _isLoading = false;
      _safeNotifyListeners();
      return false;
    }
  }

  /// حذف عنوان
  Future<bool> deleteLocation(String locationId) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final success = await _service.deleteLocation(locationId);
      if (success) {
        await loadSavedLocations();
        
        if (_selectedLocation?.id == locationId) {
          await loadDefaultLocation();
        }
      }

      _isLoading = false;
      _safeNotifyListeners();
      return success;
    } catch (e) {
      _error = 'فشل حذف العنوان';
      _isLoading = false;
      _safeNotifyListeners();
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
    _safeNotifyListeners();
  }

  /// استخدام الموقع الحالي
  void useCurrentLocation() {
    _selectedLocation = null; // استخدم الموقع الحالي بدلاً من المحفوظ
    if (_currentLocation != null) {
      _hasLocation = true;
    }
    _safeNotifyListeners();
  }

  /// مسح الخطأ
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }
}
