import 'package:bazar_suez/markets/home_market/viewmodels/market_details_viewmodel.dart';

/// صف واحد في نتائج البحث: منتج مع معرف فئته للتنقل لتفاصيل المنتج
class SearchInMarketProductEntry {
  final String categoryId;
  final MarketItemModel item;

  const SearchInMarketProductEntry({
    required this.categoryId,
    required this.item,
  });
}
