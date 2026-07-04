// markets/
//  └── my_order/
//      ├── MarketOrdersPage.dart        ✅ (الصفحة الرئيسية)
//      └── widget/
//          ├── OrderCard.dart           ✅ (كارت الطلب الواحد)
//          ├── OrderInfoRow.dart        ✅ (صف سطر المعلومات)
//          ├── OrderActionButtons.dart  ✅ (الأزرار الخاصة بالحالة)
//          └── OrderCollapsibleHeader.dart  ✅ (العنوان مع البحث) [موجود لديك بالفعل]
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import 'package:bazar_suez/markets/order_of_markets/widget/OrderCollapsibleHeader.dart';
import 'package:bazar_suez/markets/order_of_markets/widget/OrderCard.dart';
import 'package:bazar_suez/markets/order_of_markets/widget/OrderStats.dart';
import 'package:bazar_suez/markets/order_of_markets/viewmodels/MarketOrdersViewModel.dart';
import 'package:bazar_suez/markets/order_of_markets/independent_couriers/widgets/independent_courier_picker_sheet.dart';
import 'package:bazar_suez/services/independent_courier/independent_courier_settings_service.dart';
import 'package:bazar_suez/services/review_service.dart';
import 'package:bazar_suez/theme/app_color.dart';

class MarketOrdersPage extends StatefulWidget {
  final String marketId;
  final String? initialOrderId;
  const MarketOrdersPage({
    super.key,
    required this.marketId,
    this.initialOrderId,
  });

  @override
  State<MarketOrdersPage> createState() => _MarketOrdersPageState();
}

