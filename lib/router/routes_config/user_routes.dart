import 'package:bazar_suez/markets/Markets_after_category/pages/home_market.dart';
import 'package:go_router/go_router.dart';


final userRoutes = [
  GoRoute(
    path: '/FoodHomePage',
    builder: (context, state) {
      final categoryId = state.uri.queryParameters['categoryId'];
      return FoodHomePage(categoryId: categoryId);
    },
  ),
];
