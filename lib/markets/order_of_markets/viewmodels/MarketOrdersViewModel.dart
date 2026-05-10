import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/OrderService.dart';
import '../services/delivery_request_service.dart';
import 'package:bazar_suez/markets/create_market/services/store_service.dart';
import 'package:bazar_suez/services/delivery_fee/delivery_fee_service.dart';

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
  
  // تخزين رسائل الرفض لعرضها للتاجر
  final Map<String, String> rejectedMessages = {};

  // تخزين بيانات طلب التوصيل لكل طلب (من مجموعة request delivery)
  // key = orderDocumentId
  final Map<String, Map<String, dynamic>> deliveryRequestsByOrderId = {};

  // ======== Init ========
  void init() {
    scrollController.addListener(_onScroll);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
    _setupOrdersStream();
    _fetchMarketLocation();
    _listenToRejectedRequests();
    _listenToDeliveryRequests();
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

  // الاستماع لكل طلبات التوصيل الخاصة بهذا المتجر
  void _listenToDeliveryRequests() {
    _deliveryRequestsSubscription = _deliveryRequestService
        .streamRequestsForMarket(marketId)
        .listen((requests) {
      deliveryRequestsByOrderId.clear();

      for (final request in requests) {
        final orderDocumentId = request['orderDocumentId'] as String?;
        if (orderDocumentId == null || orderDocumentId.isEmpty) continue;
        deliveryRequestsByOrderId[orderDocumentId] = request;
      }

      // تحديث الـ UI لعرض حالة الطلب / بيانات المندوب فوراً
      notifyListeners();
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

  // ======== Order conversion ========
  Map<String, dynamic> convertOrder(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final customerInfo = data['customerInfo'] as Map<String, dynamic>? ?? {};
      final items = data['items'] as List<dynamic>? ?? [];

      // جلب بيانات طلب التوصيل (إن وجد) لهذا الطلب
      final deliveryInfo = deliveryRequestsByOrderId[doc.id];

      // أولوية عرض الحالة:
      // 1) لو فيه طلب توصيل → نستخدم حالة تطبيق المكاتب (request delivery)
      // 2) لو مفيش → نستخدم حالة الطلب الأصلية الخاصة بالتاجر
      final String status;
      final String? rawStatusFromDelivery =
          deliveryInfo != null ? deliveryInfo['status'] as String? : null;
      final String? rawStatusFromOrder = data['status'] as String?;

      if (rawStatusFromDelivery != null) {
        status = _convertDeliveryStatusToArabic(rawStatusFromDelivery);
      } else {
        status = _convertLegacyStatusToArabic(
          rawStatusFromOrder ?? 'قيد المراجعة',
        );
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
        // بيانات المندوب من وثيقة request delivery (إن وُجدت)
        'assignedDriverName':
            deliveryInfo != null ? deliveryInfo['assignedDriverName'] ?? '' : '',
        'assignedDriverPhone': deliveryInfo != null
            ? deliveryInfo['assignedDriverPhone'] ?? ''
            : '',
        'orderTime': orderTime,
        'createdAt': createdAtTimestamp, // إضافة createdAt لعرض التاريخ
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
        status == 'الزبون رفض الاستلام') {
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
        status == 'الزبون رفض الاستلام') {
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
      default:
        return status;
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

      final existingRequest = deliveryRequestsByOrderId[orderDocumentId];
      if (existingRequest != null) {
        final existingRequestId = (existingRequest['id'] ?? '').toString();
        final existingStatus = (existingRequest['status'] ?? '').toString();
        final existingOfficeId = (existingRequest['officeId'] ?? '').toString();
        final isPendingOfficeApproval =
            existingStatus == 'pending' || existingStatus == 'في انتظار قبول المكتب';

        if (replacePendingRequest) {
          if (!isPendingOfficeApproval || existingRequestId.isEmpty) {
            return 'لا يمكن تغيير المكتب بعد بدء تنفيذ الطلب';
          }
          if (existingOfficeId.isNotEmpty &&
              existingOfficeId == (office['id'] ?? '').toString()) {
            return 'تم اختيار نفس المكتب الحالي';
          }
          await _deliveryRequestService.deleteRequest(existingRequestId);
        } else {
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
    scrollController.dispose();
  }
}
