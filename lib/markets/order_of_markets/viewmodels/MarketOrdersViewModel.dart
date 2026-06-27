import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../services/OrderService.dart';
import '../services/delivery_request_service.dart';
import 'package:bazar_suez/markets/create_market/services/store_service.dart';
import 'package:bazar_suez/services/delivery_fee/delivery_fee_service.dart';

bool _isReturnedToMerchantRaw(String? status) {
  if (status == null || status.isEmpty) return false;
  return status.trim().toLowerCase() == 'returned_to_merchant';
}

class MarketOrdersViewModel extends ChangeNotifier {
  final String marketId;
  final OrderService _service;
  final StoreService _storeService = StoreService();
  final DeliveryRequestService _deliveryRequestService =
      DeliveryRequestService();

  GeoPoint? marketLocation;
  final Map<String, Map<String, String>> distancesAndDurations = {};

  Future<List<Map<String, dynamic>>> fetchActiveOffices() async {
    return _deliveryRequestService.fetchActiveOffices();
  }

  MarketOrdersViewModel({required this.marketId, OrderService? service})
    : _service = service ?? OrderService();

  // ======== UI State ========
  final ScrollController scrollController = ScrollController();
  bool showHeader = true;
  double lastOffset = 0;
  String searchQuery = '';

  // ======== Data State ========
  Stream<QuerySnapshot>? _ordersStream;
  Stream<QuerySnapshot>? get ordersStream => _ordersStream;

  bool isLoading = true;
  String? error;
  Timer? _timer;
  StreamSubscription? _rejectedRequestsSubscription;
  StreamSubscription? _deliveryRequestsSubscription;
  StreamSubscription? _independentDispatchOrdersSubscription;
  StreamSubscription? _couriersDirectorySubscription;
  
  // تخزين رسائل الرفض لعرضها للتاجر
  final Map<String, String> rejectedMessages = {};

  // دليل المناديب المستقلين (uid -> profile data) لعرض الاسم/الصورة بدل id
  final Map<String, Map<String, dynamic>> independentCouriersByUid = {};
  final Map<String, double> _customerReliabilityByUid = {};
  final Set<String> _loadingReliabilityUids = {};

  // ======== Init ========
  void init() {
    scrollController.addListener(_onScroll);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
    _setupOrdersStream();
    _fetchMarketLocation();
    _listenToRejectedRequests();
    _listenToDeliveryCompletions();
    _syncCompletedOrders();
    _listenToIndependentCouriersDirectory();
  }

  Future<void> _syncCompletedOrders() async {
    try {
      await _service.syncCompletedOrdersForMarket(marketId);
    } catch (e) {
      print('⚠️ خطأ في مزامنة الطلبات المكتملة: $e');
    }
  }

  void _listenToDeliveryCompletions() {
    _deliveryRequestsSubscription = _deliveryRequestService
        .streamRequestsForMarket(marketId)
        .listen((requests) async {
      for (final request in requests) {
        final status = (request['status'] ?? '').toString().toLowerCase();
        if (status != 'completed') continue;

        final orderDocumentId =
            request['orderDocumentId'] as String? ??
            request['id'] as String?;
        if (orderDocumentId == null || orderDocumentId.isEmpty) continue;

        try {
          await _service.finalizeDeliveredOrder(marketId, orderDocumentId);
          notifyListeners();
        } catch (e) {
          print('❌ خطأ في إنهاء الطلب $orderDocumentId: $e');
        }
      }
    });
  }

  // ======== Listen to rejected delivery requests ========
  void _listenToRejectedRequests() {
    _rejectedRequestsSubscription = _deliveryRequestService
        .streamRejectedRequests(marketId)
        .listen((rejectedRequests) async {
      for (final request in rejectedRequests) {
        final orderDocumentId = request['orderDocumentId'] as String?;
        final officeName = request['officeName'] as String? ?? 'مكتب غير معروف';
        final requestId = request['id'] as String?;

        if (orderDocumentId != null && requestId != null) {
          // تخزين رسالة الرفض
          rejectedMessages[orderDocumentId] = 'تم رفض الطلب من مكتب "$officeName"';
          
          try {
            // إرجاع حالة الطلب إلى "تم استلام الطلب"
            await _service.updatePresentOrderStatus(
              marketId,
              orderDocumentId,
              'تم استلام الطلب',
            );

            // حذف طلب التوصيل المرفوض
            await _deliveryRequestService.deleteRequest(requestId);
            
            notifyListeners();
          } catch (e) {
            print('❌ خطأ في معالجة الرفض: $e');
          }
        }
      }
    });
  }


