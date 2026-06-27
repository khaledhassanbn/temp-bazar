import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../create_market/services/store_service.dart';
import '../../services/OrderService.dart';
import '../models/independent_courier.dart';
import '../services/independent_couriers_service.dart';
import '../services/independent_courier_dispatch_service.dart';

class IndependentCourierPickerViewModel extends ChangeNotifier {
  final String marketId;
  final String presentOrderDocumentId;
  final Set<String> excludedCourierUids;

  final StoreService _storeService = StoreService();
  final OrderService _orderService = OrderService();
  final IndependentCouriersService _couriersService = IndependentCouriersService();
  final IndependentCourierDispatchService _dispatchService =
      IndependentCourierDispatchService();

  StreamSubscription<List<IndependentCourier>>? _couriersSub;

  bool isLoading = true;
  String? errorMessage;

  GeoPoint? storeLocation;
  Map<String, dynamic>? storeData;
  Map<String, dynamic>? presentOrderData;

  List<IndependentCourier> couriers = [];
  final Set<String> selectedCourierUids = {};

  Stream<DocumentSnapshot<Map<String, dynamic>>>? dispatchOrderStream;

  IndependentCourierPickerViewModel({
    required this.marketId,
    required this.presentOrderDocumentId,
    Set<String>? excludedCourierUids,
  }) : excludedCourierUids = excludedCourierUids ?? <String>{};

  Future<void> init() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _storeService.getStore(marketId),
        _orderService.getPresentOrder(marketId, presentOrderDocumentId),
      ]);

      final storeDoc = results[0];
      final presentOrderDoc = results[1];

      storeData = storeDoc.data() ?? <String, dynamic>{};
      if (storeData?['location'] is GeoPoint) {
        storeLocation = storeData?['location'] as GeoPoint;
      }

      presentOrderData = presentOrderDoc.data() ?? <String, dynamic>{};
      dispatchOrderStream =
          _dispatchService.streamDispatchOrder(presentOrderDocumentId);

      _couriersSub?.cancel();
      _couriersSub = _couriersService
          .streamApprovedCouriersWithLiveStatus(storeLocation: storeLocation)
          .listen((list) {
        couriers = list
            .where((c) => c.canReceiveOrders)
            .toList(growable: false);
        isLoading = false;
        notifyListeners();
      }, onError: (e) {
        isLoading = false;
        errorMessage = e.toString();
        notifyListeners();
      });
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void toggleSelected(String uid) {
    if (excludedCourierUids.contains(uid)) return;
    if (selectedCourierUids.contains(uid)) {
      selectedCourierUids.remove(uid);
      notifyListeners();
      return;
    }
    if (selectedCourierUids.length >= 3) return;
    selectedCourierUids.add(uid);
    notifyListeners();
  }

  bool isSelected(String uid) => selectedCourierUids.contains(uid);

  Future<String?> sendOrResend() async {
    if (selectedCourierUids.isEmpty) {
      return 'اختر مندوب واحد على الأقل';
    }
    if (storeData == null || presentOrderData == null) {
      return 'بيانات الطلب غير مكتملة';
    }
    try {
      await _dispatchService.createOrResendIndependentCourierOrder(
        orderId: presentOrderDocumentId,
        storeId: marketId,
        storeData: storeData!,
        presentOrderData: presentOrderData!,
        courierUids: selectedCourierUids.toList(),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _couriersSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}

