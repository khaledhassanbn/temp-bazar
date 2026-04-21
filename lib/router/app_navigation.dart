import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// مفتاح [Navigator] الجذر — يُمرَّر لـ [GoRouter] لتمكين التنقّل من خدمات
/// الإشعارات ودورات حياة التطبيق الخلفية.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter? _appRouter;

/// تسجيل الـ [GoRouter] بعد إنشائه (يُستدعى مرة من [createRouter]).
void registerAppRouter(GoRouter router) {
  _appRouter = router;
}

/// الانتقال لشاشة طلبات التاجر (المسار الموجود مسبقاً).
void navigateToStoreOrders(String storeId, {String? orderId}) {
  final qp = <String, String>{
    'marketId': storeId,
    if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
  };
  _appRouter?.go(Uri(path: '/myorder', queryParameters: qp).toString());
}
