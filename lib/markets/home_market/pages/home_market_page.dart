import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/home_page/viewmodels/home_data_provider.dart';

import 'package:bazar_suez/markets/home_market/widgets/market_cover_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_tabbar_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_appbar.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_product_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/floating_cart_bar.dart';
import 'package:bazar_suez/markets/home_market/viewmodels/market_details_viewmodel.dart';
import 'package:bazar_suez/markets/license/widgets/license_warning_banner.dart';
import 'package:bazar_suez/markets/search_in_market/pages/search_in_market_page.dart';
import 'package:bazar_suez/markets/search_in_market/viewmodels/search_in_market_viewmodel.dart';

// ══════════════════════════════════════════════════════════════
// دالة تطبيع عربية مشتركة (خارج build لتجنب إعادة الإنشاء)
// ══════════════════════════════════════════════════════════════
String _normalizeArabic(String input) {
  final diacritics = RegExp('[\u064B-\u0652]');
  return input
      .replaceAll(diacritics, '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('اً', 'ا')
      .trim();
}

/// ترتيب الفئات: الأكثر مبيعاً → العروض → الباقي
List<MarketCategoryModel> _orderedCategories(
    List<MarketCategoryModel> categories) {
  MarketCategoryModel? best;
  MarketCategoryModel? offers;
  final others = <MarketCategoryModel>[];

  for (final cat in categories) {
    // ❌ تم إزالة: `if (cat.items.isEmpty) continue;`
    // لأن الفئات أثناء التحميل تكون .isEmpty وتخطيها يمنع الـ Tabs من الظهور
    final key = _normalizeArabic(cat.name);
    if (key == 'الاكثر مبيعا') {
      best ??= cat;
    } else if (key == 'العروض') {
      offers ??= cat;
    } else {
      others.add(cat);
    }
  }

  others.sort((a, b) => a.order.compareTo(b.order));

  return [
    if (best != null) best,
    if (offers != null) offers,
    ...others,
  ];
}

// ══════════════════════════════════════════════════════════════
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

  Map<String, GlobalKey> _sectionKeys = {};
  bool _isProgrammaticScroll = false;
  bool _isScrolling = false;
  Timer? _scrollDebounceTimer;
  String? _userMarketId;
  late final MarketDetailsViewModel _vm;

  bool _scrollOffsetNotifyScheduled = false;

  // آخر قائمة فئات مرتبة — لتجنب إعادة الحساب في كل rebuild
  List<MarketCategoryModel> _lastOrdered = [];
  int _lastOrderedHash = 0;

  bool _isStoreOwner(String storeId) {
    return _userMarketId != null && _userMarketId == storeId;
  }

  void _resolveUserMarketId() {
    try {
      final homeData = context.read<HomeDataProvider>();
      _userMarketId = homeData.myStore?.id;
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _vm = MarketDetailsViewModel();

    if (widget.marketLink != null && widget.marketLink!.isNotEmpty) {
      _vm.loadByLink(widget.marketLink!);
    } else {
      _vm.startCategoriesStream();
    }

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
      final ctx = key.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero).dy;
      final topPadding = MediaQuery.of(ctx).padding.top;
      final appBarHeight = kToolbarHeight + topPadding;
      final totalHeaderHeight = appBarHeight + tabBarHeight;

      if (position < totalHeaderHeight + 20 && position > -box.size.height / 2) {
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
    } finally {
      _isScrolling = false;
      _isProgrammaticScroll = false;
    }
  }

  /// يُعيد بناء _tabController فقط عند تغيير عدد الفئات — وليس داخل build()
  void _updateTabControllerIfNeeded(int desiredLength) {
    if (_tabController.length == desiredLength) return;
    final old = _tabController;
    _tabController = TabController(length: desiredLength, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  /// حساب الترتيب مرة واحدة حتى لا يُعاد عند كل notify
  List<MarketCategoryModel> _getOrdered(List<MarketCategoryModel> categories) {
    final hash = Object.hashAll(categories.map((c) => Object.hash(c.id, c.items.length)));
    if (hash == _lastOrderedHash) return _lastOrdered;
    _lastOrdered = _orderedCategories(categories);
    _lastOrderedHash = hash;
    return _lastOrdered;
  }

  @override
  void didUpdateWidget(covariant MarketAnimatedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.marketLink != widget.marketLink) {
      if (widget.marketLink != null && widget.marketLink!.isNotEmpty) {
        _vm.loadByLink(widget.marketLink!);
      } else {
        _vm.startCategoriesStream();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double mergePoint =
        coverHeight + 40 - kToolbarHeight - MediaQuery.of(context).padding.top;

    return ChangeNotifierProvider.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<MarketDetailsViewModel>(
          builder: (context, vm, _) {
            // ══════ فحص الترخيص ══════
            if (vm.store != null &&
                vm.store!.isLicenseExpired &&
                !_isStoreOwner(vm.store!.id)) {
              return _buildStoreUnavailablePage(context, vm.store!);
            }

            final bool isBusyStore = vm.store != null && !vm.store!.available;
            final bool isClosedStore =
                vm.store != null && vm.store!.isClosedByWorkingHours;
            final bool isOrderingBlocked = isBusyStore || isClosedStore;

            // ══════ الفئات المرتبة (محفوظة بالكاش) ══════
            final ordered = _getOrdered(vm.categories);

            // ══════ TabController (يُحدَّث خارج build عبر postFrameCallback) ══════
            final int desiredLength = ordered.isEmpty ? 1 : ordered.length;
            if (_tabController.length != desiredLength) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _updateTabControllerIfNeeded(desiredLength);
              });
            }

            final bool tabReady =
                ordered.isNotEmpty && _tabController.length == ordered.length;

            return Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // ══════ غلاف المتجر (يتحرك بـ ValueListenable فقط) ══════
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

                    // ══════ شريط التبويبات (مثبت) ══════
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

                    // ══════ تحذير إغلاق المتجر ══════
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

                    // ══════ حالة التحميل / الخطأ / المحتوى ══════
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
                          padding: const EdgeInsets.all(16),
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
                            // تحديث مفاتيح الأقسام بكفاءة
                            final newKeys = <String, GlobalKey>{};
                            for (final c in ordered) {
                              newKeys[c.name] =
                                  _sectionKeys[c.name] ?? GlobalKey();
                            }
                            _sectionKeys = newKeys;

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

                // ══════ AppBar العائم (يتحرك بـ ValueListenable فقط) ══════
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
                      storeId: vm.store?.id,
                      isOwner: vm.store != null ? _isStoreOwner(vm.store!.id) : false,
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
    _vm.dispose();
    super.dispose();
  }

  Widget _buildStoreUnavailablePage(BuildContext context, store) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/HomePage'),
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
