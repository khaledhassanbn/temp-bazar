import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ad_model.dart';
import '../models/ad_request_model.dart';
import '../services/ad_request_service.dart';

class MyAdsViewModel extends ChangeNotifier {
  final AdRequestService _service = AdRequestService();
  final ImagePicker _imagePicker = ImagePicker();

  List<AdModel> _activeAds = [];
  List<AdModel> _expiredAds = [];
  List<AdRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<AdModel> get activeAds => _activeAds;
  List<AdModel> get expiredAds => _expiredAds;
  List<AdRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _errorMessage = 'يجب تسجيل الدخول';
        return;
      }

      final ads = await _service.fetchMyAds(uid);
      _activeAds = ads.where((ad) => ad.isValid).toList();
      _expiredAds = ads.where((ad) => ad.isExpired || (!ad.isValid && !ad.isPaused)).toList();
      _requests = await _service.fetchUserAdRequests(uid);
    } catch (e) {
      _errorMessage = 'خطأ في تحميل البيانات: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String formatRemaining(AdModel ad) {
    final hours = ad.remainingHours;
    if (hours <= 0) return 'منتهي';

    final days = hours ~/ 24;
    final remainingHours = (hours % 24).floor();

    if (days > 0 && remainingHours > 0) {
      return 'باقي $days ${days == 1 ? 'يوم' : 'أيام'} و $remainingHours ${remainingHours == 1 ? 'ساعة' : 'ساعات'}';
    }
    if (days > 0) return 'باقي $days ${days == 1 ? 'يوم' : 'أيام'}';
    return 'باقي $remainingHours ${remainingHours == 1 ? 'ساعة' : 'ساعات'}';
  }

  double remainingProgress(AdModel ad) {
    if (ad.startTime == null || ad.durationHours <= 0) return 0;
    final total = ad.durationHours.toDouble();
    final remaining = ad.remainingHours;
    return (remaining / total).clamp(0.0, 1.0);
  }

  Future<bool> changeAdImage(int slotId) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return false;

      final success = await _service.changeAdImage(slotId, File(image.path));
      if (success) await loadAll();
      return success;
    } catch (e) {
      _errorMessage = 'فشل تغيير الصورة: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAd(int slotId) async {
    final success = await _service.deleteUserAd(slotId);
    if (success) {
      await loadAll();
    } else {
      _errorMessage = 'فشل حذف الإعلان';
      notifyListeners();
    }
    return success;
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'معلق ⏳';
      case 'approved':
        return 'موافق ✅';
      case 'rejected':
        return 'مرفوض ❌';
      default:
        return status;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
