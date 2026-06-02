import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/markets/order_of_markets/services/OrderService.dart';
import 'package:bazar_suez/markets/order_of_markets/utils/order_status_helper.dart';

class StatisticsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final OrderService _orderService;

  StatisticsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    OrderService? orderService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _orderService = orderService ?? OrderService();

  Future<String?> getCurrentUserMarketId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final snake = data['market_id'];
    final camel = data['marketId'];
    final nested = data['market'];
    if (snake is String && snake.isNotEmpty) return snake;
    if (camel is String && camel.isNotEmpty) return camel;
    if (nested is Map &&
        nested['id'] is String &&
        (nested['id'] as String).isNotEmpty) {
      return nested['id'] as String;
    }
    return null;
  }

  // ─── حساب الإحصائيات مباشرة من orders collection ───────────────────────────

  Future<void> syncCompletedOrders(String marketId) async {
    await _orderService.syncCompletedOrdersForMarket(marketId);
  }

  Map<String, double> _aggregateMonthly(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    int year,
  ) {
    final startOfYear = Timestamp.fromDate(DateTime(year, 1, 1));
    final startOfNextYear = Timestamp.fromDate(DateTime(year + 1, 1, 1));
    final Map<String, double> result = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_isCompletedOrder(data)) continue;

      final ts = _orderDateTimestamp(data);
      if (ts == null) continue;
      if (ts.compareTo(startOfYear) < 0 ||
          ts.compareTo(startOfNextYear) >= 0) {
        continue;
      }

      final date = ts.toDate();
      final monthKey = date.month.toString().padLeft(2, '0');
      final amount = _asDouble(data['totalAmount']) ?? 0.0;
      result[monthKey] = (result[monthKey] ?? 0.0) + amount;
    }
    return result;
  }

  Map<String, double> _aggregateDaily(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    int year,
    int month,
  ) {
    final startOfMonth = Timestamp.fromDate(DateTime(year, month, 1));
    final startOfNextMonth = Timestamp.fromDate(DateTime(year, month + 1, 1));
    final Map<String, double> result = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (!_isCompletedOrder(data)) continue;

      final ts = _orderDateTimestamp(data);
      if (ts == null) continue;
      if (ts.compareTo(startOfMonth) < 0 ||
          ts.compareTo(startOfNextMonth) >= 0) {
        continue;
      }

      final date = ts.toDate();
      final dayKey = date.day.toString().padLeft(2, '0');
      final amount = _asDouble(data['totalAmount']) ?? 0.0;
      result[dayKey] = (result[dayKey] ?? 0.0) + amount;
    }
    return result;
  }

  /// يجلب كل الطلبات المكتملة للمتجر في سنة معينة ويحسب الإجمالي الشهري
  Future<Map<String, double>> fetchMonthlyTotals({
    required String marketId,
    required int year,
  }) async {
    await syncCompletedOrders(marketId);

    final snapshot = await _firestore
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .get();

    return _aggregateMonthly(snapshot, year);
  }

  Stream<Map<String, double>> streamMonthlyTotals({
    required String marketId,
    required int year,
  }) {
    syncCompletedOrders(marketId);

    return _firestore
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .snapshots()
        .map((snapshot) => _aggregateMonthly(snapshot, year));
  }

  /// يجلب الإجمالي اليومي لشهر معين
  Future<Map<String, double>> fetchDailyTotals({
    required String marketId,
    required int year,
    required int month,
  }) async {
    await syncCompletedOrders(marketId);

    final snapshot = await _firestore
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .get();

    return _aggregateDaily(snapshot, year, month);
  }

  Stream<Map<String, double>> streamDailyTotals({
    required String marketId,
    required int year,
    required int month,
  }) {
    syncCompletedOrders(marketId);

    return _firestore
        .collection('orders')
        .where('storeId', isEqualTo: marketId)
        .snapshots()
        .map((snapshot) => _aggregateDaily(snapshot, year, month));
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  Timestamp? _orderDateTimestamp(Map<String, dynamic> data) {
    final completedAt = data['completedAt'];
    if (completedAt is Timestamp) return completedAt;

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt;

    return null;
  }

  /// الطلبات المكتملة فقط تُحسب في الإحصائيات
  bool _isCompletedOrder(Map<String, dynamic> data) {
    return OrderStatusHelper.isDelivered(data);
  }

  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
