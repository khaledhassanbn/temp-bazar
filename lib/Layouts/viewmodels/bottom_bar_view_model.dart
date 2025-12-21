import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../services/user_market_service.dart';
import '../../markets/my_order/services/OrderService.dart';

class BottomBarViewModel extends ChangeNotifier {
  final UserMarketService _userMarketService;
  final OrderService _orderService;

  BottomBarViewModel({
    UserMarketService? userMarketService,
    OrderService? orderService,
  }) : _userMarketService = userMarketService ?? const UserMarketService(),
       _orderService = orderService ?? OrderService();

  Future<String?> resolveMarketId() {
    return _userMarketService.resolveCurrentUserMarketId();
  }

  Stream<int> streamOrdersCount(String marketId) {
    return _orderService
        .streamPresentOrders(marketId)
        .map((QuerySnapshot snap) => snap.docs.length)
        .handleError((_) => 0);
  }
}
