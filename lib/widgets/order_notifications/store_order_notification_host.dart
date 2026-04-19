import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/services/fcm_service.dart';
import 'package:bazar_suez/services/order_notifications/store_new_order_listener.dart';

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
  String? _attachedStoreId;
  bool _busy = false;

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
    super.dispose();
  }

  Future<void> _onAuthChanged() async {
    if (_busy) return;

    if (!_auth.isMarketOwner || _auth.currentUser == null) {
      await _listener?.dispose();
      _listener = null;
      _attachedStoreId = null;
      return;
    }

    _busy = true;
    try {
      final uid = _auth.currentUser!.uid;
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snap.data();
      final dynamic mid = data?['market_id'] ?? data?['marketId'];
      if (mid is! String || mid.isEmpty) {
        await _listener?.dispose();
        _listener = null;
        _attachedStoreId = null;
        return;
      }

      if (_attachedStoreId == mid && _listener != null) return;

      await _listener?.dispose();
      _attachedStoreId = mid;

      await FcmService.instance.saveTokenForStore(mid);

      _listener = StoreNewOrderListener(mid)..start();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
