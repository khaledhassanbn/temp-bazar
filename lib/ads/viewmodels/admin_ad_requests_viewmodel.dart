import 'package:flutter/material.dart';
import '../models/ad_request_model.dart';
import '../models/ad_model.dart';
import '../services/ad_request_service.dart';
import '../services/ads_service.dart';

class AdminAdRequestsViewModel extends ChangeNotifier {
  final AdRequestService _adRequestService = AdRequestService();
  final AdsService _adsService = AdsService();

  List<AdRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<AdRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRequests() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final allRequests = await _adRequestService.fetchAllAdRequests();
      final pendingRequests = allRequests
          .where((r) => r.status == 'pending')
          .toList();

      _requests = pendingRequests;
    } catch (e) {
      _errorMessage = 'خطأ في تحميل الطلبات: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRequestStatus(String requestId, String status) async {
    _errorMessage = null;

    try {
      // إذا كانت الموافقة، قم بإنشاء إعلان جديد
      if (status == 'approved') {
        final request = _requests.firstWhere((r) => r.id == requestId);

        final newAd = AdModel(
          slotId: 0,
          imageUrl: request.imageUrl,
          targetStoreId: request.storeId,
          durationHours: request.days * 24,
          isActive: true,
          startTime: DateTime.now(),
        );

        final adCreated = await _adsService.addAd(newAd);
        if (!adCreated) {
          _errorMessage = 'فشل إنشاء الإعلان';
          return false;
        }
      }

      // تحديث حالة الطلب
      final success = await _adRequestService.updateRequestStatus(
        requestId,
        status,
      );

      if (success) {
        // حذف الطلب من القائمة
        _requests.removeWhere((r) => r.id == requestId);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'فشل تحديث حالة الطلب';
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    _errorMessage = null;

    try {
      final success = await _adRequestService.deleteAdRequest(requestId);
      if (success) {
        await loadRequests();
        return true;
      } else {
        _errorMessage = 'فشل حذف الطلب';
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ: ${e.toString()}';
      return false;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  String formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
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



