// import 'package:bazar_suez/markets/my_order/pages/PastOrdersPage.dart';
// import 'package:bazar_suez/markets/statistics/pages/sales_stats_page.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:bazar_suez/markets/my_order/pages/MarketOrdersPage.dart';
// // Removed direct page import; routing uses MarketOrdersLoader to resolve marketId
// // Loader not needed when we pass marketId via query parameter
// import 'package:go_router/go_router.dart';
// import 'package:bazar_suez/authentication/guards/AuthGuard.dart';

// // 🧩 Auth Pages
// import 'package:bazar_suez/authentication/pages/signin_with_social.dart';
// import 'package:bazar_suez/authentication/pages/signin_with_mail.dart';
// import 'package:bazar_suez/authentication/pages/Signup.dart';
// import 'package:bazar_suez/authentication/pages/forget_password.dart';

// // 🛒 Market Pages
// import 'package:bazar_suez/markets/grid_of_categories/pages/grid_of_categoies.dart';
// import 'package:bazar_suez/markets/cart/pages/cart_page.dart';
// import 'package:bazar_suez/markets/planes/pages/pricing_page.dart';
// import 'package:bazar_suez/markets/add_product/pages/add_product.dart';
// import 'package:bazar_suez/markets/home_market/pages/home_market_page.dart';
// import 'package:bazar_suez/markets/home_market/pages/ProductDetails.dart';
// import 'package:bazar_suez/markets/Markets/pages/home_market.dart';
// import 'package:bazar_suez/markets/create_market/pages/create_store_page.dart';

// // 🧭 Layouts
// import 'package:bazar_suez/Layouts/user_layout.dart';
// import 'package:bazar_suez/Layouts/market_layout.dart';

// Future<GoRouter> createRouter(AuthGuard authGuard) async {
//   try {
//     print('🔐 Loading user status...');
//     await authGuard.loadUserStatus();
//     print('✅ User status loaded');

//     print('👂 Starting status listener...');
//     authGuard.startStatusListener();
//     print('✅ Status listener started');

//     print('🛣️ Creating router...');
//     return GoRouter(
//       initialLocation: '/PastOrders',
//       refreshListenable: authGuard,

//       redirect: (context, state) {
//         final loggedIn = authGuard.isAuthenticated;
//         final isMarketOwner = authGuard.isMarketOwner;
//         final location = state.matchedLocation;

//         if (!loggedIn && !location.contains('/login')) {
//           return '/login';
//         }

//         if (loggedIn && location.contains('/login')) {
//           return isMarketOwner ? '/HomeMarketPage' : '/CategoriesGrid';
//         }

//         return null;
//       },

//       routes: [
//         // ===============================
//         // 🔹 صفحات الدخول والتسجيل
//         // ===============================
//         GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
//         GoRoute(
//           path: '/login-email',
//           builder: (_, __) => const EmailLoginPage(),
//         ),
//         GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
//         GoRoute(
//           path: '/forgot-password',
//           builder: (_, __) => const ForgotPasswordPage(),
//         ),

//         // ===============================
//         // 🧩 كل الصفحات داخل Layout ديناميكي
//         // ===============================
//         ShellRoute(
//           builder: (context, state, child) {
//             // 🔄 اختيار الـ Layout حسب نوع المستخدم
//             if (authGuard.isMarketOwner) {
//               return MarketLayout(child: child);
//             } else {
//               return UserLayout(child: child);
//             }
//           },
//           routes: [
//             // 🔹 الصفحات المشتركة بين المستخدمين
//             GoRoute(
//               path: '/CategoriesGrid',
//               builder: (_, __) => CategoriesGridPage(),
//             ),
//             GoRoute(
//               path: '/PastOrders',
//               builder: (context, state) {
//                 final marketId = state.uri.queryParameters['marketId'];
//                 if (marketId != null && marketId.isNotEmpty) {
//                   return PastOrdersPage(marketId: marketId);
//                 }

//                 // If marketId not provided, resolve from current user seamlessly
//                 return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//                   future: () async {
//                     final user = FirebaseAuth.instance.currentUser;
//                     if (user == null) throw Exception('Not authenticated');
//                     return FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(user.uid)
//                         .get();
//                   }(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Scaffold(
//                         body: Center(child: CircularProgressIndicator()),
//                       );
//                     }
//                     if (snapshot.hasError ||
//                         !snapshot.hasData ||
//                         !snapshot.data!.exists) {
//                       return const Scaffold(
//                         body: Center(
//                           child: Text('تعذر تحديد المتجر المرتبط بالحساب'),
//                         ),
//                       );
//                     }
//                     final data = snapshot.data!.data();
//                     String? resolvedId;
//                     if (data != null) {
//                       final snake = data['market_id'];
//                       final camel = data['marketId'];
//                       final nested = data['market'];
//                       if (snake is String && snake.isNotEmpty) {
//                         resolvedId = snake;
//                       } else if (camel is String && camel.isNotEmpty) {
//                         resolvedId = camel;
//                       } else if (nested is Map &&
//                           nested['id'] is String &&
//                           (nested['id'] as String).isNotEmpty) {
//                         resolvedId = nested['id'] as String;
//                       }
//                     }
//                     if (resolvedId == null || resolvedId.isEmpty) {
//                       return const Scaffold(
//                         body: Center(
//                           child: Text('لا يوجد متجر مرتبط بهذا الحساب'),
//                         ),
//                       );
//                     }
//                     return PastOrdersPage(marketId: resolvedId);
//                   },
//                 );
//               },
//             ),
//             GoRoute(path: '/CartPage', builder: (_, __) => const CartPage()),
//             GoRoute(
//               path: '/pricingpage',
//               builder: (_, __) => const PricingPage(),
//             ),

