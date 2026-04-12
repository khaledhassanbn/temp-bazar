import 'package:flutter/material.dart';
import 'package:bazar_suez/markets/home_market/viewmodels/market_details_viewmodel.dart';
import '../models/search_in_market_product_entry.dart';

class SearchInMarketViewModel extends ChangeNotifier {
  SearchInMarketViewModel({
    required this.marketId,
    required List<MarketCategoryModel> categories,
  }) : _categories = List<MarketCategoryModel>.from(categories) {
    searchController.addListener(_onSearchChanged);
  }

  final String marketId;
  final List<MarketCategoryModel> _categories;
  final TextEditingController searchController = TextEditingController();

  void _onSearchChanged() => notifyListeners();

  List<SearchInMarketProductEntry> get _allEntries {
    final out = <SearchInMarketProductEntry>[];
    for (final c in _categories) {
      for (final item in c.items) {
        out.add(SearchInMarketProductEntry(categoryId: c.id, item: item));
      }
    }
    return out;
  }

  List<SearchInMarketProductEntry> get filteredEntries {
    final raw = searchController.text;
    final q = _normalizeForSearch(raw);
    if (q.isEmpty) return _allEntries;
    return _allEntries.where((e) {
      final name = _normalizeForSearch(e.item.name);
      final desc = _normalizeForSearch(e.item.description ?? '');
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  static String _normalizeForSearch(String input) {
    final diacritics = RegExp('[\u064B-\u0652]');
    return input
        .toLowerCase()
        .replaceAll(diacritics, '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ً', '')
        .trim();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}
