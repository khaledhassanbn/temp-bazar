import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../license/models/license_status.dart';
import '../../license/services/license_service.dart';
import '../../planes/models/package.dart';
import '../../planes/services/pricing_service.dart';
import '../models/dashboard_market_model.dart';

class DashboardMarketService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LicenseService _licenseService;
  final PricingService _pricingService;

  DashboardMarketService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    LicenseService? licenseService,
    PricingService? pricingService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _licenseService = licenseService ?? LicenseService(),
       _pricingService = pricingService ?? PricingService();

  Future<DashboardMarketModel> loadDashboard({String? marketId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final resolvedMarketId =
        marketId ?? await _licenseService.resolveCurrentUserMarketId();
    if (resolvedMarketId == null || resolvedMarketId.isEmpty) {
      throw Exception('لا يوجد متجر مرتبط بالحساب');
    }

    final marketDoc = await _firestore
        .collection('markets')
        .doc(resolvedMarketId)
        .get();
    final marketData = marketDoc.data() ?? <String, dynamic>{};

    final status = await _licenseService.fetchStatus(resolvedMarketId);
    final walletBalance = await _licenseService.fetchBalance(user.uid);
    final availablePackages = await _pricingService.getPackages();

    final totalProducts = await _fetchProductsCount(resolvedMarketId);
    final weeklySalesCount = await _fetchWeeklySalesCount(resolvedMarketId);
    final monthlyRevenue = await _fetchMonthlyRevenue(resolvedMarketId);
    final topProducts = await _fetchTopProducts(resolvedMarketId);
    final rating = await _fetchRating(resolvedMarketId, marketData);

    final progress = _computeProgress(status);
    final isActive =
        (marketData['status'] == 'active' || marketData['status'] == null) &&
        (status.endAt == null || status.endAt!.isAfter(DateTime.now()));

    final totalCommissionsPaid = (marketData['totalCommissionsPaid'] ?? 0.0).toDouble();

    double creditLimit = -50.0;
    try {
      final configDoc = await _firestore.collection('commission_config').doc('default').get();
      if (configDoc.exists) {
        creditLimit = (configDoc.data()?['defaultCreditLimit'] ?? -50.0).toDouble();
      }
    } catch (_) {}
    if (marketData['creditLimit'] != null) {
      creditLimit = (marketData['creditLimit'] as num).toDouble();
    }

    final isNearCreditLimit = walletBalance <= creditLimit + 20.0;

    return DashboardMarketModel(
      marketId: resolvedMarketId,
      currentPackageName: status.currentPackageName ?? 'باقة غير محددة',
      packageStartAt: status.startAt,
      packageEndAt: status.endAt,
      remainingDays: status.remainingDays,
      packageProgress: progress,
      isPackageActive: isActive,
      walletBalance: walletBalance,
      totalCommissionsPaid: totalCommissionsPaid,
      creditLimit: creditLimit,
      isNearCreditLimit: isNearCreditLimit,
      totalProducts: totalProducts,
      weeklySalesCount: weeklySalesCount,
      monthlyRevenue: monthlyRevenue,
      rating: rating,
      topProducts: topProducts,
      availablePackages: availablePackages,
    );
  }

  Future<int> _fetchProductsCount(String marketId) async {
    final products = await _firestore
        .collection('markets')
        .doc(marketId)
        .collection('products')
        .get();
    return products.docs.length;
  }

  Future<int> _fetchWeeklySalesCount(String marketId) async {
    final from = DateTime.now().subtract(const Duration(days: 7));
    final docs = await _firestore
        .collection('markets')
        .doc(marketId)
        .collection('past_order')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .get();

    return docs.docs.where(_isDeliveredOrder).length;
  }

  Future<double> _fetchMonthlyRevenue(String marketId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = now.month == 12
        ? DateTime(now.year + 1, 1, 1)
        : DateTime(now.year, now.month + 1, 1);

    final docs = await _firestore
        .collection('markets')
        .doc(marketId)
        .collection('past_order')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    double total = 0;
    for (final doc in docs.docs) {
      final data = doc.data();
      if (!_isDeliveredOrderDoc(data)) continue;
      final raw = data['totalAmount'];
      total += raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    }
    return total;
  }

  Future<List<ProductSalesPoint>> _fetchTopProducts(String marketId) async {
    final docs = await _firestore
        .collection('markets')
        .doc(marketId)
        .collection('past_order')
        .get();

    final Map<String, int> quantities = {};
    for (final doc in docs.docs) {
      final data = doc.data();
      if (!_isDeliveredOrderDoc(data)) continue;
      final items = data['items'] as List<dynamic>? ?? const [];
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final productName = (item['productName'] ?? 'منتج').toString().trim();
        final rawQty = item['quantity'];
        final qty = rawQty is num
            ? rawQty.toInt()
            : int.tryParse('$rawQty') ?? 0;
        quantities[productName] = (quantities[productName] ?? 0) + qty;
      }
    }

    final points =
        quantities.entries
            .map(
              (e) => ProductSalesPoint(productName: e.key, quantity: e.value),
            )
            .toList()
          ..sort((a, b) => b.quantity.compareTo(a.quantity));

    return points.take(5).toList();
  }

  Future<double> _fetchRating(
    String marketId,
    Map<String, dynamic> marketData,
  ) async {
    final ratingDoc = await _firestore
        .collection('markets')
        .doc(marketId)
        .collection('statistics')
        .doc('rating')
        .get();

    if (ratingDoc.exists) {
      final stats = ratingDoc.data() ?? {};
      final raw = stats['averageRating'];
      return raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    }

    final marketRaw = marketData['averageRating'];
    return marketRaw is num
        ? marketRaw.toDouble()
        : double.tryParse('$marketRaw') ?? 0;
  }

  double _computeProgress(LicenseStatus status) {
    final start = status.startAt;
    final end = status.endAt;
    if (start == null || end == null || !end.isAfter(start)) return 0;

    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    final percent = elapsed / total;
    return percent.clamp(0, 1).toDouble();
  }

  bool _isDeliveredOrder(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _isDeliveredOrderDoc(doc.data());
  }

  bool _isDeliveredOrderDoc(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    return status == 'تم التسليم للطيار' || status.toLowerCase() == 'delivered';
  }
}
