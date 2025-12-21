import 'package:bazar_suez/Layouts/admin_layout.dart';
import 'package:bazar_suez/Layouts/market_layout.dart';
import 'package:bazar_suez/Layouts/user_layout.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/authentication/pages/signin_with_social.dart';
import 'package:bazar_suez/markets/Markets_after_category/pages/home_market.dart';
import 'package:bazar_suez/markets/home_market/pages/home_market_page.dart';
import 'package:go_router/go_router.dart';

import 'routes_config/admin_routes.dart';
import 'routes_config/auth_routes.dart';
import 'routes_config/market_routes.dart';
import 'routes_config/shared_routes.dart';
import 'routes_config/user_routes.dart';

bool _isPublicPath(String path) {
  if (path.isEmpty || path == '/') return true;
  if (path == '/FoodHomePage') return true;
  if (path.startsWith('/market/')) return true;
  return false;
}

Future<GoRouter> createRouter(AuthGuard authGuard) async {
  try {
    await authGuard.loadUserStatus();
    authGuard.startStatusListener();

    return GoRouter(
      initialLocation: '/HomePage',
      refreshListenable: authGuard,
      redirect: (context, state) {
        final loggedIn = authGuard.isAuthenticated;
        final isMarketOwner = authGuard.isMarketOwner;
        final isAdmin = authGuard.userStatus == 'admin';
        final hasSetupLocation = authGuard.hasSetupLocation;
        final location = state.matchedLocation;
        final path = state.uri.path;

        if (_isPublicPath(path)) return null;

        // حماية صفحات الأدمن
        if (path.startsWith('/admin')) {
          if (!loggedIn) return '/login';
          if (!isAdmin) return '/CategoriesGrid';
        }

        if (!loggedIn && !location.contains('/login')) return '/login';
        if (loggedIn && location.contains('/login')) {
          if (isAdmin) return '/admin/dashboard';
          return '/HomePage';
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
          path: '/',
          builder: (context, state) {
            final categoryId = state.uri.queryParameters['categoryId'];
            return FoodHomePage(categoryId: categoryId);
          },
        ),
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
      ],
    );
  } catch (e) {
    return GoRouter(
      initialLocation: '/login',
      routes: [GoRoute(path: '/login', builder: (_, __) => const LoginPage())],
    );
  }
}
