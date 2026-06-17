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
import 'package:bazar_suez/markets/saved_locations/pages/delivery_addresses_page.dart';
import 'package:bazar_suez/markets/license/pages/license_status_page.dart';
import 'package:bazar_suez/markets/favourite_markets/pages/favourite_markets_page.dart';
import 'package:bazar_suez/craftsmen/pages/craftsmen_home_page.dart';
import 'package:bazar_suez/craftsmen/pages/craftsmen_list_page.dart';
import 'package:bazar_suez/craftsmen/pages/craftsman_detail_page.dart';
import 'package:bazar_suez/craftsmen/pages/craftsman_register_page.dart';
import 'package:bazar_suez/craftsmen/pages/craftsman_dashboard_page.dart';
import 'package:bazar_suez/craftsmen/pages/craftsmen_all_categories_page.dart';
import 'package:bazar_suez/router/site_path_rules.dart';
import 'package:go_router/go_router.dart';

final sharedRoutes = [
  GoRoute(path: '/', builder: (_, __) => const HomePage()),
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
  GoRoute(path: '/favourite-markets', builder: (_, __) => const FavouriteMarketsPage()),
  GoRoute(
    path: '/craftsmen',
    builder: (_, __) => const CraftsmenHomePage(),
    routes: [
      GoRoute(
        path: 'browse',
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return CraftsmenListPage(
            groupId: q['groupId'],
            professionId: q['professionId'],
            sort: q['sort'],
            query: q['q'],
          );
        },
      ),
      GoRoute(
        path: 'register',
        builder: (context, state) {
          final edit = state.uri.queryParameters['edit'] == '1';
          return CraftsmanRegisterPage(isEdit: edit);
        },
      ),
      GoRoute(
        path: 'dashboard',
        builder: (_, __) => const CraftsmanDashboardPage(),
      ),
      GoRoute(
        path: 'categories',
        builder: (_, __) => const CraftsmenAllCategoriesPage(),
      ),
      GoRoute(
        path: ':id',
        builder: (context, state) {
          return CraftsmanDetailPage(
            craftsmanId: state.pathParameters['id']!,
          );
        },
      ),
    ],
  ),
  GoRoute(
    path: '/craftsman/:id',
    builder: (context, state) {
      return CraftsmanDetailPage(
        craftsmanId: state.pathParameters['id']!,
      );
    },
  ),
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
  GoRoute(
    path: r'/:marketLink([a-z0-9-]+)/:itemId([a-zA-Z0-9_-]+)',
    redirect: (context, state) {
      final m = state.pathParameters['marketLink'] ?? '';
      final p = state.pathParameters['itemId'] ?? '';
      if (!isPublicProductSharePath(m, p)) return '/not-found';
      return null;
    },
    builder: (context, state) {
      final marketLink = state.pathParameters['marketLink']!;
      final itemId = state.pathParameters['itemId']!;
      return ProductDetailsPage(
        marketId: marketLink,
        categoryId: null,
        itemId: itemId,
      );
    },
  ),
];
