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
      await _loadCurrentView();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _setLoading(false);
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

  void toggleView(bool daily) {
    if (isDaily == daily) return;
    isDaily = daily;
    _loadCurrentView();
    notifyListeners();
  }

  void updateDate({int? year, int? month}) {
    if (year != null) selectedYear = year;
    if (month != null) selectedMonth = month;
    _loadCurrentView();
    notifyListeners();
  }

  Future<void> refresh() async {
    await _resolveMarketAndLoad();
  }

  String? get marketId => _marketId;

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}
