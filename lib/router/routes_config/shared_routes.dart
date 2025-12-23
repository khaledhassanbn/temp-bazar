import 'package:bazar_suez/markets/account/pages/account_page.dart';
import 'package:bazar_suez/markets/cart/pages/cart_page.dart';
import 'package:bazar_suez/markets/grid_of_categories/pages/grid_of_categoies.dart';
import 'package:bazar_suez/markets/home_market/pages/ProductDetails.dart';
import 'package:bazar_suez/markets/search/pages/search_page.dart';
import 'package:bazar_suez/markets/planes/pages/pricing_page.dart';
import 'package:bazar_suez/markets/home_page/pages/home_page.dart';
import 'package:bazar_suez/ads/views/request_ads_page.dart';
import 'package:bazar_suez/markets/wallet/pages/wallet_page.dart';
import 'package:bazar_suez/markets/wallet/pages/deposit_request_page.dart';
import 'package:bazar_suez/markets/wallet/pages/admin_wallet_requests_page.dart';
import 'package:bazar_suez/markets/saved_locations/pages/delivery_addresses_page.dart';
import 'package:bazar_suez/markets/license/pages/license_status_page.dart';
import 'package:go_router/go_router.dart';

final sharedRoutes = [
  GoRoute(path: '/delivery-addresses', builder: (_, __) => const DeliveryAddressesPage()),
  GoRoute(path: '/HomePage', builder: (_, __) => const HomePage()),
  GoRoute(path: '/Search', builder: (_, __) => const SearchPage()),
  GoRoute(path: '/CategoriesGrid', builder: (_, __) => CategoriesGridPage()),
  GoRoute(path: '/CartPage', builder: (_, __) => const CartPage()),
  GoRoute(
    path: '/pricingpage',
    builder: (context, state) {
      final marketId = state.uri.queryParameters['marketId'];
      return PricingPage(marketId: marketId);
    },
  ),
  GoRoute(path: '/request-ads', builder: (_, __) => const RequestAdsPage()),
  GoRoute(path: '/AccountPage', builder: (_, __) => const AccountPage()),
  GoRoute(
    path: '/license-status',
    builder: (context, state) {
      final marketId = state.uri.queryParameters['marketId'];
      return LicenseStatusPage(marketId: marketId);
    },
  ),
  GoRoute(path: '/wallet', builder: (_, __) => const WalletPage()),
  GoRoute(
    path: '/deposit-request',
    builder: (_, __) => const DepositRequestPage(),
  ),
  GoRoute(
    path: '/admin/wallet-requests',
    builder: (_, __) => const AdminWalletRequestsPage(),
  ),
  GoRoute(
    path: '/productdetails',
    builder: (context, state) {
      final marketId = state.uri.queryParameters['marketId'];
      final categoryId = state.uri.queryParameters['categoryId'];
      final itemId = state.uri.queryParameters['itemId'];
      return ProductDetailsPage(
        marketId: marketId,
        categoryId: categoryId,
        itemId: itemId,
      );
    },
  ),
];
