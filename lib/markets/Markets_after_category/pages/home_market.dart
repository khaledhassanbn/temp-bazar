import 'package:bazar_suez/markets/Markets_after_category/widget/CategorySelector.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/best_restaurants_section.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/restaurant_card.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/auto_scrolling_ads.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/market_Items_List.dart';
import 'package:flutter/material.dart';
import 'package:bazar_suez/markets/Markets_after_category/widget/collapsible_header.dart'; // ← الودجت الجديدة
import 'package:provider/provider.dart';
import 'package:bazar_suez/markets/Markets_after_category/viewmodel/category_filter_viewmodel.dart';

class FoodHomePage extends StatefulWidget {
  final String? categoryId;
  const FoodHomePage({super.key, this.categoryId});

  @override
  State<FoodHomePage> createState() => _FoodHomePageState();
}

class _FoodHomePageState extends State<FoodHomePage> {
  final ScrollController scrollController = ScrollController();
  bool showHeader = true;
  double lastOffset = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    // تحميل بيانات الكاتيجوري الأولية إذا وصلت من الراوتر
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        final vm = context.read<CategoryFilterViewModel>();
        vm.setCategory(widget.categoryId);
      }
    });
  }

  void _scrollListener() {
    final offset = scrollController.offset;
    if (offset > lastOffset && showHeader) {
      setState(() => showHeader = false);
    } else if (offset < lastOffset && !showHeader) {
      setState(() => showHeader = true);
    }
    lastOffset = offset;
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryFilterViewModel>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              expandedHeight: 108,
              collapsedHeight: 70,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: CollapsibleHeader(
                title: "متاجر الطعام",
                showHeader: showHeader,
                suggestions: const [
                  "مطاعم",
                  "بيتزا",
                  "كريب",
                  "مشويات",
                  "سوبرماركت",
                ],
              ),
            ),

            // 📢 إعلانات
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 4, bottom: 12),
                child: AutoScrollingAds(),
              ),
            ),

            // 🔥 أفضل المطاعم تصنيفًا
            SliverToBoxAdapter(
              child: BestRestaurantsSection(
                title: "أفضل المطاعم تصنيفًا",
                data: [
                  [
                    RestaurantCard(
                      name: "مخبوزات الشعراوي",
                      rating: "⭐ 4.7",
                      info: "25-40 دقيقة • 6.99 ج.م",
                    ),
                    RestaurantCard(
                      name: "زادنا بيكري",
                      rating: "⭐ 4.9",
                      info: "20-35 دقيقة • 6.99 ج.م",
                    ),
                    RestaurantCard(
                      name: "الحاتي المشويات الأصلية",
                      rating: "⭐ 4.5",
                      info: "35-55 دقيقة • 6.99 ج.م",
                    ),
                  ],
                ],
              ),
            ),

            // 🧭 اختيار التصنيفات الفرعية إن وجدت للفئة المحددة
            if (vm.subCategories.isNotEmpty)
              const SliverToBoxAdapter(child: CategorySelector()),

            // 📋 قائمة المتاجر بناءً على الفئة/التصنيف الفرعي
            SliverToBoxAdapter(child: CategoryItemsList()),
          ],
        ),
      ),
    );
  }
}
