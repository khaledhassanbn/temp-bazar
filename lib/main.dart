import 'package:bazar_suez/core/network/connection_service.dart';
import 'package:bazar_suez/core/network/connectivity_listener.dart';
import 'package:bazar_suez/router/router.dart';
import 'package:bazar_suez/router/app_navigation.dart';
import 'package:bazar_suez/router/routes_config/auth_routes.dart';
import 'package:bazar_suez/router/routes_config/shared_routes.dart';
import 'package:bazar_suez/router/routes_config/user_routes.dart';
import 'package:bazar_suez/router/routes_config/market_routes.dart';
import 'package:bazar_suez/Layouts/market_layout.dart';
import 'package:bazar_suez/Layouts/user_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

// 🧩 Firebase
import 'firebase_options.dart';

// 🧠 Auth
import 'authentication/guards/AuthGuard.dart';
import 'authentication/viewModel/AuthViewModel.dart';

// 🛍️ ViewModels
import 'markets/add_product/viewmodels/add_product_viewmodel.dart';
import 'markets/grid_of_categories/ViewModel/ViewModel.dart';
import 'markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';
import 'markets/cart/viewmodels/cart_view_model.dart';
import 'markets/saved_locations/viewmodels/saved_locations_viewmodel.dart';
import 'markets/home_page/viewmodels/home_data_provider.dart';
import 'package:bazar_suez/support/viewmodels/support_viewmodel.dart';
import 'package:bazar_suez/notifications/viewmodels/inbox_viewmodel.dart';


// 🐝 Hive
import 'services/hive_adapters_setup.dart';

// 🔔 FCM Notifications
import 'services/fcm_service.dart';
import 'services/order_notifications/local_notification_service.dart';
import 'services/zones/zone_repository.dart';
import 'package:bazar_suez/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    print('✅ Firebase initialized successfully');

    print('📦 Initializing Hive...');
    await HiveAdaptersSetup.initializeHive().timeout(
      const Duration(seconds: 5),
    );
    print('✅ Hive initialized successfully');

    // الإشعارات والـ Zones مش حرجة - لو فشلوا التطبيق لازم يفتح برضو
    print('🔔 Initializing local notifications + FCM...');
    try {
      await LocalNotificationService.instance.initialize().timeout(
        const Duration(seconds: 5),
      );
      await FcmService().initialize().timeout(
        const Duration(seconds: 5),
      );
      print('✅ FCM Service initialized successfully');
    } catch (e) {
      print('⚠️ FCM init failed (non-critical): $e');
    }

    print('🗺️ Initializing zones...');
    try {
      await ZoneRepository.instance.initialize().timeout(
        const Duration(seconds: 5),
      );
      print('✅ Zones initialized successfully');
    } catch (e) {
      print('⚠️ Zones init failed (non-critical): $e');
    }

    print('🚀 Starting app...');
    runApp(const MyApp());
  } catch (e) {
    print('❌ Error during initialization: $e');
    // Run app anyway with error handling
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthGuard _authGuard;
  late final ConnectionService _connectionService;
  late final Future<GoRouter> _routerFuture;

  @override
  void initState() {
    super.initState();
    _authGuard = AuthGuard();
    _connectionService = ConnectionService();
    _connectionService.initialize();
    // إضافة timeout للراوتر عشان لو الاتصال بطيء أو مفيش نت، التطبيق ميقفش
    _routerFuture = createRouter(_authGuard).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⚠️ Router creation timed out, creating fallback router');
        return _createFallbackRouter();
      },
    );
  }

  /// راوتر احتياطي في حالة timeout أو خطأ
  GoRouter _createFallbackRouter() {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: _authGuard,
      routes: [
        ...authRoutes,
        ShellRoute(
          builder: (context, state, child) {
            if (_authGuard.isMarketOwner) {
              return MarketLayout(child: child);
            } else {
              return UserLayout(child: child);
            }
          },
          routes: [...sharedRoutes, ...userRoutes, ...marketRoutes],
        ),
      ],
    );
    registerAppRouter(router);
    return router;
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AppBootstrap(
      routerFuture: _routerFuture,
      buildApp: _buildApp,
      createFallbackRouter: _createFallbackRouter,
    );
  }

  Widget _buildApp(GoRouter router) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authGuard),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AddProductViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryFilterViewModel()),
        ChangeNotifierProvider(
          create: (_) {
            final cartViewModel = CartViewModel();
            Future.microtask(cartViewModel.initialize);
            return cartViewModel;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final savedLocationsViewModel = SavedLocationsViewModel();
            Future.microtask(savedLocationsViewModel.initialize);
            return savedLocationsViewModel;
          },
        ),
        ChangeNotifierProvider(create: (_) => HomeDataProvider()),
        ChangeNotifierProvider(create: (_) => SupportViewModel()),
        ChangeNotifierProvider(create: (_) => InboxViewModel()),
        ChangeNotifierProvider<ConnectionService>.value(
          value: _connectionService,
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        locale: const Locale("ar"),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale("ar"), Locale("en")],
        routerConfig: router,
        builder: (context, child) =>
            ConnectivityListener(child: child ?? const SizedBox.shrink()),
        theme: ThemeData(
          fontFamily: "NotoSansArabic",
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 16, fontFamily: "NotoSansArabic"),
            bodyLarge: TextStyle(fontSize: 18, fontFamily: "NotoSansArabic"),
            headlineSmall: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: "NotoSansArabic",
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: "NotoSansArabic",
            ),
            titleLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: "NotoSansArabic",
            ),
          ),
        ),
      ),
    );
  }
}

/// يعرض شاشة الـ Splash حتى تكتمل الأنيميشن ويصبح الراوتر جاهزاً.
class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap({
    required this.routerFuture,
    required this.buildApp,
    required this.createFallbackRouter,
  });

  final Future<GoRouter> routerFuture;
  final Widget Function(GoRouter router) buildApp;
  final GoRouter Function() createFallbackRouter;

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  GoRouter? _router;
  bool _splashDone = false;
  bool _routerFailed = false;

  @override
  void initState() {
    super.initState();
    widget.routerFuture
        .then((router) {
          if (mounted) setState(() => _router = router);
        })
        .catchError((Object error) {
          print('❌ Router error: $error');
          if (mounted) {
            setState(() {
              _router = widget.createFallbackRouter();
              _routerFailed = true;
            });
          }
        });
  }

  bool get _readyToShowApp =>
      _splashDone && (_router != null || _routerFailed);

  @override
  Widget build(BuildContext context) {
    if (!_readyToShowApp) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onComplete: () {
            if (mounted) setState(() => _splashDone = true);
          },
        ),
      );
    }

    return widget.buildApp(_router!);
  }
}
