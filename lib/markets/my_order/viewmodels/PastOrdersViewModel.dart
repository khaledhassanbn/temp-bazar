import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/OrderService.dart';
import 'package:bazar_suez/markets/create_market/services/store_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    final String apiKey =
        'AIzaSyA9bJxVt4G17WqaUeIHmpaHfmcOhsJddYA'; // ضع هنا مفتاحك بأمان

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json?key=$apiKey'
      '&origins=${marketLocation!.latitude},${marketLocation!.longitude}'
      '&destinations=${clientLoc.latitude},${clientLoc.longitude}'
      '&mode=driving&language=ar',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rows = data['rows'] as List?;
        if (rows != null && rows.isNotEmpty) {
          final elements = rows[0]['elements'] as List?;
          if (elements != null && elements.isNotEmpty) {
            final el = elements[0];
            if (el['status'] == 'OK') {
              String distanceText = el['distance']['text'] ?? '';
              String durationText = el['duration']['text'] ?? '';
              distancesAndDurations[orderId] = {
                'distance': distanceText,
                'duration': durationText,
              };
              notifyListeners();
            }
          }
        }
      }
    } catch (_) {}
  }

  // ======== Order conversion ========
  Map<String, dynamic> convertOrder(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final customerInfo = data['customerInfo'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];

      String status = _convertStatusToArabic(data['status'] ?? 'قيد المراجعة');

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
    if (selectedDate == null) return true;

    // استخدام createdAt للفلترة
    DateTime orderDate;
    if (order['createdAt'] != null) {
      final timestamp = order['createdAt'] as Timestamp;
      orderDate = timestamp.toDate();
    } else {
      orderDate = order['orderTime'] as DateTime;
    }

    return orderDate.year == selectedDate!.year &&
        orderDate.month == selectedDate!.month &&
        orderDate.day == selectedDate!.day;
  }

  // ======== Status Translation ========
  String _convertStatusToArabic(String status) {
    if (status == 'قيد المراجعة' ||
        status == 'تم استلام الطلب' ||
        status == 'جارى تسليم للدليفري' ||
        status == 'تم التسليم للطيار' ||
        status == 'تم رفض الطلب') {
      return status;
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد المراجعة';
      case 'accepted':
        return 'تم استلام الطلب';
      case 'preparing':
        return 'جارى تسليم للدليفري';
      case 'delivered':
        return 'تم التسليم للطيار';
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