  void _listenToIndependentCouriersDirectory() {
    _couriersDirectorySubscription = FirebaseFirestore.instance
        .collection('courier_requests')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snapshot) {
      independentCouriersByUid.clear();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final uid = (data['courierUid'] ?? data['uid'] ?? data['userId'] ?? doc.id)
            .toString();

        final name = (data['name'] ??
                data['fullName'] ??
                data['full_name'] ??
                data['userName'] ??
                data['user_name'] ??
                data['displayName'] ??
                data['display_name'] ??
                'مندوب')
            .toString();

        final phone = (data['phone'] ??
                data['phoneNumber'] ??
                data['phone_number'] ??
                '')
            .toString();

        final vehicleType =
            (data['vehicleType'] ?? data['vehicle_type'] ?? data['vehicle'] ?? '')
                .toString();

        final photoUrl = (data['profileImage'] ??
                data['personalPhoto'] ??
                data['personal_photo'] ??
                data['photoUrl'] ??
                data['photo_url'] ??
                data['personalImage'] ??
                data['personal_image'] ??
                data['image'] ??
                data['photo'] ??
                data['avatar'] ??
                data['avatarUrl'] ??
                data['avatar_url'] ??
                '')
            .toString();

        double? rating;
        final ratingRaw = data['rating'] ?? data['rate'];
        if (ratingRaw is num) rating = ratingRaw.toDouble();
        if (rating == null && ratingRaw != null) {
          rating = double.tryParse(ratingRaw.toString());
        }

        independentCouriersByUid[uid] = {
          'uid': uid,
          'name': name,
          'phone': phone,
          'vehicleType': vehicleType,
          'photoUrl': photoUrl,
          'rating': rating,
        };
      }
      notifyListeners();
    }, onError: (Object error) {
      print('⚠️ تعذّر تحميل دليل المناديب: $error');
    });
  }

  // دالة للحصول على رسالة الرفض وحذفها بعد العرض
  String? getRejectedMessage(String orderId) {
    final message = rejectedMessages[orderId];
    if (message != null) {
      // حذف الرسالة بعد الحصول عليها (لعرضها مرة واحدة فقط)
      Future.delayed(const Duration(seconds: 5), () {
        rejectedMessages.remove(orderId);
        notifyListeners();
      });
    }
    return message;
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

  // ======== Stream setup ========
  void _setupOrdersStream() {
    try {
      _ordersStream = _service.streamPresentOrders(marketId);
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

  /// يفصل حقل الإشعارات (`status: new`) عن الحالة التشغيلية (`orderStatus`).
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

  // ======== Order conversion ========
  Map<String, dynamic> convertOrder(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final customerInfo = data['customerInfo'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];

      // جلب بيانات طلب التوصيل والمناديب المستقلين من نفس المستند الموحد
      final deliveryInfo = data['deliveryRequest'] as Map<String, dynamic>?;
      final independentDispatchInfo = data['dispatchType'] == 'independent_courier' ? data : null;

      // أولوية عرض الحالة:
      // 1) لو فيه طلب توصيل (مكتب) → نستخدم حالة تطبيق المكاتب (request delivery)
      // 2) لو فيه مندوب مستقل → نستخدم حالة الـ dispatch المستقل
      // 3) لو مفيش أي منهم → نستخدم حالة الطلب الأصلية
      final String status;
      final String? rawStatusFromDelivery =
          deliveryInfo != null ? deliveryInfo['status'] as String? : null;
      final String? rawStatusFromIndependent =
          independentDispatchInfo != null
              ? (independentDispatchInfo['status'] as String?)
              : null;
      final String rawStatusFromOrder = _resolveRawOrderStatus(data);

      if (rawStatusFromDelivery != null) {
        status = _convertDeliveryStatusToArabic(rawStatusFromDelivery);
      } else if (rawStatusFromIndependent != null) {
        status = _convertIndependentStatusToArabic(rawStatusFromIndependent);
      } else {
        status = _convertLegacyStatusToArabic(rawStatusFromOrder);
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
          final itemPrice = _extractItemPrice(itemData);

          // تفاصيل المنتج (quantity + options)
          List<Map<String, dynamic>> details = [
            {'label': 'الكمية', 'value': quantity.toString()},
            {
              'label': 'سعر المنتج',
              'value': '${itemPrice.toStringAsFixed(1)} جنيه',
            },
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
      final customerId =
          (customerInfo['userId'] ?? data['userId'] ?? '').toString();
      _prefetchCustomerReliability(customerId);
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
        'customerId': customerId,
        'customerReliability': customerId.isEmpty
            ? null
            : _customerReliabilityByUid[customerId],
        'customerLocation': clientLoc, // جديد
        'status': status,
        // بيانات المندوب من وثيقة request delivery (إن وُجدت)
        'assignedDriverName': deliveryInfo != null 
            ? (deliveryInfo['assignedDriverName'] ?? deliveryInfo['driverName'] ?? deliveryInfo['driver_name'] ?? '') 
            : '',
        'assignedDriverPhone': deliveryInfo != null
            ? (deliveryInfo['assignedDriverPhone'] ?? deliveryInfo['driverPhone'] ?? deliveryInfo['driver_phone'] ?? '')
            : '',
        'orderTime': orderTime,
        'createdAt': createdAtTimestamp, // إضافة createdAt لعرض التاريخ
        'totalPrice': (data['totalAmount'] ?? 0.0).toDouble(),
        'requiredOptions': requiredOptions,
        'extraOptions': [],
        'documentId': doc.id,
        // بيانات نظام المناديب المستقلين (إن وجد)
        'independentDispatch': independentDispatchInfo,
        // دليل المناديب لعرض الأسماء بدلاً من uid
        'independentCouriersDirectory': independentCouriersByUid,
        // ✅ إضافة البيانات المفقودة
        'items': items, // المنتجات بالصيغة الجديدة
        'notes': data['notes'] ?? '', // الملحوظات العامة
        'subtotal': (data['subtotal'] ?? 0.0).toDouble(),
        'deliveryFee': (data['deliveryFee'] ?? 0.0).toDouble(),
        'serviceFee': (data['serviceFee'] ?? 0.0).toDouble(),
        'totalAmount': (data['totalAmount'] ?? 0.0).toDouble(),
        'deliveryRating': data['deliveryRating'],
        // بيانات الإلغاء (إن وُجدت)
        'cancelReason': data['cancelReason'] ?? independentDispatchInfo?['cancelReason'] ?? '',
        'cancelledAt': data['cancelledAt'] ?? independentDispatchInfo?['cancelledAt'],
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
        'independentDispatch': doc.data() is Map && (doc.data() as Map)['dispatchType'] == 'independent_courier' ? doc.data() : null,
        'independentCouriersDirectory': independentCouriersByUid,
        // ✅ إضافة البيانات المفقودة
        'items': [],
        'notes': '',
        'subtotal': 0.0,
        'deliveryFee': 0.0,
        'serviceFee': 0.0,
        'totalAmount': 0.0,
      };
    }
  }

  Future<void> _prefetchCustomerReliability(String customerId) async {
    if (customerId.isEmpty) return;
    if (_customerReliabilityByUid.containsKey(customerId)) return;
    if (_loadingReliabilityUids.contains(customerId)) return;
    _loadingReliabilityUids.add(customerId);
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(customerId).get();
      final data = userDoc.data();
      if (data != null) {
        final raw = data['customerReliability'];
        if (raw is num) {
          _customerReliabilityByUid[customerId] = raw.toDouble();
          notifyListeners();
        } else if (raw != null) {
          final parsed = double.tryParse(raw.toString());
          if (parsed != null) {
            _customerReliabilityByUid[customerId] = parsed;
            notifyListeners();
          }
        }
      }
    } catch (_) {
      // ignore
    } finally {
      _loadingReliabilityUids.remove(customerId);
    }
  }

  double _extractItemPrice(Map<String, dynamic> itemData) {
    const candidateFields = [
      'totalPrice',
      'total',
      'finalPrice',
      'price',
      'unitPrice',
      'productPrice',
      'subtotal',
    ];
    for (final field in candidateFields) {
      final value = itemData[field];
      if (value is num) return value.toDouble();
      if (value != null) {
        final parsed = double.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return 0.0;
  }

  // ======== Status Translation (Legacy store statuses) ========
  // تستخدم قبل إرسال الطلب لمكتب الشحن (تطبيق التاجر القديم)
  String _convertLegacyStatusToArabic(String status) {
    // لو القيمة أصلاً عربية ومعروفة نرجعها كما هى
    if (status == 'قيد المراجعة' ||
        status == 'تم استلام الطلب' ||
        status == 'جارى تسليم للدليفري' ||
        status == 'تم التسليم للطيار' ||
        status == 'تم رفض الطلب' ||
        status == 'في انتظار قبول المكتب' ||
        status == 'تم قبوله من المكتب' ||
        status == 'تم تعيين مندوب' ||
        status == 'المندوب قبل الطلب' ||
        status == 'تم استلام الطلب من المتجر' ||
        status == 'الطلب مكتمل' ||
        status == 'المندوب رفض الطلب' ||
        status == 'الزبون رفض الاستلام' ||
        status == 'المكتب رفض الطلب' ||
        status == 'التسليم الذاتي') {
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
        return 'تم التسليم للطيار';
      case 'rejected':
        return 'تم رفض الطلب';
      case 'cancelled_by_customer':
        return 'تم إلغاء الطلب';
      case 'returned_to_merchant':
        return 'المكتب رفض الطلب';
      case 'self_delivery':
        return 'التسليم الذاتي';
      default:
        return status;
    }
  }

  // ======== Status Translation (Delivery app statuses) ========
  // تستخدم بعد إنشاء مستند فى request delivery لهذا الطلب
  String _convertDeliveryStatusToArabic(String status) {
    // لو القيمة أصلاً عربية ومعروفة نرجعها كما هى
    if (status == 'في انتظار قبول المكتب' ||
        status == 'تم قبوله من المكتب' ||
        status == 'تم تعيين مندوب' ||
        status == 'المندوب قبل الطلب' ||
        status == 'تم استلام الطلب من المتجر' ||
        status == 'الطلب مكتمل' ||
        status == 'المندوب رفض الطلب' ||
        status == 'الزبون رفض الاستلام' ||
        status == 'تم رفض الطلب من المكتب' ||
        status == 'في انتظار قبول المكتب' ||
        status == 'تم قبوله من المكتب' ||
        status == 'تم تعيين مندوب' ||
        status == 'المندوب قبل الطلب' ||
        status == 'تم استلام الطلب من المتجر' ||
        status == 'الطلب مكتمل' ||
        status == 'المندوب رفض الطلب' ||
        status == 'الزبون رفض الاستلام' ||
        status == 'المكتب رفض الطلب') {
      return status;
    }

    switch (status.toLowerCase()) {
      // الحالات الخاصة بتطبيق المكاتب (request delivery)
      // مثلما هى فى الجدول الذى أرسلته
      case 'pending': // طلب جديد - فى انتظار قبول المكتب
        return 'في انتظار قبول المكتب';
      case 'accepted': // تم قبوله من المكتب - بإنتظار تعيين مندوب
        return 'تم قبوله من المكتب';
      case 'assigned': // تم تعيين مندوب
        return 'تم تعيين مندوب';
      case 'driver_accepted': // المندوب قبل الطلب - بإنتظار الاستلام من المتجر
        return 'المندوب قبل الطلب';
      case 'picked_up': // تم استلام الطلب من المتجر - المندوب فى الطريق للزبون
        return 'تم استلام الطلب من المتجر';
      case 'completed': // تم التسليم
        return 'الطلب مكتمل';
      case 'driver_rejected': // المندوب رفض الطلب / تم تعيين مندوب آخر
        return 'المندوب رفض الطلب';
      case 'customer_rejected': // الزبون رفض الاستلام
        return 'الزبون رفض الاستلام';
      case 'rejected': // رفض نهائى من المكتب
        return 'تم رفض الطلب من المكتب';
      case 'returned_to_merchant':
        return 'المكتب رفض الطلب';
      default:
        return status;
    }
  }

  String _convertIndependentStatusToArabic(String status) {
    if (status == 'في انتظار قبول المندوب' ||
        status == 'المندوب قبل الطلب' ||
        status == 'تم استلام الطلب من المتجر' ||
        status == 'الطلب مكتمل' ||
        status == 'المندوب رفض الطلب' ||
        status == 'الزبون رفض الاستلام' ||
        status == 'تم إلغاء الطلب من التاجر' ||
        status == 'تم إعادة التعيين من التاجر') {
      return status;
    }

    switch (status.toLowerCase()) {
      case 'pending':
      case 'searching':
        return 'تم استلام الطلب';
      case 'assigned':
      case 'notified_multiple':
        return 'في انتظار قبول المندوب';
      case 'driver_accepted':
      case 'accepted':
        return 'المندوب قبل الطلب';
      case 'picked_up':
        return 'تم استلام الطلب من المتجر';
      case 'completed':
        return 'الطلب مكتمل';
      case 'driver_rejected':
        return 'المندوب رفض الطلب';
      case 'customer_rejected':
        return 'الزبون رفض الاستلام';
      case 'cancelled':
      case 'cancelled_by_merchant':
        return 'تم إلغاء الطلب من التاجر';
      case 'reassigned_by_merchant':
        return 'تم إعادة التعيين من التاجر';
      default:
        return status;
    }
  }

  Future<void> cancelIndependentCourierDispatch(String orderId, String actionType) async {
    final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) return;
    final dispatch = orderDoc.data() ?? {};
    if (dispatch['dispatchType'] != 'independent_courier') return;

    final String? assignedCourierId = dispatch['assignedCourierId'] as String?;
    final updates = <String, dynamic>{
      'assignedCourierId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (assignedCourierId != null && assignedCourierId.isNotEmpty) {
      updates['previousCourierId'] = assignedCourierId;
      updates['courierResponses.$assignedCourierId'] = 'cancelled_by_merchant';

      // Clear courier's busy status in Realtime Database
      try {
        await FirebaseDatabase.instance.ref('couriers_live/$assignedCourierId/currentOrderId').remove();
        await FirebaseDatabase.instance.ref('couriers_live/$assignedCourierId/current_order_id').remove();
      } catch (e) {
        print('Error clearing courier currentOrderId in RTDB: $e');
      }
    }

    if (actionType == 'send_to_office') {
      updates['status'] = 'cancelled_by_merchant';
      updates['dispatchStatus'] = 'sent_to_office';
      updates['cancelledAt'] = FieldValue.serverTimestamp();
      updates['cancelReason'] = 'merchant_sent_to_office';
    } else if (actionType == 'deliver_self') {
      updates['status'] = 'cancelled_by_merchant';
      updates['dispatchStatus'] = 'delivered_by_merchant';
      updates['cancelledAt'] = FieldValue.serverTimestamp();
      updates['cancelReason'] = 'merchant_delivering_self';
    } else if (actionType == 'cancel_order') {
      updates['status'] = 'cancelled_by_merchant';
      updates['dispatchStatus'] = 'cancelled_by_merchant';
      updates['cancelledAt'] = FieldValue.serverTimestamp();
      updates['cancelReason'] = 'merchant_cancelled_order';
    }

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      print('Error updating independent dispatch: $e');
    }
  }

  // ======== Delivery request ========
  Future<String?> sendDeliveryRequest({
    required String orderDocumentId,
    required Map<String, dynamic> office,
    Map<String, String>? distanceInfo,
    bool replacePendingRequest = false,
  }) async {
    try {
      print('🚀 بدء إرسال طلب التوصيل...');
      print('📦 orderDocumentId: $orderDocumentId');
      print('🏢 office: ${office['name']} (${office['id']})');

      final orderDoc = await _service.getPresentOrder(
        marketId,
        orderDocumentId,
      );
      if (!orderDoc.exists) {
        print('❌ الطلب غير موجود');
        return 'الطلب غير موجود';
      }

      final orderData = orderDoc.data() ?? <String, dynamic>{};
      final customerInfo =
          orderData['customerInfo'] as Map<String, dynamic>? ?? {};
      final customerId =
          customerInfo['userId'] as String? ?? orderData['userId'] as String?;

      print('👤 customerId: $customerId');

      final marketDoc = await _storeService.getStore(marketId);
      final marketData = marketDoc.data();

      // التحقق من البيانات الأساسية
      if (office['id'] == null || office['id'].toString().isEmpty) {
        print('❌ معرف مكتب الشحن غير موجود');
        return 'معرف مكتب الشحن غير صحيح';
      }

      final existingRequest = orderData['deliveryRequest'] as Map<String, dynamic>?;
      if (existingRequest != null) {
        final existingRequestId = orderDocumentId;
        final existingStatus = (existingRequest['status'] ?? '').toString();
        final existingOfficeId = (existingRequest['officeId'] ?? '').toString();
        final isPendingOfficeApproval =
            existingStatus == 'pending' || 
            existingStatus == 'في انتظار قبول المكتب' ||
            existingStatus == 'accepted' ||
            existingStatus == 'تم قبوله من المكتب';
        final isOfficeReturnedToMerchant =
            _isReturnedToMerchantRaw(existingStatus);

        if (replacePendingRequest) {
          final canReplace =
              (isPendingOfficeApproval || isOfficeReturnedToMerchant) &&
                  existingRequestId.isNotEmpty;
          if (!canReplace) {
            return 'لا يمكن تغيير المكتب بعد بدء تنفيذ الطلب';
          }
          if (existingOfficeId.isNotEmpty &&
              existingOfficeId == (office['id'] ?? '').toString()) {
            return 'تم اختيار نفس المكتب الحالي';
          }
          await _deliveryRequestService.updateRequestStatus(existingRequestId, 'cancelled_by_merchant');
        } else {
          if (isOfficeReturnedToMerchant) {
            return 'استخدم «مكتب جديد» لإعادة الإرسال بعد رفض المكتب';
          }
          return 'تم إرسال طلب توصيل لهذا الطلب بالفعل';
        }
      }

      final payload = <String, dynamic>{
        'orderId': orderData['orderId'] ?? orderDocumentId,
        'orderDocumentId': orderDocumentId,
        'marketId': marketId,
        'marketName': marketData != null ? marketData['name'] ?? '' : '',
        'marketPhone': marketData != null ? marketData['phone'] ?? '' : '',
        'marketAddress': marketData != null
            ? (marketData['address'] ?? marketData['description'] ?? '')
            : '',
        'marketLocation': marketData != null
            ? marketData['location'] ?? marketLocation
            : marketLocation,
        'customerId': customerId ?? '',
        'customerName': customerInfo['name'] ?? '',
        'customerPhone': customerInfo['phone'] ?? '',
        'customerAddress': customerInfo['address'] ?? '',
        'customerLocation': customerInfo['location'],
        'distanceText': distanceInfo?['distance'],
        'durationText': distanceInfo?['duration'],
        'orderCreatedAt': orderData['createdAt'],
        'items': orderData['items'] ?? [],
        'subtotal': orderData['subtotal'] ?? orderData['totalAmount'] ?? 0,
        'deliveryFee': orderData['deliveryFee'] ?? 0,
        'serviceFee': orderData['serviceFee'] ?? 0,
        'totalAmount': orderData['totalAmount'] ?? 0,
        'officeId': office['id'] ?? '',
        'officeName': office['name'] ?? '',
        'officePhone': office['phone'] ?? '',
        'officeAddress': office['address'] ?? '',
        'officeEmail': office['email'] ?? '',
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      };

      print('📤 إرسال البيانات إلى قاعدة البيانات...');
      await _deliveryRequestService.createRequest(payload);
      print('✅ تم إرسال البيانات بنجاح');

      // Cancel/unassign independent dispatch if any exists
      try {
        await cancelIndependentCourierDispatch(orderDocumentId, 'send_to_office');
      } catch (e) {
        print('⚠️ Error cancelling independent dispatch during sendDeliveryRequest: $e');
      }

      print('🔄 تحديث حالة الطلب...');
      await _service.updatePresentOrderStatus(
        marketId,
        orderDocumentId,
        'جارى تسليم للدليفري',
      );
      print('✅ تم تحديث حالة الطلب');

      if (customerId != null && customerId.isNotEmpty) {
        try {
          await _service.updateUserOrder(customerId, orderDocumentId, {
            'status': 'جارى تسليم للدليفري',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('✅ تم تحديث طلب العميل');
        } catch (e) {
          print('⚠️ خطأ في تحديث طلب العميل: $e');
        }
      }

      print('✅ تم إكمال العملية بنجاح');
      return null;
    } catch (e, stackTrace) {
      print('❌ خطأ في إرسال طلب التوصيل: $e');
      print('📍 Stack trace: $stackTrace');
      return 'تعذر إرسال الطلب للدليفري: ${e.toString()}';
    }
  }

  // ======== Update order status ========
  Future<String?> updateOrderStatus(
    BuildContext context,
    String documentId,
    String newStatus,
  ) async {
    if (documentId.isEmpty) {
      return 'خطأ: معرف الطلب غير صحيح';
    }
    try {
      final orderDoc = await _service.getPresentOrder(marketId, documentId);
      if (!orderDoc.exists) {
        return 'الطلب غير موجود';
      }

      final orderData = orderDoc.data() ?? <String, dynamic>{};
      final customerInfo =
          orderData['customerInfo'] as Map<String, dynamic>? ?? {};
      final customerId =
          customerInfo['userId'] as String? ?? orderData['userId'] as String?;

      if (newStatus == 'تم التسليم للطيار' || newStatus == 'تم رفض الطلب') {
        final deliveryInfo = orderData['deliveryRequest'] as Map<String, dynamic>?;
        final rid = documentId;
        if (deliveryInfo != null) {
          try {
            await _deliveryRequestService.updateRequestStatus(rid, 'cancelled_by_merchant');
          } catch (_) {}
        }
        try {
          await cancelIndependentCourierDispatch(
            documentId,
            newStatus == 'تم التسليم للطيار' ? 'deliver_self' : 'cancel_order',
          );
        } catch (_) {}
      }

      final isFinalStatus =
          newStatus == 'تم التسليم للطيار' || newStatus == 'تم رفض الطلب';

      if (isFinalStatus) {
        await _service.moveToPastOrder(
          marketId,
          documentId,
          orderData,
          newStatus,
        );

        // Mirror status in user's order document as well
        if (customerId != null && customerId.isNotEmpty) {
          try {
            await _service.updateUserOrder(customerId, documentId, {
              'status': newStatus,
              'updatedAt': FieldValue.serverTimestamp(),
              'completedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }
      } else {
        await _service.updatePresentOrderStatus(
          marketId,
          documentId,
          newStatus,
        );

        if (customerId != null && customerId.isNotEmpty) {
          try {
            await _service.updateUserOrder(customerId, documentId, {
              'status': newStatus,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {}
        }
      }
      return null;
    } catch (e) {
      return 'خطأ في تحديث حالة الطلب: ${e.toString()}';
    }
  }

  // ======== Dispose ========
  void disposeViewModel() {
    _timer?.cancel();
    _rejectedRequestsSubscription?.cancel();
    _deliveryRequestsSubscription?.cancel();
    _independentDispatchOrdersSubscription?.cancel();
    _couriersDirectorySubscription?.cancel();
    scrollController.dispose();
  }
}
