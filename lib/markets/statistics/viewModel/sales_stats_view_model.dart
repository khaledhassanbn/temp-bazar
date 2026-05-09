import 'dart:async';

import 'package:flutter/material.dart';
import '../model/sales_data_model.dart';
import '../service/statistics_service.dart';

class SalesStatsViewModel extends ChangeNotifier {
  final StatisticsService _service;

  bool isDaily = true;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  bool isLoading = false;
  String? errorMessage;
  String? _marketId;
  StreamSubscription<Map<String, double>>? _statsSubscription;

  Map<String, double> _dailyTotals = {};
  Map<String, double> _monthlyTotals = {};

  SalesStatsViewModel({StatisticsService? service})
    : _service = service ?? StatisticsService() {
    _initialize();
  }

  List<SalesData> get salesData {
    final source = isDaily ? _dailyTotals : _monthlyTotals;
    final keys = source.keys.toList()..sort();
    return keys.map((k) => SalesData(label: k, value: source[k] ?? 0)).toList();
  }

  Future<void> _initialize() async {
    await _resolveMarketAndLoad();
  }

  Future<void> _resolveMarketAndLoad() async {
    _setLoading(true);
    try {
      errorMessage = null;
      _marketId ??= await _service.getCurrentUserMarketId();
      if (_marketId == null || _marketId!.isEmpty) {
        throw Exception('لا يوجد متجر مرتبط بالحساب');
      }
      _subscribeToCurrentView();
    } catch (e) {
      errorMessage = e.toString();
      _setLoading(false);
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadCurrentView() async {
    if (_marketId == null) return;
    if (isDaily) {
      _dailyTotals = await _service.fetchDailyTotals(
        marketId: _marketId!,
        year: selectedYear,
        month: selectedMonth,
      );
    } else {
      _monthlyTotals = await _service.fetchMonthlyTotals(
        marketId: _marketId!,
        year: selectedYear,
      );
    }
    notifyListeners();
  }

  void _subscribeToCurrentView() {
    if (_marketId == null) return;
    _setLoading(true);
    errorMessage = null;

    _statsSubscription?.cancel();
    final stream = isDaily
        ? _service.streamDailyTotals(
            marketId: _marketId!,
            year: selectedYear,
            month: selectedMonth,
          )
        : _service.streamMonthlyTotals(
            marketId: _marketId!,
            year: selectedYear,
          );

    _statsSubscription = stream.listen(
      (totals) {
        if (isDaily) {
          _dailyTotals = totals;
        } else {
          _monthlyTotals = totals;
        }
        errorMessage = null;
        _setLoading(false);
      },
      onError: (e) {
        errorMessage = e.toString();
        _setLoading(false);
      },
    );
  }

  void toggleView(bool daily) {
    if (isDaily == daily) return;
    isDaily = daily;
    _subscribeToCurrentView();
    notifyListeners();
  }

  void updateDate({int? year, int? month}) {
    if (year != null) selectedYear = year;
    if (month != null) selectedMonth = month;
    _subscribeToCurrentView();
    notifyListeners();
  }

  Future<void> refresh() async {
    _marketId = await _service.getCurrentUserMarketId();
    await _loadCurrentView();
    _subscribeToCurrentView();
  }

  String? get marketId => _marketId;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }
}
