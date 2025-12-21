import 'package:flutter/material.dart';

class MarketAppBar extends StatelessWidget {
  final double scrollOffset;
  final bool isMerged;
  final TabController tabController;
  final double tabBarHeight;
  final Function(int) onTabSelected;
  final List<String> tabs;
  final String? storeName;

  const MarketAppBar({
    super.key,
    required this.scrollOffset,
    required this.isMerged,
    required this.tabController,
    required this.tabBarHeight,
    required this.onTabSelected,
    required this.tabs,
    this.storeName,
  });

  double _calculateAppBarOpacity(double offset) =>
      (offset / 100).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    final double opacity = _calculateAppBarOpacity(scrollOffset);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height:
            kToolbarHeight +
            MediaQuery.of(context).padding.top +
            (isMerged ? tabBarHeight : 0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(opacity),
          boxShadow: isMerged
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.black,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Opacity(
                    opacity: opacity,
                    child: Text(
                      storeName ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isMerged && tabs.isNotEmpty)
              Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  height: tabBarHeight,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.transparent, width: 0),
                      ),
                    ),
                    child: TabBar(
                      controller: tabController,
                      isScrollable: true,
                      indicatorColor: Colors.black,
                      indicatorWeight: 3.5,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      overlayColor: MaterialStateProperty.all(
                        Colors.transparent,
                      ),
                      onTap: onTabSelected,
                      tabs: tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
