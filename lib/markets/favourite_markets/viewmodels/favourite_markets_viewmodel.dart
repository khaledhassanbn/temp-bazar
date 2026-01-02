import 'package:flutter/foundation.dart';
import '../models/favourite_market_model.dart';
import '../services/favourite_markets_service.dart';
import '../../create_market/models/store_model.dart';
import '../../Markets_after_category/service/category_store_service.dart';

/// ViewModel لإدارة المتاجر المفضلة
class FavouriteMarketsViewModel extends ChangeNotifier {
  final FavouriteMarketsService _service = FavouriteMarketsService();
  final CategoryStoreService _storeService = CategoryStoreService();

  List<FavouriteMarketModel> _favourites = [];
  List<StoreModel> _stores = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<StoreModel> get stores => _stores;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// تحميل المتاجر المفضلة
  Future<void> loadFavouriteMarkets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _favourites = await _service.getFavouriteMarkets();
      
      if (_favourites.isEmpty) {
        _stores = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // جلب بيانات المتاجر
      final marketIds = _favourites.map((f) => f.marketId).toList();
      _stores = await _storeService.getStoresByIds(marketIds);

      // ترتيب المتاجر حسب تاريخ الإضافة
      final orderMap = {
        for (int i = 0; i < _favourites.length; i++)
          _favourites[i].marketId: i,
      };
      _stores.sort((a, b) =>
          (orderMap[a.id] ?? 999).compareTo(orderMap[b.id] ?? 999));
    } catch (e) {
      _errorMessage = 'خطأ في تحميل المتاجر المفضلة: ${e.toString()}';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// إزالة متجر من المفضلة
  Future<bool> removeFavouriteMarket(String marketId) async {
    try {
      final success = await _service.removeFavouriteMarket(marketId);
      if (success) {
        await loadFavouriteMarkets();
      }
      return success;
    } catch (e) {
      _errorMessage = 'خطأ في إزالة المتجر: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}


