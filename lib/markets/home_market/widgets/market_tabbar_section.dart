import 'package:flutter/material.dart';

class MarketTabBarSection extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final double tabBarHeight;
  final Function(int) onTabSelected;
  final List<String> tabs;

  MarketTabBarSection({
    required this.tabController,
    required this.tabBarHeight,
    required this.onTabSelected,
    required this.tabs,
  });

  @override
  double get minExtent => tabBarHeight;
  @override
  double get maxExtent => tabBarHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: tabBarHeight,
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: tabController,
            isScrollable: true,
            indicatorColor: Colors.black,
            indicatorWeight: 3.5,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            onTap: onTabSelected,
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(MarketTabBarSection oldDelegate) =>
      oldDelegate.tabs != tabs || oldDelegate.tabBarHeight != tabBarHeight;
}
