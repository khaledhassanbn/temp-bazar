import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/OrderService.dart';
import '../utils/order_status_helper.dart';
import 'package:bazar_suez/markets/create_market/services/store_service.dart';
import 'package:bazar_suez/services/delivery_fee/delivery_fee_service.dart';

class PastOrdersViewModel extends ChangeNotifier {
  final String marketId;
  final OrderService _service;
  final StoreService _storeService = StoreService();

  GeoPoint? marketLocation;
  final Map<String, Map<String, String>> distancesAndDurations = {};

  PastOrdersViewModel({
    required this.marketId,
    OrderService? service,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) : _service = service ?? OrderService(),
       _filterStartDate = filterStartDate,
       _filterEndDate = filterEndDate;

  // ======== Filter State ========
  final DateTime? _filterStartDate;
  final DateTime? _filterEndDate;

  // ======== UI State ========
  final ScrollController scrollController = ScrollController();
  bool showHeader = true;
  double lastOffset = 0;
  String searchQuery = '';
  DateTime? selectedDate;

  // ======== Data State ========
  Stream<QuerySnapshot>? _ordersStream;
  Stream<QuerySnapshot>? get ordersStream => _ordersStream;

  bool isLoading = true;
  String? error;
  Timer? _timer;

  // ======== Init ========
  void init() {
    scrollController.addListener(_onScroll);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
    _setupOrdersStream();
    _fetchMarketLocation();
    _syncCompletedOrders();
  }

  Future<void> _syncCompletedOrders() async {
    try {
      await _service.syncCompletedOrdersForMarket(marketId);
    } catch (_) {}
  }

  void _onScroll() {
    final offset = scrollController.offset;
    if (offset > lastOffset && showHeader) {
      showHeader = false;
      notifyListeners();
    } else if (offset < lastOffset && !showHeader) {
      showHeader = true;
      notifyListeners();
    }
    lastOffset = offset;
  }

  void setSearchQuery(String value) {
    searchQuery = value.trim();
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    selectedDate = date;
    notifyListeners();
  }

  // ======== Stream setup ========
  void _setupOrdersStream() {
    try {
      _ordersStream = _service.streamPastOrders(
        marketId,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );
      isLoading = false;
      error = null;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      error = 'خطأ في تحميل الطلبات: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> _fetchMarketLocation() async {
    try {
      final doc = await _storeService.getStore(marketId);
      final data = doc.data();
      if (data != null && data['location'] is GeoPoint) {
        marketLocation = data['location'] as GeoPoint;
        notifyListeners();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> fetchDistanceAndDurationBicycle(
    String orderId,
    GeoPoint? clientLoc,
  ) async {
    if (marketLocation == null || clientLoc == null) return;
    if (distancesAndDurations.containsKey(orderId)) return; // موجودة مسبقاً

    try {
      // حساب المسافة باستخدام Haversine Formula (مسافة خطية)
      final distanceKm = DeliveryFeeService.calculateDistanceFromGeoPoints(
        marketLocation!,
        clientLoc,
      );

      // حساب وقت التوصيل التقديري (بالدقائق)
      final durationMinutes = DeliveryFeeService.calculateDeliveryTime(distanceKm);

      // تنسيق البيانات لعرضها
      final distanceText = '${distanceKm.toStringAsFixed(1)} كم';
      final durationText = '$durationMinutes دقيقة';

      distancesAndDurations[orderId] = {
        'distance': distanceText,
        'duration': durationText,
      };
      notifyListeners();
    } catch (_) {}
  }

  // ======== Order conversion ========
  Map<String, dynamic> convertOrder(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final customerInfo = data['customerInfo'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];

      final deliveryInfo = data['deliveryRequest'] as Map<String, dynamic>?;
      final independentDispatch =
          data['dispatchType'] == 'independent_courier' ? data : null;

      String status;
      if (deliveryInfo != null && deliveryInfo['status'] != null) {
        status = _convertDeliveryStatusToArabic(
          deliveryInfo['status'].toString(),
        );
      } else if (independentDispatch != null &&
          independentDispatch['status'] != null) {
        status = _convertIndependentStatusToArabic(
          independentDispatch['status'].toString(),
        );
      } else {
        final rawStatus = _resolveRawOrderStatus(data);
        status = _convertStatusToArabic(rawStatus);
      }

      if (OrderStatusHelper.isDelivered(data)) {
        status = 'تم التسليم';
      }

      DateTime orderTime;
      Timestamp? createdAtTimestamp;
      if (data['createdAt'] != null) {
        createdAtTimestamp = data['createdAt'] as Timestamp;
        orderTime = createdAtTimestamp.toDate();
      } else {
        orderTime = DateTime.now();
        createdAtTimestamp = Timestamp.fromDate(orderTime);
      }

      // ========== ✅ تعديل هنا ==========
      List<Map<String, dynamic>> requiredOptions = [];

      for (var item in items) {
        try {
          final itemData = item as Map<String, dynamic>? ?? {};
          final productName = itemData['productName'] ?? 'منتج';
          final quantity = itemData['quantity'] ?? 1;

          // تفاصيل المنتج (quantity + options)
          List<Map<String, dynamic>> details = [
            {'label': 'الكمية', 'value': quantity.toString()},
          ];

          final selectedOptionsMap =
              itemData['selectedOptions'] as Map<String, dynamic>? ?? {};

          selectedOptionsMap.forEach((optionTitle, optionValue) {
            if (optionValue != null && optionValue.toString().isNotEmpty) {
              details.add({
                'label': optionTitle,
                'value': optionValue.toString(),
              });
            }
          });

          requiredOptions.add({'title': productName, 'details': details});
        } catch (_) {
          continue;
        }
      }

      // ==================================

      // استخراج احداثيات العميل إن وجدت
      dynamic customerLocRaw = customerInfo['location'];
      GeoPoint? clientLoc;
      if (customerLocRaw is GeoPoint) {
        clientLoc = customerLocRaw;
      } else if (customerLocRaw is Map) {
        if (customerLocRaw.containsKey('lat') &&
            customerLocRaw.containsKey('lng')) {
          final lat = customerLocRaw['lat'];
          final lng = customerLocRaw['lng'];
          if (lat is num && lng is num) {
            clientLoc = GeoPoint(lat.toDouble(), lng.toDouble());
          }
        }
      }

      return {
        'id': data['orderId'] ?? doc.id,
        'customerName': customerInfo['name'] ?? 'عميل',
        'customerPhone': customerInfo['phone'] ?? '',
        'customerAddress': customerInfo['address'] ?? '',
        'customerLocation': clientLoc, // جديد
        'status': status,
        'orderTime': orderTime,
        'createdAt': createdAtTimestamp, // إضافة createdAt للفرز والفلترة
        'totalPrice': (data['totalAmount'] ?? 0.0).toDouble(),
        'requiredOptions': requiredOptions,
        'extraOptions': [],
        'documentId': doc.id,
      };
    } catch (e) {
      final now = DateTime.now();
      return {
        'id': doc.id,
        'customerName': 'عميل',
        'customerPhone': '',
        'customerAddress': '',
        'status': 'قيد المراجعة',
        'orderTime': now,
        'createdAt': Timestamp.fromDate(now),
        'totalPrice': 0.0,
        'requiredOptions': [],
        'extraOptions': [],
        'documentId': doc.id,
      };
    }
  }

  // ======== Date filtering ========
  bool isOrderOnSelectedDate(Map<String, dynamic> order) {
    if (selectedDate == null && _filterStartDate == null) return true;

    DateTime orderDate;
    if (order['createdAt'] != null) {
      final timestamp = order['createdAt'] as Timestamp;
      orderDate = timestamp.toDate();
    } else {
      orderDate = order['orderTime'] as DateTime;
    }

    if (selectedDate != null) {
      return orderDate.year == selectedDate!.year &&
          orderDate.month == selectedDate!.month &&
          orderDate.day == selectedDate!.day;
    }

    return isOrderInFilterRange(orderDate);
  }

  bool isOrderInFilterRange(DateTime orderDate) {
    if (_filterStartDate == null && _filterEndDate == null) return true;
    if (_filterStartDate != null && orderDate.isBefore(_filterStartDate!)) {
      return false;
    }
    if (_filterEndDate != null && !orderDate.isBefore(_filterEndDate!)) {
      return false;
    }
    return true;
  }

  String _resolveRawOrderStatus(Map<String, dynamic> data) {
    final rawStatus = (data['status'] as String?)?.trim();
    final rawOrderStatus = (data['orderStatus'] as String?)?.trim();

    const notificationOnly = {'new', 'accepted', 'rejected'};
    if (rawStatus != null &&
        notificationOnly.contains(rawStatus.toLowerCase()) &&
        rawOrderStatus != null &&
        rawOrderStatus.isNotEmpty) {
      return rawOrderStatus;
    }
    if (rawStatus != null && rawStatus.isNotEmpty) {
      return rawStatus;
    }
    if (rawOrderStatus != null && rawOrderStatus.isNotEmpty) {
      return rawOrderStatus;
    }
    return 'pending';
  }

  // ======== Status Translation ========
  String _convertDeliveryStatusToArabic(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'في انتظار قبول المكتب';
      case 'accepted':
        return 'تم قبوله من المكتب';
      case 'assigned':
        return 'تم تعيين مندوب';
      case 'driver_accepted':
        return 'المندوب قبل الطلب';
      case 'picked_up':
        return 'تم استلام الطلب من المتجر';
      case 'completed':
        return 'تم التسليم';
      case 'driver_rejected':
        return 'المندوب رفض الطلب';
      case 'customer_rejected':
        return 'الزبون رفض الاستلام';
      case 'rejected':
        return 'تم رفض الطلب من المكتب';
      default:
        return status;
    }
  }

  String _convertIndependentStatusToArabic(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'تم التسليم';
      case 'picked_up':
        return 'تم استلام الطلب من المتجر';
      case 'driver_accepted':
      case 'accepted':
        return 'المندوب قبل الطلب';
      default:
        return status;
    }
  }

  String _convertStatusToArabic(String status) {
    if (status == 'قيد المراجعة' ||
        status == 'تم استلام الطلب' ||
        status == 'جارى تسليم للدليفري' ||
        status == 'تم التسليم للطيار' ||
        status == 'تم رفض الطلب') {
      return status;
    }
    switch (status.toLowerCase()) {
      case 'new':
      case 'pending':
        return 'قيد المراجعة';
      case 'accepted':
        return 'تم استلام الطلب';
      case 'preparing':
      case 'delivering':
        return 'جارى تسليم للدليفري';
      case 'delivered':
      case 'completed':
        return 'تم التسليم';
      case 'rejected':
        return 'تم رفض الطلب';
      default:
        return status;
    }
  }

  // ======== Dispose ========
  void disposeViewModel() {
    _timer?.cancel();
    scrollController.dispose();
  }
}
