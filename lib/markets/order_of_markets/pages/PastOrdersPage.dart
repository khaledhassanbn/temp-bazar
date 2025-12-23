import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bazar_suez/markets/order_of_markets/widget/OrderCollapsibleHeader.dart';
import 'package:bazar_suez/markets/order_of_markets/widget/OrderCardWithoutActions.dart';
import 'package:bazar_suez/markets/order_of_markets/viewmodels/PastOrdersViewModel.dart';

class PastOrdersPage extends StatefulWidget {
  final String marketId;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;

  const PastOrdersPage({
    super.key,
    required this.marketId,
    this.filterStartDate,
    this.filterEndDate,
  });

  @override
  State<PastOrdersPage> createState() => _PastOrdersPageState();
}

class _PastOrdersPageState extends State<PastOrdersPage>
    with SingleTickerProviderStateMixin {
  late final PastOrdersViewModel _viewModel;
  AnimationController? _animController;

  @override
  void initState() {
    super.initState();
    _viewModel = PastOrdersViewModel(
      marketId: widget.marketId,
      filterStartDate: widget.filterStartDate,
      filterEndDate: widget.filterEndDate,
    )..init();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController?.dispose();
    _viewModel.disposeViewModel();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _viewModel.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar', 'EG'),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('ar', 'EG'),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _viewModel.selectedDate) {
      _viewModel.setSelectedDate(picked);
    }
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
                    title: "الطلبات السابقة",
                    showHeader: _viewModel.showHeader,
                    suggestions: const [],
                    searchHint: "ابحث برقم الأوردر أو اسم العميل",
                    onSearchChanged: _viewModel.setSearchQuery,
                  ),
                ),

                // Date Filter
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _viewModel.selectedDate != null
                                          ? '${_viewModel.selectedDate!.year}/${_viewModel.selectedDate!.month.toString().padLeft(2, '0')}/${_viewModel.selectedDate!.day.toString().padLeft(2, '0')}'
                                          : 'اختر تاريخ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _viewModel.selectedDate != null
                                            ? Colors.black87
                                            : Colors.grey[600],
                                        fontWeight:
                                            _viewModel.selectedDate != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_viewModel.selectedDate != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              _viewModel.setSelectedDate(null);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.clear,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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
                                  "ستظهر الطلبات السابقة هنا",
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

                      // Sort by createdAt descending (newest first)
                      orders.sort((a, b) {
                        // استخدام createdAt للفرز
                        DateTime aTime;
                        DateTime bTime;

                        if (a['createdAt'] != null) {
                          final aTimestamp = a['createdAt'] as Timestamp;
                          aTime = aTimestamp.toDate();
                        } else {
                          aTime = a['orderTime'] as DateTime;
                        }

                        if (b['createdAt'] != null) {
                          final bTimestamp = b['createdAt'] as Timestamp;
                          bTime = bTimestamp.toDate();
                        } else {
                          bTime = b['orderTime'] as DateTime;
                        }

                        return bTime.compareTo(aTime);
                      });

                      // Filter by date if selected
                      final dateFilteredOrders = orders.where((order) {
                        return _viewModel.isOrderOnSelectedDate(order);
                      }).toList();

                      // Filter by search query
                      final filteredOrders = dateFilteredOrders.where((order) {
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

                      return SliverList(
                        delegate: SliverChildListDelegate([
                          // رسالة عدم وجود نتائج للبحث أو الفلترة بالتاريخ
                          if (filteredOrders.isEmpty)
                            Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.search_off,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _viewModel.selectedDate != null
                                          ? "لا توجد طلبات في هذا التاريخ"
                                          : "لا توجد طلبات مطابقة للبحث",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _viewModel.selectedDate != null
                                          ? "جرب اختيار تاريخ آخر أو احذف الفلترة"
                                          : "جرب البحث برقم الطلب أو اسم العميل",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
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
                            return OrderCardWithoutActions(
                              order: order,
                              animController: _animController!,
                              marketLocation: _viewModel.marketLocation,
                              distanceAndDuration:
                                  _viewModel.distancesAndDurations[order['id']],
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
}