//             // ✅ أضف الصفحة الناقصة هنا 👇👇👇
//             GoRoute(
//               path: '/FoodHomePage',
//               builder: (context, state) {
//                 final categoryId = state.uri.queryParameters['categoryId'];
//                 return FoodHomePage(categoryId: categoryId);
//               },
//             ),

//             // 🔹 صفحات التاجر
//             GoRoute(
//               path: '/HomeMarketPage',
//               builder: (context, state) {
//                 final marketLink = state.uri.queryParameters['marketLink'];
//                 return MarketAnimatedPage(marketLink: marketLink);
//               },
//             ),
//             GoRoute(
//               path: '/addproduct',
//               builder: (_, __) => const AddProductModernPage(),
//             ),
//             GoRoute(
//               path: '/SalesStatsPage',
//               builder: (_, __) => const SalesStatsPage(),
//             ),
//             GoRoute(
//               path: '/myorder',
//               builder: (context, state) {
//                 final marketId = state.uri.queryParameters['marketId'];
//                 if (marketId != null && marketId.isNotEmpty) {
//                   return MarketOrdersPage(marketId: marketId);
//                 }

//                 // If marketId not provided, resolve from current user seamlessly
//                 return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
//                   future: () async {
//                     final user = FirebaseAuth.instance.currentUser;
//                     if (user == null) throw Exception('Not authenticated');
//                     return FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(user.uid)
//                         .get();
//                   }(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Scaffold(
//                         body: Center(child: CircularProgressIndicator()),
//                       );
//                     }
//                     if (snapshot.hasError ||
//                         !snapshot.hasData ||
//                         !snapshot.data!.exists) {
//                       return const Scaffold(
//                         body: Center(
//                           child: Text('تعذر تحديد المتجر المرتبط بالحساب'),
//                         ),
//                       );
//                     }
//                     final data = snapshot.data!.data();
//                     String? resolvedId;
//                     if (data != null) {
//                       final snake = data['market_id'];
//                       final camel = data['marketId'];
//                       final nested = data['market'];
//                       if (snake is String && snake.isNotEmpty) {
//                         resolvedId = snake;
//                       } else if (camel is String && camel.isNotEmpty) {
//                         resolvedId = camel;
//                       } else if (nested is Map &&
//                           nested['id'] is String &&
//                           (nested['id'] as String).isNotEmpty) {
//                         resolvedId = nested['id'] as String;
//                       }
//                     }
//                     if (resolvedId == null || resolvedId.isEmpty) {
//                       return const Scaffold(
//                         body: Center(
//                           child: Text('لا يوجد متجر مرتبط بهذا الحساب'),
//                         ),
//                       );
//                     }
//                     return MarketOrdersPage(marketId: resolvedId);
//                   },
//                 );
//               },
//             ),
//             // 🔹 صفحات عامة
//             GoRoute(
//               path: '/productdetails',
//               builder: (context, state) {
//                 final marketId = state.uri.queryParameters['marketId'];
//                 final categoryId = state.uri.queryParameters['categoryId'];
//                 final itemId = state.uri.queryParameters['itemId'];
//                 return ProductDetailsPage(
//                   marketId: marketId,
//                   categoryId: categoryId,
//                   itemId: itemId,
//                 );
//               },
//             ),
//             GoRoute(
//               path: '/create-store',
//               builder: (context, state) {
//                 final products = state.uri.queryParameters['products'];
//                 final duration = state.uri.queryParameters['duration'];
//                 return CreateStoreModernPage(
//                   numberOfProducts: products != null
//                       ? int.tryParse(products)
//                       : null,
//                   selectedDuration: duration,
//                 );
//               },
//             ),
//           ],
//         ),
//       ],
//     );
//   } catch (e) {
//     print('❌ Error creating router: $e');
//     // Return a basic router as fallback
//     return GoRouter(
//       initialLocation: '/login',
//       routes: [GoRoute(path: '/login', builder: (_, __) => const LoginPage())],
//     );
//   }
// }
