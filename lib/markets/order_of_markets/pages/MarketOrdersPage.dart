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
  AnimationController? _animController;

  Future<void> _handleRequestDelivery(
    Map<String, dynamic> order,
    Map<String, String>? distanceInfo,
  ) async {
    final documentId = order['documentId'] as String?;
    if (documentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('معرف الطلب غير متوفر')));
      }
      return;
    }

    bool loadingShown = false;
    try {
      final isChangingOffice = order['status'] == 'في انتظار قبول المكتب';
      final offices = await _viewModel.fetchActiveOffices();
      if (!mounted) return;

      if (offices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد مكاتب توصيل متاحة')),
        );
        return;
      }

      final selectedOffice = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Text(
                'اختار مكتب الشحن',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 340,
                child: ListView.builder(
                  itemCount: offices.length,
                  itemBuilder: (context, index) {
                    final office = offices[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.local_shipping),
                        title: Text(office['name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (office['address'] != null)
                              Text(office['address']),
                            if (office['phone'] != null)
                              Text('هاتف: ${office['phone']}'),
                          ],
                        ),
                        onTap: () => Navigator.of(ctx).pop(office),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (selectedOffice == null) return;

      // الانتظار حتى إغلاق الـ bottom sheet بالكامل قبل فتح الـ dialog
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      final error = await _viewModel
          .sendDeliveryRequest(
            orderDocumentId: documentId,
            office: selectedOffice,
            distanceInfo: distanceInfo,
            replacePendingRequest: isChangingOffice,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => 'انتهت مهلة الطلب، حاول مرة أخرى',
          );

      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        print('❌ خطأ في إرسال الطلب: $error');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isChangingOffice
                  ? 'تم سحب الطلب من المكتب السابق وإرساله للمكتب الجديد'
                  : 'تم إرسال الطلب لمكتب الشحن بنجاح',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        print(
          isChangingOffice
              ? '✅ تم تغيير المكتب وإعادة إرسال الطلب'
              : '✅ تم إرسال الطلب بنجاح',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted && loadingShown && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
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
                          .toList();

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
                          .where((o) => o['status'] == 'جارى تسليم للدليفري')
                          .length;
                      final deliveredOrders = orders
                          .where((o) => o['status'] == 'تم التسليم للطيار')
                          .length;

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
