import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/markets/order_of_markets/utils/order_status_helper.dart';
import 'store_rating_dialog.dart';
import 'delivery_rating_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:bazar_suez/services/review_service.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import '../services/user_orders_service.dart';

/// كارت عرض طلب المستخدم
class UserOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final String orderId;
  final VoidCallback onRatingSubmitted;
  final Map<String, dynamic>?
  deliveryInfo; // بيانات الطلب من تطبيق المكاتب (إن وجدت)

  const UserOrderCard({
    super.key,
    required this.order,
    required this.orderId,
    required this.onRatingSubmitted,
    this.deliveryInfo,
  });

  @override
  State<UserOrderCard> createState() => _UserOrderCardState();
}

class _UserOrderCardState extends State<UserOrderCard> {
  bool _expanded = false;
  bool _isCancelling = false;
  bool _isAccountingSuccess = false;
  final UserOrdersService _ordersService = UserOrdersService();
  Map<String, dynamic>? _fetchedCourierData;
  bool _loadingCourier = false;
  GoogleMapController? _mapController;
  BitmapDescriptor? _motorcycleIcon;

  @override
  void initState() {
    super.initState();
    _checkAndFetchCourier();
    _loadMotorcycleIcon();
  }

  Future<void> _loadMotorcycleIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/delvery.png');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 100, // تصغير الأيقونة لتظهر بشكل مناسب
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? resizedData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
      if (resizedData != null && mounted) {
        setState(() {
          _motorcycleIcon = BitmapDescriptor.bytes(resizedData.buffer.asUint8List());
        });
      }
    } catch (e) {
      // Fallback
      if (mounted) {
        setState(() {
          _motorcycleIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant UserOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCourierId = _resolveCourierId(oldWidget.order, oldWidget.deliveryInfo);
    final newCourierId = _resolveCourierId(widget.order, widget.deliveryInfo);
    if (newCourierId != oldCourierId && newCourierId.isNotEmpty) {
      _fetchCourierDetails(newCourierId);
    }
  }

  void _checkAndFetchCourier() {
    final courierId = _resolveCourierId(widget.order, widget.deliveryInfo);
    if (courierId.isNotEmpty) {
      _fetchCourierDetails(courierId);
    }
  }

  String _resolveCourierId(Map<String, dynamic> order, Map<String, dynamic>? deliveryInfo) {
    final assignedCourierIdFromOrder = (order['assignedCourierId'] ?? '').toString();
    final directDeliveryMap = _asMap(order['deliveryRequest']);
    String cId = '';
    if (deliveryInfo != null || directDeliveryMap.isNotEmpty) {
      final Map<String, dynamic> source = deliveryInfo ?? directDeliveryMap;
      cId = (source['courierId'] ??
              source['driverId'] ??
              source['assignedDriverId'] ??
              source['assignedCourierId'] ??
              assignedCourierIdFromOrder ??
              '')
          .toString();
    }
    if (cId.isEmpty && assignedCourierIdFromOrder.isNotEmpty) {
      cId = assignedCourierIdFromOrder;
    }
    if (cId.isEmpty) {
      cId = (order['courierId'] ?? order['driverId'] ?? '').toString();
    }
    return cId;
  }

  void _fetchCourierDetails(String courierId) {
    if (courierId.isEmpty) return;
    setState(() {
      _loadingCourier = true;
    });
    FirebaseFirestore.instance
        .collection('courier_requests')
        .doc(courierId)
        .get()
        .then((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _fetchedCourierData = doc.data();
          _loadingCourier = false;
        });
      } else if (mounted) {
        setState(() {
          _loadingCourier = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _loadingCourier = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final orderId = widget.orderId;
    final deliveryInfo = widget.deliveryInfo;

    final rawStatus = OrderStatusHelper.resolveRawStatus(order);
    final statusArabic = OrderStatusHelper.toCustomerArabic(rawStatus);
    final statusColor = Color(OrderStatusHelper.statusColor(rawStatus));
    final isCompleted = OrderStatusHelper.isDelivered(order);
    final isRejected = OrderStatusHelper.isRejected(order);

    final createdAt = order['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('d MMMM • h:mm a', 'ar').format(createdAt.toDate())
        : '';

    // اسم المتجر - نحاول جلبه من items أو من حقل منفصل
    final items = order['items'] as List<dynamic>? ?? [];
    String marketName = 'متجر';
    String? marketLogo;
    String marketId = ''; // default empty

    // محاولة جلب معلومات المتجر من المنتج الأول
    if (items.isNotEmpty) {
      final firstItem = items[0] as Map<String, dynamic>?;
      marketLogo = firstItem?['productImage'] as String?;

      // البحث عن storeId في المنتج
      marketId =
          firstItem?['storeId'] as String? ??
          firstItem?['marketId'] as String? ??
          firstItem?['marketLink'] as String? ??
          '';
    }

    // البحث عن اسم المتجر في الحقول المختلفة
    marketName =
        order['storeName'] as String? ??
        order['marketName'] as String? ??
        'متجر';

    // البحث عن storeId في الطلب نفسه (أولوية أعلى)
    if (order['storeId'] != null && (order['storeId'] as String).isNotEmpty) {
      marketId = order['storeId'] as String;
    } else if (order['marketId'] != null &&
        (order['marketId'] as String).isNotEmpty) {
      marketId = order['marketId'] as String;
    } else if (order['marketLink'] != null &&
        (order['marketLink'] as String).isNotEmpty) {
      marketId = order['marketLink'] as String;
    }

    final totalAmount = (order['totalAmount'] ?? 0.0) as num;

    final storeRating = order['storeRating'] as Map<String, dynamic>?;
    final deliveryRating = order['deliveryRating'] as Map<String, dynamic>?;
    final hasRatedStore = storeRating != null;
    final hasRatedDelivery = deliveryRating != null;
    final hasFullyRated = hasRatedStore && hasRatedDelivery;
    final userRating = storeRating?['rating'] as int?;

    // ================== بيانات المندوب المعروضة للزبون ==================
    String driverName = '';
    String driverPhone = '';
    String driverPhoto = '';
    String courierId = '';

    // 1) لو الطلب داخل نظام المكاتب → نستخدم بيانات المندوب من request delivery
    final directDeliveryMap = _asMap(order['deliveryRequest']);
    final couriersDir = _asMap(order['independentCouriersDirectory']);
    final assignedCourierIdFromOrder = (order['assignedCourierId'] ?? '').toString();

    if (deliveryInfo != null || directDeliveryMap.isNotEmpty) {
      final Map<String, dynamic> source = deliveryInfo ?? directDeliveryMap;
      driverName = (source['assignedDriverName'] ??
              source['driverName'] ??
              source['driver_name'] ??
              '')
          .toString();
      driverPhone = (source['assignedDriverPhone'] ??
              source['driverPhone'] ??
              source['driver_phone'] ??
              '')
          .toString();
      driverPhoto = (source['assignedDriverPhoto'] ??
              source['driverPhoto'] ??
              source['driverImage'] ??
              '')
          .toString();
      courierId = (source['courierId'] ??
              source['driverId'] ??
              source['assignedDriverId'] ??
              source['assignedCourierId'] ??
              assignedCourierIdFromOrder ??
              '')
          .toString();
    }
    // 2) الطلب عبر مندوب مستقل
    if (courierId.isEmpty && assignedCourierIdFromOrder.isNotEmpty) {
      courierId = assignedCourierIdFromOrder;
    }
    if (courierId.isEmpty) {
      courierId = (order['courierId'] ?? order['driverId'] ?? '').toString();
    }
    if (courierId.isNotEmpty && (driverName.isEmpty || driverPhone.isEmpty || driverPhoto.isEmpty)) {
      final cData = _fetchedCourierData ?? _asMap(couriersDir[courierId]);
      final nameRaw = cData['name'] ??
          cData['fullName'] ??
          cData['full_name'] ??
          cData['userName'] ??
          cData['user_name'] ??
          cData['displayName'] ??
          cData['display_name'];
      driverName = driverName.isEmpty
          ? (nameRaw ?? 'مندوب').toString()
          : driverName;
      final phoneRaw = cData['phone'] ??
          cData['phoneNumber'] ??
          cData['phone_number'];
      driverPhone = driverPhone.isEmpty ? (phoneRaw ?? '').toString() : driverPhone;
      final photoRaw = cData['profileImage'] ??
          cData['personalPhoto'] ??
          cData['personal_photo'] ??
          cData['photoUrl'] ??
          cData['photo_url'] ??
          cData['personalImage'] ??
          cData['personal_image'] ??
          cData['image'] ??
          cData['photo'] ??
          cData['avatar'] ??
          cData['avatarUrl'] ??
          cData['avatar_url'];
      driverPhoto = driverPhoto.isEmpty
          ? (photoRaw ?? '').toString()
          : driverPhoto;
    }
    // 2) لو مفيش DeliveryInfo، لكن التاجر اختار "هسلمه بنفسى"
    else if (isCompleted && deliveryInfo == null) {
      // نحاول إيجاد رقم هاتف المتجر من الطلب
      final dynamic rawStorePhone =
          order['marketPhone'] ??
          order['storePhone'] ??
          order['store_phone'] ??
          order['phone'] ??
          order['market_phone'];

      final String storePhone = rawStorePhone?.toString() ?? '';
      // نعرض على الأقل "مندوب المتجر" حتى لو لم يتوفر رقم الهاتف
      driverName = 'مندوب المتجر';
      driverPhone = storePhone;
    }

    // التحقق من إمكانية التقييم (يجب أن يكون هناك storeId)
    final canRate = isCompleted && marketId.isNotEmpty;
    final rawStatusLower = OrderStatusHelper.resolveRawStatus(order).toLowerCase();
    final shouldShowTrackingMap =
        rawStatusLower == 'picked_up' || rawStatusLower == 'out_for_delivery';

    if (isCompleted && !_isAccountingSuccess) {
      _isAccountingSuccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final uid = (order['userId'] ?? order['customerInfo']?['userId'] ?? '').toString();
        if (uid.isEmpty) return;
        _ordersService.accountSuccessfulOrderIfNeeded(
          orderId: orderId,
          userId: uid,
        );
      });
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - الحالة والتاريخ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusArabic,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // معلومات المندوب عندما يكون الطلب فى نظام الشحن
          if ((driverName.isNotEmpty || driverPhone.isNotEmpty) &&
              !isRejected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // نفس درجة لون حالة الطلب فى الأعلى لمزيد من الاتساق البصري
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    _buildDriverAvatar(driverPhoto),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (driverName.isNotEmpty)
                            Text(
                              'المندوب: $driverName',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (driverPhone.isNotEmpty)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'هاتف المندوب: $driverPhone',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.phone,
                                    size: 18,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _callPhone(driverPhone),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildTrackingSection(
              order: order,
              marketName: marketName,
              courierId: courierId,
              showMap: shouldShowTrackingMap,
            ),
          ),

          // معلومات المتجر
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // شعار المتجر
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[100],
                  ),
                  child: marketLogo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            marketLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.store, color: Colors.grey),
                          ),
                        )
                      : const Icon(Icons.store, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                // اسم المتجر ورمز الطلب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marketName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'رمز الطلب: ${order['orderId'] ?? orderId}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // عدد المنتجات
                Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[400],
                      ),
                    ),
                    Text(
                      '${items.length} منتج',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // قائمة المنتجات
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: (_expanded ? items : items.take(2)).map((item) {
                  final itemData = item as Map<String, dynamic>;
                  final quantity = itemData['quantity'] ?? 1;
                  final name = itemData['productName'] ?? 'منتج';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: itemData['productImage'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    itemData['productImage'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.fastfood,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.fastfood,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'x$quantity $name',
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 1),

          // المبلغ الإجمالي
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // زر اطلب مجدداً وإلغاء الطلب
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton(
                      onPressed: marketId.isNotEmpty
                          ? () =>
                                context.push('/HomeMarketPage?marketLink=$marketId')
                          : null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        side: const BorderSide(color: AppColors.mainColor),
                      ),
                      child: const Text(
                        'اطلب مجدداً',
                        style: TextStyle(
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isCompleted && !isRejected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                        child: InkWell(
                          onTap: _isCancelling ? null : () => _confirmCancel(order, orderId),
                          child: _isCancelling
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : Text(
                                  'إلغاء الطلب',
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
                // المبلغ وتفاصيل الدفع
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ج.م ${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _showInvoiceDialog(context, order, items, totalAmount),
                      child: Text(
                        'تفاصيل الدفع',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // التقييم أو زر التقييم
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: hasFullyRated
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'تقييمك $userRating/5',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : canRate
                ? GestureDetector(
                    onTap: () => _showRatingDialog(
                      context,
                      marketId,
                      marketName,
                      marketLogo,
                      courierId: courierId,
                      driverName: driverName,
                      hasRatedStore: hasRatedStore,
                      hasRatedDelivery: hasRatedDelivery,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.mainColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'قيّم الطلب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : isCompleted && marketId.isEmpty
                ? Center(
                    child: Text(
                      'لا يمكن التقييم - معرف المتجر غير متوفر',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(
    BuildContext context,
    String storeId,
    String storeName,
    String? storeLogo, {
    required String courierId,
    required String driverName,
    required bool hasRatedStore,
    required bool hasRatedDelivery,
  }) {
    final reviewService = ReviewService();

    Future<void> openDeliveryDialog() async {
      if (hasRatedDelivery) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DeliveryRatingDialog(
          driverId: courierId,
          driverName: driverName,
          onSubmit: (deliveryRating, deliveryComment) async {
            try {
              await reviewService.submitDeliveryRating(
                orderId: widget.orderId,
                rating: deliveryRating,
                comment: deliveryComment,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('شكراً لتقييمك!'),
                    backgroundColor: Colors.green,
                  ),
                );
                widget.onRatingSubmitted();
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );
    }

    if (hasRatedStore && !hasRatedDelivery) {
      openDeliveryDialog();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoreRatingDialog(
        storeId: storeId,
        storeName: storeName,
        storeLogo: storeLogo,
        onSubmit: (rating, comment, tags) async {
          try {
            // حفظ تقييم المتجر
            await reviewService.submitStoreRating(
              orderId: widget.orderId,
              storeId: storeId,
              rating: rating,
              comment: comment,
              tags: tags,
              storeName: storeName,
            );

            if (context.mounted) {
              Navigator.pop(context);
              await openDeliveryDialog();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('حدث خطأ: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildDriverAvatar(String driverPhoto) {
    if (driverPhoto.isEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.orange.withOpacity(0.15),
        ),
        child: const Icon(
          Icons.delivery_dining,
          color: Colors.orange,
          size: 20,
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        driverPhoto,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orange.withOpacity(0.15),
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: Colors.orange,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingSection({
    required Map<String, dynamic> order,
    required String marketName,
    required String courierId,
    required bool showMap,
  }) {
    final customerInfoMap = _asMap(order['customerInfo']);
    final deliveryMap = _asMap(order['deliveryRequest']);
    final marketMap = _asMap(order['market']);
    
    GeoPoint? customerLocation = _extractGeoPoint(
      customerInfoMap['location'] ?? order['customerLocation'],
    );
    if (customerLocation == null &&
        order['customerLatitude'] != null &&
        order['customerLongitude'] != null) {
      final lat = order['customerLatitude'];
      final lng = order['customerLongitude'];
      if (lat is num && lng is num) {
        customerLocation = GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }

    GeoPoint? marketLocation = _extractGeoPoint(
      order['marketLocation'] ??
          order['storeLocation'] ??
          deliveryMap['marketLocation'] ??
          deliveryMap['storeLocation'] ??
          marketMap['location'] ??
          order['storeGeoPoint'] ??
          order['marketGeoPoint'],
    );
    if (marketLocation == null &&
        order['storeLatitude'] != null &&
        order['storeLongitude'] != null) {
      final lat = order['storeLatitude'];
      final lng = order['storeLongitude'];
      if (lat is num && lng is num) {
        marketLocation = GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }

    if (!showMap) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'بانتظار استلام المندوب للطلب',
          style: TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (courierId.isEmpty || customerLocation == null || marketLocation == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'لا تتوفر بيانات كافية للتتبع الآن',
          style: TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('couriers_live/$courierId').onValue,
      builder: (context, snapshot) {
        final val = snapshot.data?.snapshot.value;
        GeoPoint? courierPoint;
        if (val is Map) {
          final map = Map<dynamic, dynamic>.from(val);
          final lat = map['latitude'];
          final lng = map['longitude'];
          if (lat is num && lng is num) {
            courierPoint = GeoPoint(lat.toDouble(), lng.toDouble());
          }
        }

        final nonNullMarket = marketLocation!;
        final nonNullCustomer = customerLocation!;
        final totalDistance = _distanceMeters(nonNullMarket, nonNullCustomer);
        final remainingDistance = courierPoint == null
            ? totalDistance
            : _distanceMeters(courierPoint, nonNullCustomer);
        final progress = totalDistance <= 0
            ? 0.0
            : (1 - (remainingDistance / totalDistance)).clamp(0.0, 1.0);

        final markers = <Marker>{
          Marker(
            markerId: const MarkerId('store'),
            position: LatLng(nonNullMarket.latitude, nonNullMarket.longitude),
            infoWindow: InfoWindow(title: marketName),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          ),
          Marker(
            markerId: const MarkerId('customer'),
            position: LatLng(nonNullCustomer.latitude, nonNullCustomer.longitude),
            infoWindow: const InfoWindow(title: 'موقع الوصول'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
          if (courierPoint != null)
            Marker(
              markerId: const MarkerId('courier'),
              position: LatLng(courierPoint.latitude, courierPoint.longitude),
              infoWindow: const InfoWindow(title: 'المندوب'),
              icon: _motorcycleIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            ),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: courierPoint != null 
                          ? LatLng(courierPoint.latitude, courierPoint.longitude) 
                          : LatLng(nonNullCustomer.latitude, nonNullCustomer.longitude),
                      zoom: 14,
                    ),
                    markers: markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                    },
                  ),
                  if (courierPoint != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.orange,
                        onPressed: () {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(courierPoint!.latitude, courierPoint!.longitude),
                              15,
                            ),
                          );
                        },
                        child: const Icon(Icons.my_location, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: AppColors.mainColor,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المتبقي: ${_formatDistance(remainingDistance)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  'التقدم: ${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  GeoPoint? _extractGeoPoint(dynamic raw) {
    if (raw is GeoPoint) return raw;
    if (raw is Map) {
      final lat = raw['lat'] ?? raw['latitude'];
      final lng = raw['lng'] ?? raw['longitude'];
      if (lat is num && lng is num) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  double _distanceMeters(GeoPoint a, GeoPoint b) {
    const r = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final s1 = math.sin(dLat / 2);
    final s2 = math.sin(dLng / 2);
    final aa = s1 * s1 +
        math.cos(_toRad(a.latitude)) * math.cos(_toRad(b.latitude)) * s2 * s2;
    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return r * c;
  }

  double _toRad(double d) => d * math.pi / 180;

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  /// استخراج سعر المنتج من أي حقل متاح في بيانات الطلب
  double _extractItemPrice(Map<String, dynamic> itemData) {
    // totalPrice = (productPrice + additionalPrice) * quantity → أدق قيمة لإجمالي العنصر
    // unitPrice  = productPrice + additionalPrice              → السعر لكل وحدة
    // productPrice                                             → السعر الأساسي
    // price                                                    → قد يكون موجوداً في بعض الطلبات القديمة
    const candidateFields = [
      'totalPrice',
      'total',
      'finalPrice',
      'unitPrice',
      'productPrice',
      'price',
      'subtotal',
    ];
    for (final field in candidateFields) {
      final value = itemData[field];
      if (value is num) return value.toDouble();
      if (value != null) {
        final parsed = double.tryParse(value.toString());
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return 0.0;
  }

  void _showInvoiceDialog(BuildContext context, Map<String, dynamic> order, List<dynamic> items, num totalAmount) {
    final deliveryFee = (order['deliveryFee'] ?? 0.0) as num;
    final discount = (order['discount'] ?? 0.0) as num;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('فاتورة الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 30),
                ...items.map((item) {
                  final itemData = item as Map<String, dynamic>;
                  final name = itemData['productName'] ?? itemData['name'] ?? 'منتج';
                  final quantity = (itemData['quantity'] ?? 1) as num;
                  final itemPrice = _extractItemPrice(itemData);

                  // إذا كان totalPrice موجوداً فهو يعكس الإجمالي للعنصر مباشرة
                  // وإلا نضرب unitPrice/productPrice في الكمية
                  final hasTotal = itemData['totalPrice'] is num ||
                      itemData['total'] is num ||
                      itemData['finalPrice'] is num;
                  final displayTotal = hasTotal ? itemPrice : itemPrice * quantity.toDouble();

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'x$quantity $name',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${displayTotal.toStringAsFixed(2)} ج.م',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 30),
                if (deliveryFee > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('رسوم التوصيل', style: TextStyle(fontSize: 14)),
                        Text('${deliveryFee.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                if (discount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الخصم', style: TextStyle(fontSize: 14, color: Colors.green)),
                        Text('-${discount.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green)),
                      ],
                    ),
                  ),
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإجمالي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${totalAmount.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.mainColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmCancel(Map<String, dynamic> order, String orderId) async {
    final status = OrderStatusHelper.resolveRawStatus(order).toLowerCase();
    final isPendingReview =
        status == 'pending' || status == 'pending_review' || status == 'قيد المراجعة';
    final warning = isPendingReview
        ? 'سيتم إلغاء الطلب بدون تأثير على نسبة الالتزام.'
        : 'إلغاء الطلب في هذه المرحلة سيؤثر على نسبة الالتزام الخاصة بك عند المتاجر.';

    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('تأكيد إلغاء الطلب'),
            content: Text(warning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('رجوع'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('إلغاء الطلب'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    setState(() => _isCancelling = true);
    try {
      final resolvedUserId = (order['userId'] ??
              (order['customerInfo'] is Map
                  ? (order['customerInfo'] as Map)['userId']
                  : ''))
          .toString()
          .trim();
      if (resolvedUserId.isEmpty || resolvedUserId.toLowerCase() == 'null') {
        throw Exception('معرف العميل غير متوفر في بيانات الطلب');
      }

      await _ordersService.cancelOrderByCustomer(
        orderId: orderId,
        userId: resolvedUserId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الطلب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إلغاء الطلب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Future<void> _callPhone(String phone) async {
    if (phone.trim().isEmpty) return;
    final uri = Uri.parse('tel:${phone.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
