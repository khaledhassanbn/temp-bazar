import 'package:bazar_suez/core/network/connection_service.dart';
import 'package:bazar_suez/core/network/connectivity_listener.dart';
import 'package:bazar_suez/router/router.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    print('📦 Initializing Hive...');
    await HiveAdaptersSetup.initializeHive();
    print('✅ Hive initialized successfully');

    print('🔔 Initializing local notifications + FCM...');
    await LocalNotificationService.instance.initialize();
    await FcmService().initialize();
    print('✅ FCM Service initialized successfully');

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
  late Future<GoRouter> _routerFuture;

  @override
  void initState() {
    super.initState();
    _authGuard = AuthGuard();
    _connectionService = ConnectionService();
    _connectionService.initialize();
    _routerFuture = createRouter(_authGuard);
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => _authGuard),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => AddProductViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryFilterViewModel()),
        ChangeNotifierProvider(
          create: (_) {
            final cartViewModel = CartViewModel();
            cartViewModel.initialize();
            return cartViewModel;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final savedLocationsViewModel = SavedLocationsViewModel();
            savedLocationsViewModel.initialize();
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
      child: FutureBuilder<GoRouter>(
        future: _routerFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            locale: const Locale("ar"),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale("ar"), Locale("en")],
            routerConfig: snapshot.data!,
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
          );
        },
      ),
    );
  }
}
