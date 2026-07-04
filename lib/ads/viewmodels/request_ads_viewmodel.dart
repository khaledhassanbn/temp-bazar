import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ad_request_service.dart';
import '../models/ad_request_model.dart';
import '../../markets/create_market/services/store_service.dart';
import '../../markets/create_market/models/store_model.dart';
import '../../craftsmen/services/craftsman_service.dart';
import '../../craftsmen/models/craftsman_model.dart';
import '../../authentication/guards/AuthGuard.dart';

enum AdRequestUserType { merchant, craftsman, none }

class RequestAdsViewModel extends ChangeNotifier {
  final AdRequestService _adRequestService = AdRequestService();
  final StoreService _storeService = StoreService();
  final CraftsmanService _craftsmanService = CraftsmanService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _disposed = false;

  File? _selectedImage;
  StoreModel? _selectedStore;
  CraftsmanModel? _craftsmanProfile;
  List<StoreModel> _userStores = [];
  AdRequestUserType _userType = AdRequestUserType.none;
  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _errorMessage;
  int _days = 0;
  String? _phoneNumber;

  File? get selectedImage => _selectedImage;
  StoreModel? get selectedStore => _selectedStore;
  CraftsmanModel? get craftsmanProfile => _craftsmanProfile;
  List<StoreModel> get userStores => _userStores;
  AdRequestUserType get userType => _userType;
  bool get isMerchant => _userType == AdRequestUserType.merchant;
  bool get isCraftsman => _userType == AdRequestUserType.craftsman;
  bool get isLoading => _isLoading;
  bool get isLoadingData => _isLoadingData;
  String? get errorMessage => _errorMessage;
  int get days => _days;
  String? get phoneNumber => _phoneNumber;

  double get totalPrice => _days * 70.0;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize(AuthGuard authGuard) async {
    _isLoadingData = true;
    _errorMessage = null;
    _notify();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _userType = AdRequestUserType.none;
        return;
      }

      if (authGuard.isMarketOwner) {
        _userType = AdRequestUserType.merchant;
        if (user.email != null) {
          final stores = await _storeService.getStoresByEmail(user.email!);
          if (_disposed) return;
          _userStores = stores;
          if (stores.isNotEmpty) _selectedStore = stores.first;
        }
      } else {
        final hasCraftsman = await _craftsmanService.hasProfile(user.uid);
        if (_disposed) return;
        if (hasCraftsman) {
          _userType = AdRequestUserType.craftsman;
          _craftsmanProfile = await _craftsmanService.getById(user.uid);
          if (_disposed) return;
        } else {
          _userType = AdRequestUserType.none;
        }
      }
    } catch (e) {
      if (!_disposed) {
        _errorMessage = 'خطأ في تحميل البيانات: ${e.toString()}';
      }
    }

    if (!_disposed) {
      _isLoadingData = false;
      _notify();
    }
  }

  Future<void> pickImage() async {
    _errorMessage = null;
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        _notify();
      }
    } catch (e) {
      _errorMessage = 'خطأ في اختيار الصورة: ${e.toString()}';
      _notify();
    }
  }

  void setSelectedStore(StoreModel? store) {
    _selectedStore = store;
    _notify();
  }

  void setDays(int days) {
    _days = days;
    _notify();
  }

  void setPhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
    _notify();
  }

  Future<Map<String, dynamic>> submitRequest() async {
    _errorMessage = null;

    if (_selectedImage == null) {
      _errorMessage = 'يرجى اختيار صورة للإعلان';
      _notify();
      return {'success': false, 'insufficientBalance': false};
    }

    if (_days <= 0) {
      _errorMessage = 'يرجى إدخال عدد أيام صحيح';
      _notify();
      return {'success': false, 'insufficientBalance': false};
    }

    if (_phoneNumber == null || _phoneNumber!.trim().isEmpty) {
      _errorMessage = 'يرجى إدخال رقم الهاتف';
      _notify();
      return {'success': false, 'insufficientBalance': false};
    }

    String? storeId;
    String? storeName;
    String ownerType = AdRequestOwnerType.merchant;
    String? craftsmanId;

    if (_userType == AdRequestUserType.merchant) {
      if (_selectedStore == null) {
        _errorMessage = 'يرجى اختيار متجر';
        _notify();
        return {'success': false, 'insufficientBalance': false};
      }
      storeId = _selectedStore!.id;
      storeName = _selectedStore!.name;
    } else if (_userType == AdRequestUserType.craftsman) {
      if (_craftsmanProfile == null) {
        _errorMessage = 'لم يتم العثور على ملف الحرفي';
        _notify();
        return {'success': false, 'insufficientBalance': false};
      }
      storeId = _craftsmanProfile!.id;
      storeName = _craftsmanProfile!.name;
      ownerType = AdRequestOwnerType.craftsman;
      craftsmanId = _craftsmanProfile!.id;
    } else {
      _errorMessage = 'غير مصرح لك بطلب إعلان';
      _notify();
      return {'success': false, 'insufficientBalance': false};
    }

    _isLoading = true;
    _notify();

    try {
      final result = await _adRequestService.createAdRequest(
        imageFile: _selectedImage,
        storeId: storeId,
        storeName: storeName,
        days: _days,
        phoneNumber: _phoneNumber!.trim(),
        ownerType: ownerType,
        craftsmanId: craftsmanId,
      );

      if (_disposed) return result;

      _isLoading = false;
      _notify();

      if (!result['success']) {
        _errorMessage = result['error'] ?? 'فشل إرسال الطلب';
        _notify();
      }

      return result;
    } catch (e) {
      if (_disposed) {
        return {'success': false, 'insufficientBalance': false};
      }
      _errorMessage = 'فشل إرسال الطلب: ${e.toString()}';
      _isLoading = false;
      _notify();
      return {'success': false, 'insufficientBalance': false};
    }
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }
}
