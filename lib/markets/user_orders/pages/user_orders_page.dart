import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/theme/app_color.dart';
import '../services/user_orders_service.dart';
import '../widgets/user_order_card.dart';
import 'package:bazar_suez/markets/order_of_markets/services/delivery_request_service.dart';

/// صفحة طلبات المستخدم السابقة
class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage> {
  final UserOrdersService _ordersService = UserOrdersService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeliveryRequestService _deliveryRequestService =
      DeliveryRequestService();

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
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _ordersService.getUserOrders(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('حدث خطأ: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد طلبات بعد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ابدأ بتصفح المتاجر واطلب الآن!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            // 🔁 الاستماع لطلبات التوصيل الخاصة بهذا المستخدم
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _deliveryRequestService.streamRequestsForCustomer(
                user.uid,
              ),
              builder: (context, deliverySnapshot) {
                final deliveryRequests = deliverySnapshot.data ?? [];

                // map: orderDocumentId -> deliveryRequest
                final Map<String, Map<String, dynamic>> deliveryByOrderId = {};
                for (final req in deliveryRequests) {
                  final orderDocumentId =
                      req['orderDocumentId'] as String? ?? '';
                  if (orderDocumentId.isEmpty) continue;
                  deliveryByOrderId[orderDocumentId] = req;
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderId = order['documentId'] as String? ?? '';

                    final deliveryInfo = deliveryByOrderId[orderId];

                    return UserOrderCard(
                      order: order,
                      orderId: orderId,
                      deliveryInfo: deliveryInfo,
                      onRatingSubmitted: () {
                        setState(() {});
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
