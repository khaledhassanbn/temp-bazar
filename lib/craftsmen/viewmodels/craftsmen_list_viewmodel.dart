import 'package:flutter/foundation.dart';

import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_analytics_service.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_search_service.dart';

class CraftsmenListViewModel extends ChangeNotifier {
  final CraftsmanSearchService _search = CraftsmanSearchService();
  final CraftsmanAnalyticsService _analytics = CraftsmanAnalyticsService();

  CraftsmanFilterOptions filters;
  List<CraftsmanSearchResult> results = [];
  bool isLoading = false;
  String? error;
  final Set<String> _impressionLogged = {};

  CraftsmenListViewModel({CraftsmanFilterOptions? initialFilters})
      : filters = initialFilters ?? const CraftsmanFilterOptions();

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      results = await _search.search(filters);
      _impressionLogged.clear();
    } catch (e) {
      error = e.toString();
      results = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> applyFilters(CraftsmanFilterOptions newFilters) async {
    filters = newFilters;
    await load();
  }

  void logImpression(String craftsmanId) {
    if (_impressionLogged.contains(craftsmanId)) return;
    _impressionLogged.add(craftsmanId);
    _analytics.logSearchImpression(craftsmanId);
  }
}
