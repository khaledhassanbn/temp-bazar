import 'package:flutter/material.dart';
import '../models/ad_model.dart';
import '../services/ads_service.dart';

class AdsReorderViewModel extends ChangeNotifier {
  final AdsService _adsService = AdsService();

  List<AdModel> _ads = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;

  List<AdModel> get ads => _ads;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadAds() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final allAds = await _adsService.fetchAds();
      final activeAds = allAds.where((ad) => ad.isValid).toList();

      _ads = activeAds;
    } catch (e) {
      _errorMessage = 'خطأ في تحميل الإعلانات: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  void reorderAds(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final ad = _ads.removeAt(oldIndex);
    _ads.insert(newIndex, ad);
    notifyListeners();

    saveAdsOrder();
  }

  Future<bool> saveAdsOrder() async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (int i = 0; i < _ads.length; i++) {
        final updatedAd = _ads[i].copyWith(slotId: i + 1);
        await _adsService.updateAd(updatedAd);
      }

      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'فشل حفظ ترتيب الإعلانات: ${e.toString()}';
      _isSaving = false;
      notifyListeners();
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



