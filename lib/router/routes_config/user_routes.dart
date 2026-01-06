import 'package:bazar_suez/markets/Markets_after_category/pages/category_market_page.dart';
import 'package:go_router/go_router.dart';


final userRoutes = [
  GoRoute(
    path: '/CategoryMarketPage',
    builder: (context, state) {
      final categoryId = state.uri.queryParameters['categoryId'];
      return CategoryMarketPage(categoryId: categoryId);
    },
  ),
];
