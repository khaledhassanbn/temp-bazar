import 'package:flutter/foundation.dart';

import '../models/dashboard_market_model.dart';
import '../services/dashboard_market_service.dart';

class DashboardMarketViewModel extends ChangeNotifier {
  final DashboardMarketService _service;

  DashboardMarketModel? data;
  bool isLoading = false;
  String? errorMessage;

  DashboardMarketViewModel({DashboardMarketService? service})
    : _service = service ?? DashboardMarketService();

  Future<void> load({String? marketId}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      data = await _service.loadDashboard(marketId: marketId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
