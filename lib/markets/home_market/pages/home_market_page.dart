import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// استيراد الودجات اللي قسمناها
import 'package:bazar_suez/markets/home_market/widgets/market_cover_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_tabbar_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_appbar.dart';
import 'package:bazar_suez/markets/home_market/widgets/market_product_section.dart';
import 'package:bazar_suez/markets/home_market/widgets/floating_cart_bar.dart';
import 'package:bazar_suez/markets/home_market/viewmodels/market_details_viewmodel.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      _scrollOffsetNotifier.value = _scrollController.offset;

      if (_isProgrammaticScroll) return;

      _scrollDebounceTimer?.cancel();
      _scrollDebounceTimer = Timer(
        const Duration(milliseconds: 50),
        _updateTabBasedOnScroll,
      );
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
        body: ValueListenableBuilder<double>(
          valueListenable: _scrollOffsetNotifier,
          builder: (context, scrollOffset, _) {
            final bool isMerged = scrollOffset >= mergePoint;
            final vm = context.watch<MarketDetailsViewModel>();

            // 🔹 ترتيب الفئات (الأكثر مبيعاً -> العروض -> الباقي)
            List<MarketCategoryModel> _orderedCategories() {
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

            final ordered = _orderedCategories();

            // تحديث TabController عند تغير عدد الفئات
            final int desiredLength = ordered.isEmpty ? 1 : ordered.length;
            if (_tabController.length != desiredLength) {
              _tabController.dispose();
              _tabController = TabController(
                length: desiredLength,
                vsync: this,
              );
            }

            final bool tabReady =
                ordered.isNotEmpty && _tabController.length == ordered.length;

            return Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: MarketCoverSection(
                        coverHeight: coverHeight,
                        infoBoxHeight: infoBoxHeight,
                        scrollOffset: scrollOffset,
                        store: vm.store,
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
                MarketAppBar(
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
                ),
                const FloatingCartBar(),
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
}
