import 'dart:ui' as ui;

import 'package:bazar_suez/markets/wallet/models/wallet_transaction_model.dart';
import 'package:bazar_suez/markets/wallet/services/wallet_service.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../license/services/license_service.dart';
import '../../license/models/license_status.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WalletService _walletService = WalletService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LicenseService _licenseService = LicenseService();
  double _balance = 0.0;
  bool _isLoading = true;
  LicenseStatus? _licenseStatus;
  String? _marketId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final balance = await _walletService.getWalletBalance(user.uid);
      final marketId = await _licenseService.resolveCurrentUserMarketId();
      LicenseStatus? license;
      if (marketId != null) {
        try {
          license = await _licenseService.fetchStatus(marketId);
        } catch (_) {}
      }
      setState(() {
        _balance = balance;
        _isLoading = false;
        _licenseStatus = license;
        _marketId = marketId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول')));
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.mainColor),
            onPressed: () {
              if (Navigator.canPop(context)) {
                context.pop();
              } else {
                context.go('/AccountPage');
              }
            },
          ),
          title: const Text(
            'المحفظة',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.mainColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Balance Card
                _buildBalanceCard(),
                const SizedBox(height: 24),
                // Charge Button
                _buildChargeButton(),
                const SizedBox(height: 16),
                _buildLicenseCard(),
                const SizedBox(height: 24),
                // Transactions Section
                const Text(
                  'العمليات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                // Transactions List
                _buildTransactionsList(user.uid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.mainColor, AppColors.mainColor.withOpacity(0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.mainColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'الرصيد المتاح',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const CircularProgressIndicator(color: Colors.white)
          else
            Text(
              '${_balance.toStringAsFixed(2)} جنيه',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChargeButton() {
    return ElevatedButton(
      onPressed: () async {
        final result = await context.push('/deposit-request');
        if (result == true) {
          _loadData();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.mainColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text(
        'شحن المحفظة',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLicenseCard() {
    if (_marketId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: AppColors.mainColor),
              const SizedBox(width: 8),
              const Text(
                'ترخيص المتجر',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    context.go('/license-status?marketId=$_marketId'),
                child: const Text('التفاصيل'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _licenseStatus == null
                ? 'جارِ تحميل حالة الترخيص...'
                : 'أيام متبقية: ${_licenseStatus!.remainingDays}',
            style: const TextStyle(color: Color(0xFF4B5563)),
          ),
          if (_licenseStatus != null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('التجديد التلقائي'),
              value: _licenseStatus!.autoRenewEnabled,
              activeColor: AppColors.mainColor,
              onChanged: (value) async {
                await _licenseService.toggleAutoRenew(
                  marketId: _marketId!,
                  enabled: value,
                );
                await _loadData();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsList(String userId) {
    return StreamBuilder<List<WalletTransaction>>(
      stream: _walletService.getUserTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('خطأ في تحميل العمليات: ${snapshot.error}'),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'لا توجد عمليات حتى الآن',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
              ),
            ),
          );
        }

        return Column(
          children: transactions.map((transaction) {
            return _buildTransactionCard(transaction);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTransactionCard(WalletTransaction transaction) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (transaction.status) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'تم الموافقة';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'تم الرفض';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${transaction.amount.toStringAsFixed(2)} جنيه',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'yyyy/MM/dd - HH:mm',
                    'ar',
                  ).format(transaction.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
