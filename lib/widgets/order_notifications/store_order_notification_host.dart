import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/services/fcm_service.dart';
import 'package:bazar_suez/services/order_notifications/store_new_order_listener.dart';
import 'package:bazar_suez/services/order_notifications/store_office_return_listener.dart';

/// يربط الاستماع المباشر لطلبات `new` مع FCM بعد تحميل معرّف المتجر.
/// يوضع داخل شجرة واجهة التاجر فقط (مثلاً داخل [MarketLayout]).
class StoreOrderNotificationHost extends StatefulWidget {
  const StoreOrderNotificationHost({super.key});

  @override
  State<StoreOrderNotificationHost> createState() =>
      _StoreOrderNotificationHostState();
}

class _StoreOrderNotificationHostState extends State<StoreOrderNotificationHost> {
  late final AuthGuard _auth;
  StoreNewOrderListener? _listener;
  StoreOfficeReturnListener? _officeReturnListener;
  String? _attachedStoreId;
  String? _attachedUid;
  String? _lastLocation;
  bool _busy = false;

  bool _isEligibleLocation(String? location) {
    if (location == null || location.isEmpty) return false;
    // شغّل الاستماع فقط داخل صفحات التاجر التي تحتاج تنبيه فعلي للطلبات
    // لتجنب ثِقل فتح صفحات مثل MarketAnimatedPage.
    //
    // ملاحظة: بعد تحديثات مسارات التطبيق أصبحت صفحات التبويب الأساسية (مثل /HomePage)
    // هي المكان الافتراضي الذي يقضي فيه التاجر أغلب الوقت، لذا يجب أن تكون ضمن القائمة.
    if (location.startsWith('/HomePage')) return true;
    if (location.startsWith('/myorder')) return true;
    if (location.startsWith('/PastOrders')) return true;
    if (location.startsWith('/addproduct')) return true;
    if (location.startsWith('/MyStorePage')) return true;
    if (location.startsWith('/ManageProducts')) return true;
    if (location.startsWith('/SalesStatsPage')) return true;
    if (location.startsWith('/AccountPage')) return true;
    if (location.startsWith('/pricingpage')) return true;
    if (location.startsWith('/edit-store')) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthGuard>();
    _auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthChanged());
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _listener?.dispose();
    _officeReturnListener?.dispose();
    super.dispose();
  }

  Future<void> _onAuthChanged() async {
    if (_busy) return;

    final location = _lastLocation;
    if (!_isEligibleLocation(location)) {
      // لا نحتاج listener هنا، فنتأكد أنه متوقف
      await _listener?.dispose();
      await _officeReturnListener?.dispose();
      _listener = null;
      _officeReturnListener = null;
      _attachedStoreId = null;
      _attachedUid = null;
      return;
    }

    if (!_auth.isMarketOwner || _auth.currentUser == null) {
      await _listener?.dispose();
      await _officeReturnListener?.dispose();
      _listener = null;
      _officeReturnListener = null;
      _attachedStoreId = null;
      _attachedUid = null;
      return;
    }

    _busy = true;
    try {
      final uid = _auth.currentUser!.uid;
      if (_attachedUid == uid && _attachedStoreId != null && _listener != null) {
        return;
      }

      final mid = _auth.marketId;
      if (mid == null || mid.isEmpty) {
        await _listener?.dispose();
        await _officeReturnListener?.dispose();
        _listener = null;
        _officeReturnListener = null;
        _attachedStoreId = null;
        _attachedUid = uid;
        return;
      }

      if (_attachedStoreId == mid && _listener != null && _officeReturnListener != null) {
        return;
      }

      await _listener?.dispose();
      await _officeReturnListener?.dispose();
      _attachedStoreId = mid;
      _attachedUid = uid;

      // لا ننتظر الكتابة على الشبكة هنا حتى لا تؤخر فتح الصفحة
      // ومحدودة بـ throttle داخل FcmService.
      // ignore: unawaited_futures
      FcmService.instance.saveTokenForStore(mid);

      _listener = StoreNewOrderListener(mid)..start();
      _officeReturnListener = StoreOfficeReturnListener(mid)..start();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (_lastLocation != location) {
      _lastLocation = location;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthChanged());
    }
    return const SizedBox.shrink();
  }
}
