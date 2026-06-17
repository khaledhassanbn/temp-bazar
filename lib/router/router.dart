import 'package:bazar_suez/core/errors/not_found_page.dart';
import 'package:bazar_suez/Layouts/market_layout.dart';
import 'package:bazar_suez/Layouts/user_layout.dart';
import 'package:bazar_suez/router/app_navigation.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/markets/home_market/pages/home_market_page.dart';
import 'package:bazar_suez/router/site_path_rules.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'routes_config/auth_routes.dart';
import 'routes_config/market_routes.dart';
import 'routes_config/shared_routes.dart';
import 'routes_config/user_routes.dart';

/// المسارات التي تتطلب تسجيل دخول
bool _requiresAuth(String path) {
  const protectedPaths = [
    '/CartPage',
    '/user-orders',
    '/AccountPage',
    '/delivery-addresses',
    '/favourite-markets',
    '/create-store',
    '/pricingpage',
    '/request-ads',
    '/wallet',
    '/deposit-request',
    '/myorder',
    '/PastOrders',
    '/addproduct',
    '/SalesStatsPage',
    '/ManageProducts',
    '/edit-store',
    '/manage-managers',
    '/market-dashboard',
    '/MyStorePage',
    '/license-status',
    '/store-reviews',
    '/craftsmen/register',
    '/craftsmen/dashboard',
  ];
  return protectedPaths.any((p) => path.startsWith(p));
}

bool _isPublicPath(String path) {
  if (path.isEmpty || path == '/') return true;
  if (path == '/not-found') return true;
  if (path == '/CategoryMarketPage') return true;
  if (path.startsWith('/market/')) return true;
  if (path.startsWith('/productdetails')) return true;
  if (path.startsWith('/craftsman/')) return true;
  if (path == '/craftsmen/categories') return true;
  if (path.startsWith('/craftsmen/') &&
      !path.startsWith('/craftsmen/register') &&
      !path.startsWith('/craftsmen/dashboard') &&
      !path.startsWith('/craftsmen/browse')) {
    final segs = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segs.length == 2) return true;
  }
  final segs = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segs.length == 1 && isStoreShareSlugSegment(segs.first)) return true;
  if (segs.length == 2 && isPublicProductSharePath(segs[0], segs[1])) {
    return true;
  }
  return false;
}

Future<GoRouter> createRouter(AuthGuard authGuard) async {
  try {
    await authGuard.loadUserStatus();
    authGuard.startStatusListener();

    // التحقق من حالة الأونبوردينج
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authGuard,
      errorBuilder: (context, state) => const NotFoundPage(),
      redirect: (context, state) {
        final loggedIn = authGuard.isAuthenticated;
        final path = state.uri.path;

        // التحقق من الأونبوردينج أولاً
        final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
        if (!onboardingDone && path != '/onboarding') {
          return '/onboarding';
        }

        if (_isPublicPath(path)) return null;

        // السماح بصفحة الأونبوردينج
        if (path == '/onboarding') return null;

        // المسارات المحمية: إعادة التوجيه للرئيسية (تسجيل الدخول عبر الورقة المنبثقة)
        if (!loggedIn && _requiresAuth(path)) return '/';

        // مسارات تسجيل الدخول/إنشاء الحساب فقط — لا تشمل /craftsmen/register
        if (loggedIn &&
            (path == '/login' ||
                path == '/login-email' ||
                path == '/register')) {
          return '/';
        }

        return null;
      },
      routes: [
        ...authRoutes,
        GoRoute(
          path: '/not-found',
          builder: (_, __) => const NotFoundPage(),
        ),
        GoRoute(
          path: '/market/:marketId',
          builder: (context, state) {
            final marketId = state.pathParameters['marketId'];
            return MarketAnimatedPage(marketLink: marketId);
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            if (authGuard.isMarketOwner) {
              return MarketLayout(child: child);
            } else {
              return UserLayout(child: child);
            }
          },
          routes: [...sharedRoutes, ...userRoutes, ...marketRoutes],
        ),
        GoRoute(
          path: r'/:storeId([a-z0-9-]+)',
          redirect: (context, state) {
            final id = state.pathParameters['storeId']!;
            if (!isStoreShareSlugSegment(id)) return '/not-found';
            return null;
          },
          builder: (context, state) {
            return MarketAnimatedPage(
              marketLink: state.pathParameters['storeId'],
            );
          },
        ),
      ],
    );
    registerAppRouter(router);
    return router;
  } catch (e) {
    return GoRouter(
      initialLocation: '/',
      routes: authRoutes,
    );
  }
}
