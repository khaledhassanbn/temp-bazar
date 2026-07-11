import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bazar_suez/shared/widgets/report_dialog.dart';

class MarketAppBar extends StatelessWidget {
  final double scrollOffset;
  final bool isMerged;
  final TabController tabController;
  final double tabBarHeight;
  final Function(int) onTabSelected;
  final List<String> tabs;
  final String? storeName;
  final String? storeId; // معرف المتجر
  final bool isOwner; // هل المستخدم صاحب المتجر
  final VoidCallback? onSearchPressed;

  const MarketAppBar({
    super.key,
    required this.scrollOffset,
    required this.isMerged,
    required this.tabController,
    required this.tabBarHeight,
    required this.onTabSelected,
    required this.tabs,
    this.storeName,
    this.storeId,
    this.isOwner = false,
    this.onSearchPressed,
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
      child: RepaintBoundary(
        child: Container(
          height:
              kToolbarHeight +
              MediaQuery.of(context).padding.top +
              (isMerged && tabs.isNotEmpty ? tabBarHeight : 0),
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
                      onPressed: () {
                        context.go('/HomePage');
                      },
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
                          onPressed: onSearchPressed,
                        ),
                        // زر الإبلاغ (لغير صاحب المتجر فقط)
                        if (storeId != null && !isOwner)
                          IconButton(
                            icon: const Icon(Icons.report_outlined),
                            color: Colors.red[700],
                            onPressed: () {
                              showReportDialog(
                                context,
                                targetId: storeId!,
                                targetType: 'store',
                                targetName: storeName ?? 'المتجر',
                              );
                            },
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
                          bottom: BorderSide(
                            color: Colors.transparent,
                            width: 0,
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        indicatorColor: Colors.black,
                        indicatorWeight: 3.5,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
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
      ),
    );
  }
}
