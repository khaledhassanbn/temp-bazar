import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/bottom_bar_view_model.dart';
import 'custom_bottom_app_bar.dart';

class MarketBottomNavigation extends StatefulWidget {
  final int currentIndex;
  const MarketBottomNavigation({super.key, required this.currentIndex});

  @override
  State<MarketBottomNavigation> createState() => _MarketBottomNavigationState();
}

class _MarketBottomNavigationState extends State<MarketBottomNavigation> {
  late final BottomBarViewModel _vm;
  late final Future<String?> _marketIdFuture;

  @override
  void initState() {
    super.initState();
    _vm = BottomBarViewModel();
    _marketIdFuture = _vm.resolveMarketId();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _marketIdFuture,
      builder: (context, marketSnap) {
        final marketId = marketSnap.data;
        if (marketId == null || marketId.isEmpty) {
          return CustomBottomAppBar(
            currentIndex: widget.currentIndex,
            ordersCount: 0,
            onTap: (index) => _handleTap(context, index),
          );
        }
        return StreamBuilder<int>(
          stream: _vm.streamOrdersCount(marketId),
          builder: (context, countSnap) {
            final count = countSnap.data ?? 0;
            return CustomBottomAppBar(
              currentIndex: widget.currentIndex,
              ordersCount: count,
              onTap: (index) => _handleTap(context, index, marketId: marketId),
            );
          },
        );
      },
    );
  }

  void _handleTap(BuildContext context, int index, {String? marketId}) async {
    switch (index) {
      case 0:
        context.go('/HomePage');
        break;
      case 1:
        if (marketId == null || marketId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يوجد متجر مرتبط بالحساب')),
          );
          return;
        }
        context.go('/myorder?marketId=$marketId');
        break;
      case 2:
        context.go('/addproduct');
        break;
      case 3:
        // تمرير marketId يتخطى قراءة users/{uid} في resolveMarketRoute ويقلل التأخير
        // (مقارنة بفتح المتجر من الرئيسية برابط يحتوي المعرف مباشرة).
        if (marketId != null && marketId.isNotEmpty) {
          context.go('/MyStorePage?marketId=$marketId');
        } else {
          context.go('/MyStorePage');
        }
        break;
      case 4:
        context.go('/AccountPage');
        break;
    }
  }
}
