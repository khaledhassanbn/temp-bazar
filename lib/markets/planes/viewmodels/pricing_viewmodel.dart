import 'package:flutter/material.dart';
import '../services/pricing_service.dart';
import '../models/package.dart';

class PricingViewModel extends ChangeNotifier {
  final PricingService _service = PricingService();

  List<Package> packages = [];
  bool isLoading = false;

  bool _isDisposed = false;

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> fetchPackages() async {
    isLoading = true;
    _safeNotify();

    packages = await _service.getPackages();

    isLoading = false;
    _safeNotify();
  }
}
