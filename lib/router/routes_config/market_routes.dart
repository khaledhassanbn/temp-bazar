import 'package:bazar_suez/markets/add_product/pages/add_product.dart';
import 'package:bazar_suez/markets/account/pages/manage_managers_page.dart';
import 'package:bazar_suez/markets/create_market/pages/create_store_page.dart';
import 'package:bazar_suez/markets/edit_market/pages/edit_store_page.dart';
import 'package:bazar_suez/markets/home_market/pages/home_market_page.dart';
import 'package:bazar_suez/markets/mangement_market/pages/manage_products_page.dart';
import 'package:bazar_suez/markets/my_order/pages/MarketOrdersPage.dart';
import 'package:bazar_suez/markets/my_order/pages/PastOrdersPage.dart';
import 'package:bazar_suez/markets/statistics/pages/sales_stats_page.dart';
import 'package:bazar_suez/markets/user_orders/pages/user_orders_page.dart';
import 'package:bazar_suez/markets/store_reviews/pages/store_reviews_page.dart';
import 'package:go_router/go_router.dart';
import 'route_utils.dart';

final marketRoutes = [
  // صفحة طلبات المستخدم
  GoRoute(
    path: '/user-orders',
    builder: (context, state) => const UserOrdersPage(),
  ),
  // صفحة تقييمات المتجر
  GoRoute(
    path: '/store-reviews',
    builder: (context, state) {
      final storeId = state.uri.queryParameters['storeId'] ?? '';
      final storeName = state.uri.queryParameters['storeName'] ?? 'متجر';
      return StoreReviewsPage(storeId: storeId, storeName: storeName);
    },
  ),
  GoRoute(
    path: '/HomeMarketPage',
    builder: (context, state) {
      final marketLink = state.uri.queryParameters['marketLink'];
      return MarketAnimatedPage(marketLink: marketLink);
    },
  ),
  // يفتح متجر المستخدم المعتمد على market_id من قاعدة البيانات
  GoRoute(
    path: '/MyStorePage',
    builder: (context, state) => resolveMarketRoute(
      state,
      (marketId) => MarketAnimatedPage(marketLink: marketId),
    ),
  ),
  GoRoute(
    path: '/addproduct',
    builder: (_, __) => const AddProductModernPage(),
  ),
  GoRoute(path: '/SalesStatsPage', builder: (_, __) => const SalesStatsPage()),

  GoRoute(
    path: '/myorder',
    builder: (context, state) => resolveMarketRoute(
      state,
      (marketId) => MarketOrdersPage(marketId: marketId),
    ),
  ),
  GoRoute(
    path: '/PastOrders',
    builder: (context, state) => resolveMarketRoute(
      state,
      (marketId) => PastOrdersPage(marketId: marketId),
    ),
  ),
  GoRoute(
    path: '/ManageProducts',
    name: 'ManageProductsPage',
    builder: (context, state) => resolveMarketRoute(
      state,
      (marketId) => ManageProductsPage(marketId: marketId),
    ),
  ),
  GoRoute(
    path: '/create-store',
    builder: (context, state) {
      final products = state.uri.queryParameters['products'];
      final duration = state.uri.queryParameters['duration'];
      final packageId = state.uri.queryParameters['packageId'];
      final days = state.uri.queryParameters['days'];
      return CreateStoreModernPage(
        numberOfProducts: products != null ? int.tryParse(products) : null,
        selectedDuration: duration,
        packageId: packageId,
        days: days != null ? int.tryParse(days) : null,
      );
    },
  ),
  GoRoute(
    path: '/edit-store',
    builder: (context, state) => resolveMarketRoute(
      state,
      (marketId) => EditStorePage(storeId: marketId),
    ),
  ),
  GoRoute(
    path: '/manage-managers',
    builder: (context, state) => resolveMarketRoute(
      state,
      (marketId) => ManageManagersPage(marketId: marketId),
    ),
  ),
];
