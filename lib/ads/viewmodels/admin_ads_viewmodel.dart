import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_model.dart';
import '../services/ads_service.dart';

class AdminAdsViewModel extends ChangeNotifier {
  final AdsService _adsService = AdsService();
  final ImagePicker _imagePicker = ImagePicker();

  List<AdModel> _ads = [];
  List<Map<String, String>> _stores = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<AdModel> get ads => _ads;
  List<Map<String, String>> get stores => _stores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final allAds = await _adsService.fetchAds();
      final stores = await _adsService.fetchStores();

      final activeAds = allAds.where((ad) => ad.isValid).toList();

      _ads = activeAds;
      _stores = stores;
    } catch (e) {
      _errorMessage = 'خطأ في تحميل البيانات: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addNewAd() async {
    final newAd = AdModel(slotId: 0, durationHours: 24, isActive: false);

    return await addAd(newAd);
  }

  Future<bool> addAd(AdModel ad) async {
    _errorMessage = null;
    try {
      final success = await _adsService.addAd(ad);
      if (success) {
        await loadData();
        return true;
      } else {
        _errorMessage = 'فشل إضافة الإعلان';
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> deleteAd(int slotId) async {
    _errorMessage = null;
    try {
      final success = await _adsService.deleteAd(slotId);
      if (success) {
        await loadData();
        return true;
      } else {
        _errorMessage = 'فشل حذف الإعلان';
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> toggleAdStatus(int slotId, bool isActive) async {
    _errorMessage = null;
    try {
      final success = await _adsService.toggleAdStatus(slotId, !isActive);
      if (success) {
        await loadData();
        return true;
      } else {
        _errorMessage = 'فشل تغيير حالة الإعلان';
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<String?> pickAndUploadImage(int slotId) async {
    _errorMessage = null;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final imageUrl = await _adsService.uploadAdImage(
        File(image.path),
        slotId,
      );

      if (imageUrl == null) {
        _errorMessage = 'فشل رفع الصورة';
        return null;
      }

      // تحديث الإعلان بالصورة الجديدة
      final adIndex = _ads.indexWhere((ad) => ad.slotId == slotId);
      if (adIndex != -1) {
        _ads[adIndex] = _ads[adIndex].copyWith(imageUrl: imageUrl);
        notifyListeners();
      }

      return imageUrl;
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return null;
    }
  }

  Future<bool> saveAd(AdModel ad) async {
    _errorMessage = null;

    if (ad.imageUrl == null || ad.imageUrl!.isEmpty) {
      _errorMessage = 'يرجى اختيار صورة للإعلان';
      return false;
    }

    if (ad.durationHours <= 0) {
      _errorMessage = 'يرجى إدخال مدة صالحة';
      return false;
    }

    try {
      final success = await _adsService.updateAd(ad);
      if (success) {
        await loadData();
        return true;
      } else {
        _errorMessage = 'فشل حفظ الإعلان';
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}



