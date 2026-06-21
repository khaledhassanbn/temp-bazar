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

    final now = DateTime.now();
    final String currentYear = now.year.toString();
    final bool crossesYear = now.month == 1 && now.day <= 7;
    final String previousYear = (now.year - 1).toString();

    // حالة الترخيص تُشتق مباشرة من مستند المتجر المُحمّل (بدل قراءة إضافية)
    final status = LicenseStatus.fromDoc(resolvedMarketId, marketData);

    // Prepare all queries to run in parallel
    final walletBalanceFuture = _licenseService.fetchBalance(user.uid);
    final availablePackagesFuture = _pricingService.getPackages();
    final totalProductsFuture = _fetchProductsCount(resolvedMarketId);
    final ratingFuture = _fetchRating(resolvedMarketId, marketData);

    final statsDocFuture = _firestore
        .collection('markets')
        .doc(resolvedMarketId)
        .collection('statistics')
        .doc(currentYear)
        .get();

    final prevStatsDocFuture = crossesYear
        ? _firestore
            .collection('markets')
            .doc(resolvedMarketId)
            .collection('statistics')
            .doc(previousYear)
            .get()
        : Future.value(null);

    final productSalesDocFuture = _firestore
        .collection('markets')
        .doc(resolvedMarketId)
        .collection('statistics')
        .doc('product_sales')
        .get();

    // قراءة إعدادات العمولة ضمن نفس الدفعة المتوازية (كانت تسلسلية)
    final configDocFuture =
        _firestore.collection('commission_config').doc('default').get();

    // Fetch all concurrently
    final results = await Future.wait([
      walletBalanceFuture,
      availablePackagesFuture,
      totalProductsFuture,
      ratingFuture,
      statsDocFuture,
      prevStatsDocFuture,
      productSalesDocFuture,
      configDocFuture,
    ]);

    final walletBalance = results[0] as double;
    final availablePackages = results[1] as List<Package>;
    final totalProducts = results[2] as int;
    final rating = results[3] as double;
    final statsDoc = results[4] as DocumentSnapshot<Map<String, dynamic>>;
    final prevStatsDoc = results[5] as DocumentSnapshot<Map<String, dynamic>>?;
    final productSalesDoc = results[6] as DocumentSnapshot<Map<String, dynamic>>;
    final configDoc = results[7] as DocumentSnapshot<Map<String, dynamic>>;

    // 1. Calculate Monthly Revenue
    final String currentMonth = now.month.toString().padLeft(2, '0');
    double monthlyRevenue = 0.0;
    if (statsDoc.exists) {
      final monthsMap = statsDoc.data()?['months'] as Map<String, dynamic>?;
      if (monthsMap != null && monthsMap[currentMonth] != null) {
        final rawRevenue = monthsMap[currentMonth]['totalSales'];
        monthlyRevenue = rawRevenue is num
            ? rawRevenue.toDouble()
            : double.tryParse('$rawRevenue') ?? 0.0;
      }
    }

    // 2. Calculate Weekly Sales Count
    int weeklySalesCount = 0;
    final Map<String, dynamic> currentDaysMap =
        statsDoc.data()?['days'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> prevDaysMap =
        prevStatsDoc?.data()?['days'] as Map<String, dynamic>? ?? {};

    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dayKey =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      Map<String, dynamic>? dayData;
      if (day.year == now.year) {
        dayData = currentDaysMap[dayKey] as Map<String, dynamic>?;
      } else {
        dayData = prevDaysMap[dayKey] as Map<String, dynamic>?;
      }

      if (dayData != null) {
        final count = dayData['totalOrders'];
        weeklySalesCount += (count is num ? count.toInt() : 0);
      }
    }

    // 3. Extract Top Products
    List<ProductSalesPoint> topProducts = [];
    if (productSalesDoc.exists) {
      final salesMap =
          productSalesDoc.data()?['sales'] as Map<String, dynamic>? ?? {};
      final points = salesMap.entries.map((e) {
        final rawName = e.key.replaceAll('_', '.');
        final qty = e.value is num ? (e.value as num).toInt() : 0;
        return ProductSalesPoint(productName: rawName, quantity: qty);
      }).toList();

      points.sort((a, b) => b.quantity.compareTo(a.quantity));
      topProducts = points.take(5).toList();
    }

    // Fallback: If precomputed top products document is empty, query last 50 completed orders to compile it
    if (topProducts.isEmpty) {
      try {
        final fallbackOrders = await _firestore
            .collection('orders')
            .where('storeId', isEqualTo: resolvedMarketId)
            .where('isActive', isEqualTo: false)
            .limit(50)
            .get();

        final Map<String, int> fallbackQuantities = {};
        for (final doc in fallbackOrders.docs) {
          final data = doc.data();
          if (data['status'] == 'تم التسليم للطيار' ||
              data['status']?.toString().toLowerCase() == 'delivered') {
            final items = data['items'] as List<dynamic>? ?? const [];
            for (final item in items) {
              if (item is! Map<String, dynamic>) continue;
              final productName = (item['productName'] ?? 'منتج').toString().trim();
              final rawQty = item['quantity'];
              final qty = rawQty is num ? rawQty.toInt() : int.tryParse('$rawQty') ?? 0;
              fallbackQuantities[productName] = (fallbackQuantities[productName] ?? 0) + qty;
            }
          }
        }
        final points = fallbackQuantities.entries
            .map((e) => ProductSalesPoint(productName: e.key, quantity: e.value))
            .toList();
        points.sort((a, b) => b.quantity.compareTo(a.quantity));
        topProducts = points.take(5).toList();
      } catch (_) {}
    }

    final progress = _computeProgress(status);
    final isActive =
        (marketData['status'] == 'active' || marketData['status'] == null) &&
        (status.endAt == null || status.endAt!.isAfter(DateTime.now()));

    final totalCommissionsPaid = (marketData['totalCommissionsPaid'] ?? 0.0).toDouble();

    double creditLimit = -50.0;
    if (configDoc.exists) {
      creditLimit =
          (configDoc.data()?['defaultCreditLimit'] ?? -50.0).toDouble();
    }
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
    final countSnap = await _firestore
        .collection('markets')
        .doc(marketId)
        .collection('products')
        .count()
        .get();
    return countSnap.count ?? 0;
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
}
