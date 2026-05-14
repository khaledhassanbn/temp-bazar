import 'package:bazar_suez/Layouts/admin_layout.dart';
import 'package:bazar_suez/Layouts/market_layout.dart';
import 'package:bazar_suez/Layouts/user_layout.dart';
import 'package:bazar_suez/router/app_navigation.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/authentication/pages/signin_with_social.dart';
import 'package:bazar_suez/markets/home_market/pages/home_market_page.dart';
import 'package:bazar_suez/router/site_path_rules.dart';
import 'package:go_router/go_router.dart';

import 'routes_config/admin_routes.dart';
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
    '/admin/wallet-requests',
    '/store-reviews',
  ];
  return protectedPaths.any((p) => path.startsWith(p));
}

bool _isPublicPath(String path) {
  if (path.isEmpty || path == '/') return true;
  if (path == '/CategoryMarketPage') return true;
  if (path.startsWith('/market/')) return true;
  if (path.startsWith('/productdetails')) return true;
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

    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authGuard,
      redirect: (context, state) {
        final loggedIn = authGuard.isAuthenticated;
        final isAdmin = authGuard.userStatus == 'admin';
        final location = state.matchedLocation;
        final path = state.uri.path;

        if (_isPublicPath(path)) return null;

        // حماية صفحات الأدمن
        if (path.startsWith('/admin')) {
          if (!loggedIn) return '/login';
          if (!isAdmin) return '/CategoriesGrid';
        }

        // المسارات المحمية: إذا المستخدم غير مسجل دخول → تحويل لصفحة تسجيل الدخول
        if (!loggedIn && _requiresAuth(path)) return '/login';

        // إذا كان مسجل دخول وحاول يفتح صفحة تسجيل الدخول → تحويل للصفحة الرئيسية
        if (loggedIn && location.contains('/login')) {
          if (isAdmin) return '/admin/dashboard';
          return '/';
        }

        // منع الـ admin من الوصول إلى صفحات المستخدمين (ماعدا /AccountPage والصفحات العامة)
        if (isAdmin &&
            !path.startsWith('/admin') &&
            path != '/AccountPage' &&
            !path.startsWith('/login') &&
            !_isPublicPath(path)) {
          return '/admin/dashboard';
        }

        return null;
      },
      routes: [
        ...authRoutes,
        GoRoute(
          path: '/market/:marketId',
          builder: (context, state) {
            final marketId = state.pathParameters['marketId'];
            return MarketAnimatedPage(marketLink: marketId);
          },
        ),
        // Route منفصل لصفحات الـ admin
        ShellRoute(
          builder: (context, state, child) {
            return AdminLayout(child: child);
          },
          routes: [...adminRoutes],
        ),
        // ShellRoute للمستخدمين العاديين والمتاجر
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
            if (!isStoreShareSlugSegment(id)) return '/';
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
      initialLocation: '/login',
      routes: [GoRoute(path: '/login', builder: (_, __) => const LoginPage())],
    );
  }
}
