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

import 'package:bazar_suez/markets/order_of_markets/widget/OrderCollapsibleHeader.dart';
import 'package:bazar_suez/markets/order_of_markets/widget/OrderCard.dart';
import 'package:bazar_suez/markets/order_of_markets/widget/OrderStats.dart';
import 'package:bazar_suez/markets/order_of_markets/viewmodels/MarketOrdersViewModel.dart';

class MarketOrdersPage extends StatefulWidget {
  final String marketId;
  const MarketOrdersPage({super.key, required this.marketId});

  @override
  State<MarketOrdersPage> createState() => _MarketOrdersPageState();
}

class _MarketOrdersPageState extends State<MarketOrdersPage>
    with SingleTickerProviderStateMixin {
  late final MarketOrdersViewModel _viewModel;
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

    try {
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
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final error = await _viewModel.sendDeliveryRequest(
        orderDocumentId: documentId,
        office: selectedOffice,
        distanceInfo: distanceInfo,
      );

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // close loading
      }

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
          const SnackBar(
            content: Text('تم إرسال الطلب لمكتب الشحن بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        print('✅ تم إرسال الطلب بنجاح');
      }
    } catch (e) {
      // إغلاق loading dialog في حالة الخطأ
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = MarketOrdersViewModel(marketId: widget.marketId)..init();
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
    _viewModel.disposeViewModel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
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
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "لا توجد طلبات مطابقة للبحث",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "جرب البحث برقم الطلب أو اسم العميل",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
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
                              rejectedMessage: _viewModel.getRejectedMessage(order['documentId'] ?? ''),
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
    );
  }

  // stats moved to OrderStats widget
}
