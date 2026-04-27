import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../cart/viewmodels/cart_view_model.dart';
import '../../saved_locations/viewmodels/saved_locations_viewmodel.dart';
import '../../saved_locations/widgets/saved_locations_sheet.dart';
import '../../../authentication/guards/AuthGuard.dart';
import '../../../ads/models/ad_model.dart';

class HomeAppColors {
  static const primary = Color(0xFF4E99B4);
  static const primaryDark = Color(0xFF4E99B4);
  static const primaryLight = Color(0xFF5BA8E8);
  static const accent = Color(0xFF4CBBF5);
  static const background = Color.fromARGB(255, 251, 253, 255);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF4E99B4);
  static const textMed = Color(0xFF5A6A8A);
  static const textLight = Color(0xFF9AAAC0);
  static const discountRed = Color(0xFF3A8FE0);
  static const timerBg = Color(0xFF2B7FD4);
  static const gradStart = Color.fromARGB(255, 29, 102, 148);
  static const gradEnd = Color(0xFF4E99B4);
}

class Category {
  final String label;
  final IconData icon;
  const Category({required this.label, required this.icon});
}

class Product {
  final String name;
  final double price;
  final double oldPrice;
  final int discount;
  final String imageUrl;
  const Product({
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.imageUrl,
  });
}

final List<Category> categories = [
  const Category(label: 'Clothes', icon: Icons.checkroom_outlined),
  const Category(label: 'Electronics', icon: Icons.kitchen_outlined),
  const Category(label: 'Shoes', icon: Icons.directions_run_outlined),
  const Category(label: 'Watch', icon: Icons.watch_outlined),
];

final List<Product> products = [
  const Product(
    name: 'High-Quality Shirt',
    price: 269.00,
    oldPrice: 384.00,
    discount: 30,
    imageUrl:
        'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&q=80',
  ),
  const Product(
    name: 'Flava Shoes',
    price: 249.00,
    oldPrice: 389.00,
    discount: 36,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',
  ),
  const Product(
    name: 'Sport Sneakers',
    price: 69.99,
    oldPrice: 99.99,
    discount: 30,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',
  ),
  const Product(
    name: 'Wireless Earbuds',
    price: 49.99,
    oldPrice: 79.99,
    discount: 37,
    imageUrl:
        'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=400&q=80',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _bannerPage = 0;
  int _bannerItemCount = 1;
  int _selectedCategory = 2; // "Popular" default (index 2)
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  final PageController _bannerCtrl = PageController();
  late Timer _bannerTimer;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_bannerItemCount <= 1) return;
      final next = (_bannerPage + 1) % _bannerItemCount;
      _bannerCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _bannerTimer.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeAppColors.background,
      extendBody: true,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecialForYouHeader(),
                  _buildBannerSection(),
                  _buildCategoriesSection(),
                  _buildFlashSaleSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SavedLocationsSheet(),
    );
  }

  Widget _buildSpecialForYouHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '#SpecialForYou',
            style: TextStyle(
              color: HomeAppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'See All',
            style: TextStyle(
              color: HomeAppColors.textMed,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: HomeAppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: HomeAppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Consumer<SavedLocationsViewModel>(
                            builder: (context, locationVm, _) {
                              final isBusy =
                                  locationVm.isInitializing || locationVm.isLoading;

                              final title = isBusy
                                  ? 'جاري تحديد الموقع...'
                                  : locationVm.displayAddress;

                              return GestureDetector(
                                onTap: _openLocationSheet,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 180),
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: locationVm.locationPermissionDenied
                                              ? Colors.white.withOpacity(0.85)
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (isBusy)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Consumer<CartViewModel>(
                        builder: (context, cartVm, _) {
                          return GestureDetector(
                            onTap: () => context.push('/CartPage'),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  if (cartVm.itemCount > 0)
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${cartVm.itemCount}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              height: 1,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    final auth = context.watch<AuthGuard>();
    final isMarketOwner = auth.isMarketOwner;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('app_settings')
            .doc('home_ads')
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final rawAds = (data?['ads'] is List) ? (data?['ads'] as List) : const [];

          final ads = rawAds
              .map((e) => e is Map<String, dynamic> ? AdModel.fromMap(e) : null)
              .whereType<AdModel>()
              .where((ad) => ad.isValid)
              .toList()
            ..sort((a, b) => a.slotId.compareTo(b.slotId));

          // Always prepend a default banner depending on user type.
          final totalCount = 1 + ads.length;
          if (_bannerItemCount != totalCount) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _bannerItemCount = totalCount;
                if (_bannerPage >= _bannerItemCount) _bannerPage = 0;
              });
            });
          }

          return Column(
            children: [
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _bannerCtrl,
                  onPageChanged: (p) => setState(() => _bannerPage = p),
                  itemCount: totalCount,
                  itemBuilder: (ctx, i) {
                    // index 0 => default banner
                    if (i == 0) {
                      final assetPath = isMarketOwner
                          ? 'assets/images/adsmarket.jpg'
                          : 'assets/images/create_market.png';
                      final onTap = isMarketOwner
                          ? () => context.push('/request-ads')
                          : () => context.push('/pricingpage');
                      return _BannerCard(
                        image: AssetImage(assetPath),
                        onTap: onTap,
                      );
                    }

                    final ad = ads[i - 1];
                    final marketLink = ad.targetStoreId;
                    return _BannerCard(
                      image: NetworkImage(ad.imageUrl!),
                      onTap: marketLink == null || marketLink.isEmpty
                          ? null
                          : () => context.push(
                                '/HomeMarketPage?marketLink=$marketLink',
                              ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _bannerPage == i ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _bannerPage == i
                          ? HomeAppColors.primary
                          : HomeAppColors.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category',
                style: TextStyle(
                  color: HomeAppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'See All',
                style: TextStyle(
                  color: HomeAppColors.textMed,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: categories
                .map((c) => _CategoryCard(category: c))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashSaleSection() {
    final tabs = ['All', 'Newest', 'Popular', 'Clothes'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(
                  color: HomeAppColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(tabs.length, (i) {
              final selected = _selectedCategory == i;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? HomeAppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: selected
                            ? HomeAppColors.primary
                            : HomeAppColors.textLight.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        color: selected ? Colors.white : HomeAppColors.textMed,
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (ctx, i) => _ProductCard(product: products[i]),
            ),
          ),
        ],
      ),
    );
  }
  }



class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/Search'),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Colors.white70, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ابحث عن متجر',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final ImageProvider image;
  final VoidCallback? onTap;
  const _BannerCard({required this.image, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: HomeAppColors.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: HomeAppColors.primaryLight),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: HomeAppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: HomeAppColors.primary.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(category.icon, color: HomeAppColors.primary, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          category.label,
          style: const TextStyle(
            color: HomeAppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _wished = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: HomeAppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  widget.product.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: HomeAppColors.background,
                    child: const Icon(
                      Icons.image_outlined,
                      color: HomeAppColors.textLight,
                    ),
                  ),
                  loadingBuilder: (_, child, loading) {
                    if (loading == null) return child;
                    return Container(
                      height: 120,
                      color: HomeAppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: HomeAppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() => _wished = !_wished),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      _wished ? Icons.favorite : Icons.favorite_border,
                      color: _wished ? Colors.red : HomeAppColors.textLight,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    color: HomeAppColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '\$${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: HomeAppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${widget.product.oldPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: HomeAppColors.textLight,
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                      ),
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
}
