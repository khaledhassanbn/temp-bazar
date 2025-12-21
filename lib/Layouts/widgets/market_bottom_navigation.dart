import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/bottom_bar_view_model.dart';
import 'custom_bottom_app_bar.dart';

class MarketBottomNavigation extends StatelessWidget {
  final int currentIndex;
  const MarketBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final vm = BottomBarViewModel();
    return FutureBuilder<String?>(
      future: vm.resolveMarketId(),
      builder: (context, marketSnap) {
        final marketId = marketSnap.data;
        if (marketId == null || marketId.isEmpty) {
          return CustomBottomAppBar(
            currentIndex: currentIndex,
            ordersCount: 0,
            onTap: (index) => _handleTap(context, index),
          );
        }
        return StreamBuilder<int>(
          stream: vm.streamOrdersCount(marketId),
          builder: (context, countSnap) {
            final count = countSnap.data ?? 0;
            return CustomBottomAppBar(
              currentIndex: currentIndex,
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
        context.go('/MyStorePage');
        break;
      case 4:
        context.go('/AccountPage');
        break;
    }
  }
}
