import '../../planes/models/package.dart';

class DashboardMarketModel {
  final String marketId;
  final String currentPackageName;
  final DateTime? packageStartAt;
  final DateTime? packageEndAt;
  final int remainingDays;
  final double packageProgress;
  final bool isPackageActive;
  final double walletBalance;
  final double totalCommissionsPaid;
  final double creditLimit;
  final bool isNearCreditLimit;
  final int totalProducts;
  final int weeklySalesCount;
  final double monthlyRevenue;
  final double rating;
  final List<ProductSalesPoint> topProducts;
  final List<Package> availablePackages;

  const DashboardMarketModel({
    required this.marketId,
    required this.currentPackageName,
    required this.packageStartAt,
    required this.packageEndAt,
    required this.remainingDays,
    required this.packageProgress,
    required this.isPackageActive,
    required this.walletBalance,
    required this.totalCommissionsPaid,
    required this.creditLimit,
    required this.isNearCreditLimit,
    required this.totalProducts,
    required this.weeklySalesCount,
    required this.monthlyRevenue,
    required this.rating,
    required this.topProducts,
    required this.availablePackages,
  });
}

class ProductSalesPoint {
  final String productName;
  final int quantity;

  const ProductSalesPoint({required this.productName, required this.quantity});
}
