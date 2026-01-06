// import 'package:bazar_suez/router/router.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:provider/provider.dart';
// import 'package:go_router/go_router.dart';
// import 'package:firebase_core/firebase_core.dart';

// // 🧩 Firebase
// import 'firebase_options.dart';

// // 🧠 Auth
// import 'authentication/guards/AuthGuard.dart';
// import 'authentication/viewModel/AuthViewModel.dart';

// // 🛍️ ViewModels
// import 'markets/add_product/viewmodels/add_product_viewmodel.dart';
// import 'markets/grid_of_categories/ViewModel/ViewModel.dart';
// import 'markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';
// import 'markets/cart/viewmodels/cart_view_model.dart';
// import 'markets/saved_locations/viewmodels/saved_locations_viewmodel.dart';

// // 🐝 Hive
// import 'services/hive_adapters_setup.dart';

// // 🔔 FCM Notifications
// import 'services/fcm_service.dart';

// // 🌍 App Router
// import 'package:bazar_suez/router/app_router.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   try {
//     print('🔥 Initializing Firebase...');
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     print('✅ Firebase initialized successfully');

//     print('📦 Initializing Hive...');
//     await HiveAdaptersSetup.initializeHive();
//     print('✅ Hive initialized successfully');

//     print('🔔 Initializing FCM Service...');
//     await FcmService().initialize();
//     print('✅ FCM Service initialized successfully');

//     print('🚀 Starting app...');
//     runApp(const MyApp());
//   } catch (e) {
//     print('❌ Error during initialization: $e');
//     // Run app anyway with error handling
//     runApp(const MyApp());
//   }
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late final AuthGuard _authGuard;
//   late Future<GoRouter> _routerFuture;

//   @override
//   void initState() {
//     super.initState();
//     _authGuard = AuthGuard();
//     _routerFuture = createRouter(_authGuard);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => _authGuard),
//         ChangeNotifierProvider(create: (_) => AuthViewModel()),
//         ChangeNotifierProvider(create: (_) => AddProductViewModel()),
//         ChangeNotifierProvider(create: (_) => CategoryViewModel()),
//         ChangeNotifierProvider(create: (_) => CategoryFilterViewModel()),
//         ChangeNotifierProvider(
//           create: (_) {
//             final cartViewModel = CartViewModel();
//             cartViewModel.initialize();
//             return cartViewModel;
//           },
//         ),
//         ChangeNotifierProvider(
//           create: (_) {
//             final savedLocationsViewModel = SavedLocationsViewModel();
//             savedLocationsViewModel.initialize();
//             return savedLocationsViewModel;
//           },
//         ),
//       ],
//       child: FutureBuilder<GoRouter>(
//         future: _routerFuture,
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const MaterialApp(
//               home: Scaffold(body: Center(child: CircularProgressIndicator())),
//             );
//           }

//           return MaterialApp.router(
//             debugShowCheckedModeBanner: false,
//             locale: const Locale("ar"),
//             localizationsDelegates: const [
//               GlobalMaterialLocalizations.delegate,
//               GlobalWidgetsLocalizations.delegate,
//               GlobalCupertinoLocalizations.delegate,
//             ],
//             supportedLocales: const [Locale("ar"), Locale("en")],
//             routerConfig: snapshot.data!,
//             theme: ThemeData(
//               fontFamily: "Tajawal",
//               textTheme: const TextTheme(
//                 bodyMedium: TextStyle(fontSize: 16, fontFamily: "Tajawal"),
//                 bodyLarge: TextStyle(fontSize: 18, fontFamily: "Tajawal"),
//                 headlineSmall: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: "Tajawal",
//                 ),
//                 headlineMedium: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: "Tajawal",
//                 ),
//                 titleLarge: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   fontFamily: "Tajawal",
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
