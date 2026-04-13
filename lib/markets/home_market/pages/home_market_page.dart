import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/home_page/viewmodels/home_data_provider.dart';

// استيراد الودجات اللي قسمناها
import 'package:bazar_suez/markets/home_market/widgets/market_cover_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_tabbar_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_appbar.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_product_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/floating_cart_bar.dart';
import 'package:bazar_suez/markets/home_market/viewmodels/market_details_viewmodel.dart';
import 'package:bazar_suez/markets/license/widgets/license_warning_banner.dart';
import 'package:bazar_suez/markets/search_in_market/pages/search_in_market_page.dart';
import 'package:bazar_suez/markets/search_in_market/viewmodels/search_in_market_viewmodel.dart';

class MarketAnimatedPage extends StatefulWidget {
  final String? marketLink;
  const MarketAnimatedPage({super.key, this.marketLink});

  @override
  State<MarketAnimatedPage> createState() => _MarketAnimatedPageState();
}

class _MarketAnimatedPageState extends State<MarketAnimatedPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffsetNotifier = ValueNotifier(0.0);

  final double coverHeight = 340;
  final double infoBoxHeight = 160;
  final double tabBarHeight = 50;

  late TabController _tabController;

  // 🔹 مفاتيح الأقسام لتحديد أماكنها
  Map<String, GlobalKey> _sectionKeys = {};

  bool _isProgrammaticScroll = false;
  bool _isScrolling = false;
  Timer? _scrollDebounceTimer;
  String? _userMarketId;

  /// دمج تحديثات التمرير في إطار واحد يقلّل إعادة بناء الغلاف وشريط التطبيق على كل بكسل.
  bool _scrollOffsetNotifyScheduled = false;

  /// يتحقق إذا كان المستخدم الحالي هو صاحب المتجر
  bool _isStoreOwner(String storeId) {
    return _userMarketId != null && _userMarketId == storeId;
  }

  /// يأخذ معرف متجر المستخدم من HomeDataProvider (بدون query إضافي)
  void _resolveUserMarketId() {
    try {
      final homeData = context.read<HomeDataProvider>();
      _userMarketId = homeData.myStore?.id;
    } catch (_) {
      // HomeDataProvider مش متاح — نتجاهل
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveUserMarketId();
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      _scheduleScrollOffsetNotification();

      if (_isProgrammaticScroll) return;

      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(
        const Duration(milliseconds: 50),
        _updateTabBasedOnScroll,
      );
    });
  }

  void _scheduleScrollOffsetNotification() {
    if (_scrollOffsetNotifyScheduled) return;
    _scrollOffsetNotifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollOffsetNotifyScheduled = false;
      if (!_scrollController.hasClients) return;
      final offset = _scrollController.offset;
      if (_scrollOffsetNotifier.value != offset) {
        _scrollOffsetNotifier.value = offset;
      }
    });
  }

  void _updateTabBasedOnScroll() {
    for (int i = 0; i < _sectionKeys.length; i++) {
      final key = _sectionKeys.values.elementAt(i);
      final context = key.currentContext;
      if (context == null) continue;

      final box = context.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero).dy;
      final topPadding = MediaQuery.of(context).padding.top;
      final appBarHeight = kToolbarHeight + topPadding;
      final totalHeaderHeight = appBarHeight + tabBarHeight;

      if (position < totalHeaderHeight + 20 &&
          position > -box.size.height / 2) {
        if (_tabController.index != i) {
          _tabController.animateTo(
            i,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
        break;
      }
    }
  }

  Future<void> _scrollToCategory(int index) async {
    if (_isScrolling) return;
    _isScrolling = true;
    _isProgrammaticScroll = true;

    final key = _sectionKeys.values.elementAt(index);
    try {
      await Future.delayed(const Duration(milliseconds: 50));

      if (key.currentContext == null) return;

      final box = key.currentContext!.findRenderObject() as RenderBox;
      final currentPosition = box.localToGlobal(Offset.zero).dy;
      final topPadding = MediaQuery.of(context).padding.top;
      final appBarHeight = kToolbarHeight + topPadding;
      final desiredTop = appBarHeight + tabBarHeight + 16;
      final currentOffset = _scrollController.offset;
      final targetOffset = (currentOffset + currentPosition - desiredTop).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      await _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } catch (_) {
      // تجاهل أي خطأ طفيف
    } finally {
      _isScrolling = false;
      _isProgrammaticScroll = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double mergePoint =
        coverHeight + 40 - kToolbarHeight - MediaQuery.of(context).padding.top;

    return ChangeNotifierProvider(
      create: (_) {
        final vm = MarketDetailsViewModel();
        if (widget.marketLink != null && widget.marketLink!.isNotEmpty) {
          vm.loadByLink(widget.marketLink!);
        } else {
          vm.startCategoriesStream();
        }
        return vm;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<MarketDetailsViewModel>(
          builder: (context, vm, _) {
            final bool isBusyStore = vm.store != null && !vm.store!.available;
            final bool isClosedStore =
                vm.store != null && vm.store!.isClosedByWorkingHours;
            final bool isOrderingBlocked = isBusyStore || isClosedStore;

            // ═══════════════════════════════════════════════════════════════
            // 🔒 التحقق من صلاحية الترخيص للمستخدمين الآخرين
            // إذا كان الترخيص منتهياً والزائر ليس صاحب المتجر = عرض صفحة غير متاح
            // ═══════════════════════════════════════════════════════════════
            if (vm.store != null &&
                vm.store!.isLicenseExpired &&
                !_isStoreOwner(vm.store!.id)) {
              return _buildStoreUnavailablePage(context, vm.store!);
            }

            // 🔹 ترتيب الفئات (الأكثر مبيعاً -> العروض -> الباقي)
            List<MarketCategoryModel> orderedCategories() {
              String normalizeArabic(String input) {
                final diacritics = RegExp('[\u064B-\u0652]');
                return input
                    .replaceAll(diacritics, '')
                    .replaceAll('أ', 'ا')
                    .replaceAll('إ', 'ا')
                    .replaceAll('آ', 'ا')
                    .replaceAll('ى', 'ي')
                    .replaceAll('ة', 'ه')
                    .trim();
              }

              final normalizedCategories = vm.categories
                  .map((c) => MapEntry(normalizeArabic(c.name), c))
                  .toList();

              MarketCategoryModel? best;
              MarketCategoryModel? offers;
              final others = <MarketCategoryModel>[];

              for (final entry in normalizedCategories) {
                final key = entry.key;
                final cat = entry.value;
                if (cat.items.isEmpty) continue;
                if (key == 'الاكثر مبيعا') {
                  best ??= cat;
                } else if (key == 'العروض') {
                  offers ??= cat;
                } else {
                  others.add(cat);
                }
              }

              others.sort((a, b) => a.order.compareTo(b.order));

              final ordered = <MarketCategoryModel>[];
              if (best != null) ordered.add(best);
              if (offers != null) ordered.add(offers);
              ordered.addAll(others);
              return ordered;
            }

            final ordered = orderedCategories();

            // تحديث طول التبويبات: لا نستدعي dispose للـ controller القديم أثناء البناء
            final int desiredLength = ordered.isEmpty ? 1 : ordered.length;
            if (_tabController.length != desiredLength) {
              final TabController oldController = _tabController;
              _tabController = TabController(
                length: desiredLength,
                vsync: this,
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                oldController.dispose();
              });
            }

            final bool tabReady =
                ordered.isNotEmpty && _tabController.length == ordered.length;

            return Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _scrollOffsetNotifier,
                        builder: (context, scrollOffset, _) {
                          return MarketCoverSection(
                            coverHeight: coverHeight,
                            infoBoxHeight: infoBoxHeight,
                            scrollOffset: scrollOffset,
                            store: vm.store,
                          );
                        },
                      ),
                    ),
                    if (tabReady)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: MarketTabBarSection(
                          tabController: _tabController,
                          tabBarHeight: tabBarHeight,
                          onTabSelected: (i) {
                            if (!_isScrolling) _scrollToCategory(i);
                          },
                          tabs: ordered.map((c) => c.name).toList(),
                        ),
                      ),
                    if (isOrderingBlocked)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F1DE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isClosedStore
                                ? 'هذا المتجر مغلق حاليًا حسب مواعيد العمل. يمكنك تصفح القائمة، لكن الطلب غير متاح الآن.'
                                : 'هذا المتجر مشغول حاليًا. يمكنك تصفح القائمة، لكن الطلب غير متاح الآن.',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5A4A1B),
                            ),
                          ),
                        ),
                      ),
                    if (vm.isLoading)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (vm.errorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'حدث خطأ: ${vm.errorMessage!}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else if (ordered.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Builder(
                          builder: (context) {
                            _sectionKeys = {
                              for (final c in ordered)
                                c.name: _sectionKeys[c.name] ?? GlobalKey(),
                            };

                            return MarketProductSection(
                              sectionKeys: _sectionKeys,
                              categories: ordered,
                              marketId: vm.store?.id ?? 'kb',
                            );
                          },
                        ),
                      ),
                  ],
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _scrollOffsetNotifier,
                  builder: (context, scrollOffset, _) {
                    final bool isMerged = scrollOffset >= mergePoint;
                    return MarketAppBar(
                      scrollOffset: scrollOffset,
                      isMerged: isMerged,
                      tabController: _tabController,
                      tabBarHeight: tabBarHeight,
                      storeName: vm.store?.name,
                      tabs: tabReady
                          ? ordered.map((c) => c.name).toList()
                          : const [],
                      onTabSelected: (i) {
                        if (!_isScrolling) _scrollToCategory(i);
                      },
                      onSearchPressed: vm.store != null && ordered.isNotEmpty
                          ? () {
                              final marketId = vm.store!.id;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (ctx) => ChangeNotifierProvider(
                                    create: (_) => SearchInMarketViewModel(
                                      marketId: marketId,
                                      categories: ordered,
                                    ),
                                    child: const SearchInMarketPage(),
                                  ),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
                if (!isOrderingBlocked) const FloatingCartBar(),
                // === Overlay حجب الصفحة عند انتهاء الترخيص (لصاحب المتجر فقط) ===
                if (vm.store != null && _isStoreOwner(vm.store!.id))
                  LicenseExpiredOverlay(store: vm.store!),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollDebounceTimer?.cancel();
    _scrollController.dispose();
    _tabController.dispose();
    _scrollOffsetNotifier.dispose();
    super.dispose();
  }

  /// صفحة تظهر للمستخدمين الآخرين عندما يكون ترخيص المتجر منتهياً
  Widget _buildStoreUnavailablePage(BuildContext context, store) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            context.go('/HomePage');
          },
        ),
        title: Text(
          store.name ?? 'المتجر',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // أيقونة المتجر المغلق
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store_mall_directory_outlined,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 32),
              // العنوان
              const Text(
                'المتجر غير متاح حالياً',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // الوصف
              Text(
                'هذا المتجر غير متاح للزيارة في الوقت الحالي.\nيرجى المحاولة لاحقاً.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // زر العودة للصفحة الرئيسية
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home_outlined),
                  label: const Text(
                    'العودة للصفحة الرئيسية',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4E99B4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
