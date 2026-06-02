import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/markets/order_of_markets/utils/order_status_helper.dart';
import '../services/user_orders_service.dart';
import '../widgets/user_order_card.dart';

enum _OrdersFilter { all, active, completed }

/// صفحة طلبات المستخدم
class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage>
    with SingleTickerProviderStateMixin {
  final UserOrdersService _ordersService = UserOrdersService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  _OrdersFilter _filter = _OrdersFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _filter = _OrdersFilter.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> orders) {
    switch (_filter) {
      case _OrdersFilter.active:
        return orders
            .where((o) => OrderStatusHelper.isActiveOrder(o))
            .toList();
      case _OrdersFilter.completed:
        return orders
            .where((o) => OrderStatusHelper.isDelivered(o))
            .toList();
      case _OrdersFilter.all:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('طلباتك'), centerTitle: true),
        body: const Center(child: Text('يجب تسجيل الدخول لعرض طلباتك')),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'طلباتك',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.mainColor),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.mainColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.mainColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'جارية'),
              Tab(text: 'مكتملة'),
            ],
          ),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _ordersService.getUserOrders(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorView(
                message: snapshot.error.toString(),
                onRetry: () => setState(() {}),
              );
            }

            final allOrders = snapshot.data ?? [];
            final orders = _filterOrders(allOrders);

            if (allOrders.isEmpty) {
              return _EmptyView(
                title: 'لا توجد طلبات بعد',
                subtitle: 'ابدأ بتصفح المتاجر واطلب الآن!',
              );
            }

            if (orders.isEmpty) {
              return _EmptyView(
                title: _filter == _OrdersFilter.active
                    ? 'لا توجد طلبات جارية'
                    : 'لا توجد طلبات مكتملة',
                subtitle: _filter == _OrdersFilter.active
                    ? 'ستظهر طلباتك الجارية هنا'
                    : 'ستظهر طلباتك المكتملة هنا بعد التوصيل',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              color: AppColors.mainColor,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final orderId = order['documentId'] as String? ?? '';
                  final deliveryInfo =
                      order['deliveryRequest'] as Map<String, dynamic>?;

                  return UserOrderCard(
                    order: order,
                    orderId: orderId,
                    deliveryInfo: deliveryInfo,
                    onRatingSubmitted: () => setState(() {}),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'حدث خطأ في تحميل الطلبات',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
