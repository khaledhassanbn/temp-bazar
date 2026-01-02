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
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFFF59D),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const HungerstationHome(),
    );
  }
}

class HungerstationHome extends StatefulWidget {
  const HungerstationHome({Key? key}) : super(key: key);

  @override
  State<HungerstationHome> createState() => _HungerstationHomeState();
}

class _HungerstationHomeState extends State<HungerstationHome> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 100 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar with image background
          SliverAppBar(
            expandedHeight: _isScrolled ? 0 : 200,
            pinned: true,
            backgroundColor: const Color(0xFFFFF59D),
            flexibleSpace: _isScrolled
                ? null
                : FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=400&fit=crop',
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 50,
                          right: 16,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.menu, color: Colors.white, size: 28),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: const [
                                      Text(
                                        'Al Wurud',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'الطائف، الرياض، السعودية',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.location_on, color: Colors.green, size: 28),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.search, color: Colors.grey),
                                    SizedBox(width: 12),
                                    Text(
                                      'ابحث عن الطاعم والمتاجر',
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
            title: _isScrolled
                ? Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Colors.grey, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ابحث عن الطاعم والمتاجر',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'An Nasim Al Gharbi'.length > 20
                                ? '${'An Nasim Al Gharbi'.substring(0, 20)}...'
                                : 'An Nasim Al Gharbi',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '5141 طريق عبدالرحمن بن عوف، 5141، النسيم الغربي...'.length > 35
                                ? '${'5141 طريق عبدالرحمن بن عوف، 5141، النسيم الغربي...'.substring(0, 35)}...'
                                : '5141 طريق عبدالرحمن بن عوف، 5141',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.location_on, color: Colors.green, size: 24),
                    ],
                  )
                : null,
          ),

          // Categories Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'وش ودك تطلب اليوم؟',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double itemWidth = (constraints.maxWidth - 48) / 4;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.end,
                        children: [
                          _buildCategoryItem(
                            'استلم بنفسك',
                            'https://images.unsplash.com/photo-1534723328310-e82dad3ee43f?w=400&h=400&fit=crop',
                            'خصم حتى 30',
                            itemWidth,
                          ),
                          _buildCategoryItem(
                            'مقاضي',
                            'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=400&h=400&fit=crop',
                            null,
                            itemWidth,
                          ),
                          _buildCategoryItem(
                            'H ماركت',
                            'https://images.unsplash.com/photo-1543168256-418811576931?w=400&h=400&fit=crop',
                            '20 دقيقة',
                            itemWidth,
                          ),
                          _buildCategoryItem(
                            'مطاعم',
                            'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=400&h=400&fit=crop',
                            '+80,000',
                            itemWidth,
                          ),
                          _buildCategoryItem(
                            'هدايا',
                            'https://images.unsplash.com/photo-1513885535751-8b9238bd345a?w=400&h=400&fit=crop',
                            'خصم حتى 30',
                            itemWidth,
                          ),
                          _buildCategoryItem(
                            'ورود وأكثر',
                            'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400&h=400&fit=crop',
                            null,
                            itemWidth,
                          ),
                          _buildCategoryItem(
                            'صيدليات',
                            'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=400&h=400&fit=crop',
                            null,
                            itemWidth,
                          ),
                          _buildCategoryItem(
                            'قهوة وحلى',
                            'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400&h=400&fit=crop',
                            null,
                            itemWidth,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Selections Section (Horizontal)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'مختارات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildHorizontalRestaurantCard(
                          'شاورما زينة',
                          'ساندوتشات، مأكولات',
                          '20 - 40 دقيقة',
                          null,
                          '4.3',
                          '189',
                          'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=800&h=400&fit=crop',
                          'توصيل مجاني',
                        ),
                        const SizedBox(width: 12),
                        _buildHorizontalRestaurantCard(
                          'بلوفى',
                          'هندي، معجنات',
                          '20 - 35 دقيقة',
                          '20 ريال',
                          '4.5',
                          '275',
                          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=400&fit=crop',
                          'توصيل مجاني وقسيمة 10 ريال',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nearby Stores Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'المتاجر القريبة منك',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildNearbyStore(
                          'هنقرستيشن ماركت',
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/7/74/Spotify_App_Logo.svg/512px-Spotify_App_Logo.svg.png',
                          '10 دقيقة',
                        ),
                        const SizedBox(width: 16),
                        _buildNearbyStore(
                          'كارفور',
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Carrefour_logo.svg/512px-Carrefour_logo.svg.png',
                          '40 دقيقة',
                        ),
                        const SizedBox(width: 16),
                        _buildNearbyStore(
                          'السدحان',
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/Adidas_logo.png/512px-Adidas_logo.png',
                          '30 دقيقة',
                        ),
                        const SizedBox(width: 16),
                        _buildNearbyStore(
                          'بنده',
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Spotify_logo_with_text.svg/512px-Spotify_logo_with_text.svg.png',
                          '35 دقيقة',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Popular Groceries Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'أشهر البقالات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildHorizontalRestaurantCard(
                          'العثيم',
                          'سوبر ماركت',
                          '30 - 45 دقيقة',
                          '12 ريال',
                          '4.3',
                          '26251',
                          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&h=400&fit=crop',
                          'توصيل مجاني وقسيمة 10 ريال',
                        ),
                        const SizedBox(width: 12),
                        _buildHorizontalRestaurantCard(
                          'السدحان',
                          'سوبر ماركت',
                          '30 - 45 دقيقة',
                          null,
                          '4.1',
                          '15234',
                          'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800&h=400&fit=crop',
                          'توصيل مجاني',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Best Restaurants Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'أفضل المطاعم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildHorizontalRestaurantCard(
                          'لافونا',
                          'إيطالي، بيتزا',
                          '25 - 40 دقيقة',
                          '15 ريال',
                          '4.6',
                          '132',
                          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=400&fit=crop',
                          'خصم 20%',
                        ),
                        const SizedBox(width: 12),
                        _buildHorizontalRestaurantCard(
                          'استر',
                          'مأكولات بحرية',
                          '30 - 50 دقيقة',
                          null,
                          '4.7',
                          '892',
                          'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=800&h=400&fit=crop',
                          'توصيل مجاني',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFFC107),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'العروض',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, String imageUrl, String? badge, double width) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: width * 0.85,
                height: width * 0.85,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRestaurantCard(
    String name,
    String cuisine,
    String time,
    String? deliveryFee,
    String rating,
    String reviews,
    String imageUrl,
    String offer,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_border, size: 14),
                      const SizedBox(width: 4),
                      Text('($reviews) $rating', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                    ],
                  ),
                ),
              ),
              if (offer.isNotEmpty)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          offer,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (deliveryFee != null)
                      Row(
                        children: [
                          const Icon(Icons.delivery_dining, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            deliveryFee,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      )
                    else
                      const SizedBox(),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    Text(
                      cuisine,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyStore(String name, String logoUrl, String time) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.store, size: 40, color: Colors.grey);
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}