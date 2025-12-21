import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ad_request_service.dart';
import '../../markets/create_market/services/store_service.dart';
import '../../markets/create_market/models/store_model.dart';

class RequestAdsViewModel extends ChangeNotifier {
  final AdRequestService _adRequestService = AdRequestService();
  final StoreService _storeService = StoreService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  StoreModel? _selectedStore;
  List<StoreModel> _userStores = [];
  bool _isLoading = false;
  bool _isLoadingStores = true;
  String? _errorMessage;
  int _days = 0;

  File? get selectedImage => _selectedImage;
  StoreModel? get selectedStore => _selectedStore;
  List<StoreModel> get userStores => _userStores;
  bool get isLoading => _isLoading;
  bool get isLoadingStores => _isLoadingStores;
  String? get errorMessage => _errorMessage;
  int get days => _days;

  double get totalPrice => _days * 70.0;

  Future<void> loadUserStores() async {
    _isLoadingStores = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        final stores = await _storeService.getStoresByEmail(user!.email!);
        _userStores = stores;
        if (stores.isNotEmpty && _selectedStore == null) {
          _selectedStore = stores.first;
        }
      }
    } catch (e) {
      _errorMessage = 'خطأ في تحميل المتاجر: ${e.toString()}';
    } finally {
      _isLoadingStores = false;
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    _errorMessage = null;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _selectedImage = File(image.path);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'خطأ في اختيار الصورة: ${e.toString()}';
      notifyListeners();
    }
  }

  void setSelectedStore(StoreModel? store) {
    _selectedStore = store;
    notifyListeners();
  }

  void setDays(int days) {
    _days = days;
    notifyListeners();
  }

  String? _phoneNumber;

  String? get phoneNumber => _phoneNumber;

  void setPhoneNumber(String phoneNumber) {
    _phoneNumber = phoneNumber;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitRequest() async {
    _errorMessage = null;

    if (_selectedImage == null) {
      _errorMessage = 'يرجى اختيار صورة للإعلان';
      notifyListeners();
      return {'success': false, 'insufficientBalance': false};
    }

    if (_selectedStore == null) {
      _errorMessage = 'يرجى اختيار متجر';
      notifyListeners();
      return {'success': false, 'insufficientBalance': false};
    }

    if (_days <= 0) {
      _errorMessage = 'يرجى إدخال عدد أيام صحيح';
      notifyListeners();
      return {'success': false, 'insufficientBalance': false};
    }

    if (_phoneNumber == null || _phoneNumber!.trim().isEmpty) {
      _errorMessage = 'يرجى إدخال رقم الهاتف';
      notifyListeners();
      return {'success': false, 'insufficientBalance': false};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _adRequestService.createAdRequest(
        imageFile: _selectedImage,
        storeId: _selectedStore!.id,
        storeName: _selectedStore!.name,
        days: _days,
        phoneNumber: _phoneNumber!.trim(),
      );

      _isLoading = false;
      notifyListeners();

      if (!result['success']) {
        _errorMessage = result['error'] ?? 'فشل إرسال الطلب';
        notifyListeners();
      }

      return result;
    } catch (e) {
      _errorMessage = 'فشل إرسال الطلب: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'insufficientBalance': false};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