class _MarketOrdersPageState extends State<MarketOrdersPage>
    with SingleTickerProviderStateMixin {
  late final MarketOrdersViewModel _viewModel;
  late final TextEditingController _searchController;
  final _courierSettingsService = IndependentCourierSettingsService();
  AnimationController? _animController;

  /// طلبات ظهر dialog التقييم للمندوب فيها (لتجنب الإعادة)
  final Set<String> _ratingShownForOrders = {};

  /// يتحقق من الطلبات ويعرض dialog التقييم لو المندوب استلم الطلب
  void _checkAndShowRatingDialogIfNeeded(List<Map<String, dynamic>> orders) {
    for (final order in orders) {
      final orderId = (order['documentId'] ?? order['id'] ?? '').toString();
      if (orderId.isEmpty) continue;
      if (_ratingShownForOrders.contains(orderId)) continue;

      // تحقق من وجود merchantCourierRating (تم التقييم مسبقاً)
      if (order['merchantCourierRating'] != null) {
        _ratingShownForOrders.add(orderId);
        continue;
      }

      final dispatch = order['independentDispatch'] as Map<String, dynamic>?;
      if (dispatch == null) continue;

      final dispatchStatus = (dispatch['status'] ?? '').toString().toLowerCase();
      // عرض dialog لما المندوب يستلم الطلب من المتجر
      if (dispatchStatus != 'picked_up' && dispatchStatus != 'completed') continue;

      final courierId = (dispatch['assignedCourierId'] ?? '').toString();
      if (courierId.isEmpty) continue;

      // جيب اسم المندوب من الدليل
      final directory = (order['independentCouriersDirectory'] is Map)
          ? Map<String, dynamic>.from(order['independentCouriersDirectory'])
          : <String, dynamic>{};
      final courierData = directory[courierId] is Map
          ? Map<String, dynamic>.from(directory[courierId])
          : <String, dynamic>{};
      final courierName = (courierData['name'] ??
              courierData['fullName'] ??
              courierData['displayName'] ??
              'المندوب')
          .toString();

      _ratingShownForOrders.add(orderId);

      // عرض dialog بعد بناء الـ frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showMerchantCourierRatingDialog(
          orderId: orderId,
          courierId: courierId,
          courierName: courierName,
        );
      });
    }
  }

  /// dialog تقييم المندوب من التاجر
  Future<void> _showMerchantCourierRatingDialog({
    required String orderId,
    required String courierId,
    required String courierName,
  }) async {
    int selectedRating = 0;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أيقونة وعنوان
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delivery_dining_rounded,
                          size: 36,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'قيّم المندوب',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'استلم $courierName الطلب\nكيف كانت تجربتك معه؟',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // النجوم
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final star = i + 1;
                          return GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedRating = star),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                star <= selectedRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 40,
                                color: star <= selectedRating
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                              ),
                            ),
                          );
                        }),
                      ),

                      if (selectedRating > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          _ratingLabel(selectedRating),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _ratingColor(selectedRating),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // تعليق اختياري
                      TextField(
                        controller: commentController,
                        maxLines: 2,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: 'تعليق (اختياري)',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.mainColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // أزرار
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('تخطي'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: (selectedRating == 0 || isSubmitting)
                                  ? null
                                  : () async {
                                      setDialogState(
                                          () => isSubmitting = true);
                                      try {
                                        await ReviewService()
                                            .submitMerchantCourierRating(
                                          orderId: orderId,
                                          courierId: courierId,
                                          courierName: courierName,
                                          marketId: widget.marketId,
                                          rating: selectedRating,
                                          comment: commentController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : commentController.text
                                                  .trim(),
                                        );
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'شكراً! تم حفظ تقييمك'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(
                                            () => isSubmitting = false);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'حدث خطأ: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.mainColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.grey.shade200,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'إرسال التقييم',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    commentController.dispose();
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'سيء جداً';
      case 2:
        return 'سيء';
      case 3:
        return 'مقبول';
      case 4:
        return 'جيد';
      case 5:
        return 'ممتاز';
      default:
        return '';
    }
  }

  Color _ratingColor(int rating) {
    if (rating <= 2) return Colors.red;
    if (rating == 3) return Colors.orange;
    return Colors.green;
  }

  void _showCourierUnavailableMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          IndependentCourierSettingsService.serviceUnavailableMessage,
        ),
      ),
    );
  }

  Future<bool> _ensureCourierEnabled() async {
    final enabled = await _courierSettingsService
        .isIndependentCourierEnabledForStore(widget.marketId);
    if (!enabled) {
      _showCourierUnavailableMessage();
    }
    return enabled;
  }

  Future<void> _handleRequestDelivery(
    Map<String, dynamic> order,
    Map<String, String>? distanceInfo,
  ) async {
    if (!await _ensureCourierEnabled()) return;

    final documentId = order['documentId'] as String?;
    if (documentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('معرف الطلب غير متوفر')));
      }
      return;
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IndependentCourierPickerSheet(
        marketId: widget.marketId,
        presentOrderDocumentId: documentId,
      ),
    );
  }

  Future<void> _openIndependentCourierPicker({
    required String orderDocumentId,
    Set<String> excludedCourierUids = const <String>{},
  }) async {
    if (!await _ensureCourierEnabled()) return;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => IndependentCourierPickerSheet(
        marketId: widget.marketId,
        presentOrderDocumentId: orderDocumentId,
        excludedCourierUids: excludedCourierUids,
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _viewModel = MarketOrdersViewModel(marketId: widget.marketId)..init();
    final oid = widget.initialOrderId;
    _searchController = TextEditingController(text: oid?.trim() ?? '');
    if (oid != null && oid.trim().isNotEmpty) {
      _viewModel.setSearchQuery(oid.trim());
    }
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  // helper methods moved to ViewModel

  @override
  void dispose() {
    _animController?.dispose();
    _searchController.dispose();
    _viewModel.disposeViewModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/HomePage');
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return CustomScrollView(
              controller: _viewModel.scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: OrderCollapsibleHeader(
                    title: "الطلبات",
                    showHeader: _viewModel.showHeader,
                    suggestions: const [],
                    searchHint: "ابحث برقم الأوردر أو اسم العميل",
                    searchController: _searchController,
                    onSearchChanged: _viewModel.setSearchQuery,
                  ),
                ),

                if (_viewModel.ordersStream != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: _viewModel.ordersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'خطأ في تحميل الطلبات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  snapshot.error.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "لا توجد طلبات حالياً",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "ستظهر الطلبات الجديدة هنا تلقائياً",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // تحويل البيانات وتصفيتها
                      final orders = snapshot.data!.docs
                          .map((doc) => _viewModel.convertOrder(doc))
                          .toList()
                        ..sort((a, b) {
                          final aTime = a['orderTime'] as DateTime?;
                          final bTime = b['orderTime'] as DateTime?;
                          if (aTime == null && bTime == null) return 0;
                          if (aTime == null) return 1;
                          if (bTime == null) return -1;
                          return bTime.compareTo(aTime); // الأحدث أولاً
                        });

                      final filteredOrders = orders.where((order) {
                        final orderId = order['id'].toString().toLowerCase();
                        final customerName = order['customerName']
                            .toString()
                            .toLowerCase();
                        return orderId.contains(
                              _viewModel.searchQuery.toLowerCase(),
                            ) ||
                            customerName.contains(
                              _viewModel.searchQuery.toLowerCase(),
                            );
                      }).toList();

                      // إحصائيات الطلبات
                      final pendingOrders = orders
                          .where((o) => o['status'] == 'قيد المراجعة')
                          .length;
                      final acceptedOrders = orders
                          .where((o) => o['status'] == 'تم استلام الطلب')
                          .length;
                      final preparingOrders = orders
                          .where((o) => o['status'] == 'جارى تسليم للدليفري' || o['status'] == 'التسليم الذاتي')
                          .length;
                      final deliveredOrders = orders
                          .where((o) => o['status'] == 'تم التسليم للطيار')
                          .length;

                      // تحقق من الطلبات التي يجب عرض dialog التقييم فيها
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _checkAndShowRatingDialogIfNeeded(orders);
                      });

                      return SliverList(
                        delegate: SliverChildListDelegate([
                          if (orders.isNotEmpty)
                            OrderStats(
                              pending: pendingOrders,
                              accepted: acceptedOrders,
                              preparing: preparingOrders,
                              delivered: deliveredOrders,
                            ),

                          // رسالة عدم وجود نتائج للبحث
                          if (filteredOrders.isEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.search_off_rounded,
                                      size: 56,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    "لا توجد طلبات مطابقة",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "لم نتمكن من العثور على طلب بهذا الرقم أو الاسم.\nيرجى التأكد من البيانات والمحاولة مرة أخرى.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // قائمة الطلبات المفلترة
                          ...filteredOrders.map((order) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _viewModel.fetchDistanceAndDurationBicycle(
                                order['id'],
                                order['customerLocation'],
                              );
                            });
                            return OrderCard(
                              order: order,
                              animController: _animController!,
                              onStatusChange: (newStatus) async {
                                final documentId =
                                    order['documentId'] as String?;
                                if (documentId == null) return;
                                await _viewModel.updateOrderStatus(
                                  context,
                                  documentId,
                                  newStatus,
                                );
                              },
                              marketLocation: _viewModel.marketLocation,
                              distanceAndDuration:
                                  _viewModel.distancesAndDurations[order['id']],
                              onRequestDelivery: (currentOrder, distanceInfo) {
                                return _handleRequestDelivery(
                                  currentOrder,
                                  distanceInfo,
                                );
                              },
                              onChangeIndependentCourier: () {
                                final independentDispatch =
                                    order['independentDispatch']
                                        as Map<String, dynamic>?;
                                final excluded =
                                    (independentDispatch?['availableCouriers']
                                                is List)
                                        ? Set<String>.from(
                                            independentDispatch!['availableCouriers']
                                                as List,
                                          )
                                        : <String>{};
                                _openIndependentCourierPicker(
                                  orderDocumentId:
                                      (order['documentId'] ?? '').toString(),
                                  excludedCourierUids: excluded,
                                );
                              },
                              onAutoRedispatchIndependentCourier: () async {
                                if (!await _ensureCourierEnabled()) return;
                                final documentId =
                                    order['documentId'] as String?;
                                if (documentId == null) return;
                                final error = await _viewModel
                                    .autoRedispatchIndependentCourier(
                                  documentId,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error ?? 'تم إعادة الإرسال للمناديب',
                                    ),
                                    backgroundColor: error != null
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                );
                              },
                              onManualRedispatchIndependentCourier: () {
                                final independentDispatch =
                                    order['independentDispatch']
                                        as Map<String, dynamic>?;
                                final courierResponses =
                                    independentDispatch?['courierResponses']
                                        as Map<String, dynamic>?;
                                final excluded = <String>{
                                  if (courierResponses != null)
                                    for (final entry
                                        in courierResponses.entries)
                                      if (const {
                                        'rejected',
                                        'released',
                                        'cancelled_by_merchant',
                                      }.contains(
                                        entry.value.toString().toLowerCase(),
                                      ))
                                        entry.key,
                                  if ((independentDispatch?['previousCourierId'] ??
                                          '')
                                      .toString()
                                      .isNotEmpty)
                                    (independentDispatch!['previousCourierId']
                                            as String)
                                        .toString(),
                                };
                                _openIndependentCourierPicker(
                                  orderDocumentId:
                                      (order['documentId'] ?? '').toString(),
                                  excludedCourierUids: excluded,
                                );
                              },
                              onCancelIndependentOrderFinal: () async {
                                final documentId =
                                    order['documentId'] as String?;
                                if (documentId == null) return;
                                await _viewModel
                                    .cancelIndependentCourierDispatch(
                                  documentId,
                                  'cancel_order',
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم إلغاء الطلب نهائياً'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              },
                              rejectedMessage: _viewModel.getRejectedMessage(
                                order['documentId'] ?? '',
                              ),
                            );
                          }),
                        ]),
                      );
                    },
                  )
                else
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    ),
    );
  }

  // stats moved to OrderStats widget
}

