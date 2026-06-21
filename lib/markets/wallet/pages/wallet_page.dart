import 'dart:async';
import 'dart:ui' as ui;

import 'package:bazar_suez/markets/wallet/models/wallet_transaction_model.dart';
import 'package:bazar_suez/markets/wallet/models/wallet_ledger_model.dart';
import 'package:bazar_suez/markets/wallet/services/wallet_service.dart';
import 'package:bazar_suez/markets/wallet/services/wallet_notification_service.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  double _creditLimit = -50.0;
  String? _alertMessage;
  bool _isLoading = true;
  LicenseStatus? _licenseStatus;
  String? _marketId;
  bool _showLedger = true;

  // اشتراك لحظي على مستند المتجر (لتحديث الحد الائتماني والترخيص تلقائياً)
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _marketSub;
  // منع الضغط المتكرر على زر التجديد التلقائي + تحديث متفائل
  bool _isTogglingAutoRenew = false;
  bool? _autoRenewOptimistic;

  @override
  void initState() {
    super.initState();
    WalletNotificationService.resetForNewBalance();
    _loadData();
  }

  @override
  void dispose() {
    _marketSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final balance = await _walletService.getWalletBalance(user.uid);
    final marketId = await _licenseService.resolveCurrentUserMarketId();
    if (!mounted) return;

    setState(() {
      _balance = balance;
      _marketId = marketId;
      _isLoading = false;
      _alertMessage = WalletNotificationService.checkBalanceAndNotify(
        balance,
        _creditLimit,
      );
    });

    if (marketId != null) {
      _subscribeToMarket(marketId);
    }
  }

  /// اشتراك لحظي على مستند المتجر: الحد الائتماني + حالة الترخيص يتحدثان فور
  /// أي تعديل من تطبيق الأدمن.
  void _subscribeToMarket(String marketId) {
    _marketSub?.cancel();
    _marketSub = FirebaseFirestore.instance
        .collection('markets')
        .doc(marketId)
        .snapshots()
        .listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data();
      if (data == null) return;

      double creditLimit = _creditLimit;
      if (data['creditLimit'] != null) {
        creditLimit = (data['creditLimit'] as num).toDouble();
      }
      final license = LicenseStatus.fromDoc(marketId, data);

      setState(() {
        _creditLimit = creditLimit;
        _licenseStatus = license;
        // إلغاء التحديث المتفائل بمجرد تأكيد القيمة من المصدر
        if (_autoRenewOptimistic != null &&
            _autoRenewOptimistic == license.autoRenewEnabled) {
          _autoRenewOptimistic = null;
        }
      });
    });
  }

  void _showCreditLimitInfo() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.info_outline, color: AppColors.mainColor),
              SizedBox(width: 8),
              Text('ما هو الحد الائتماني؟'),
            ],
          ),
          content: const Text(
            'الحد الائتماني هو المبلغ المسموح للتاجر أن يكون مديناً به للنظام '
            'قبل إيقاف بعض الخدمات أو منع استقبال طلبات جديدة حسب سياسة التطبيق.\n\n'
            'مثال: إذا كان الحد الائتماني -50 جنيه، يمكن أن يصل رصيدك إلى -50 '
            'جنيه قبل أن يتوقف استقبال الطلبات الجديدة. يُرجى شحن المحفظة قبل '
            'الوصول إلى الحد لتجنّب توقف الخدمة.',
            style: TextStyle(height: 1.6, color: Color(0xFF374151)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      ),
    );
  }

  /// تبديل التجديد التلقائي: يمنع الضغط المتكرر، يحدّث الحالة فوراً (متفائل)،
  /// ويكتفي باستدعاء toggleAutoRenew دون إعادة تحميل كاملة (الـ stream يؤكد القيمة).
  Future<void> _onToggleAutoRenew(bool value) async {
    if (_isTogglingAutoRenew || _marketId == null) return;

    setState(() {
      _isTogglingAutoRenew = true;
      _autoRenewOptimistic = value;
    });

    try {
      await _licenseService.toggleAutoRenew(
        marketId: _marketId!,
        enabled: value,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'تم تفعيل التجديد التلقائي' : 'تم إيقاف التجديد التلقائي',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // التراجع عند الفشل
      setState(() => _autoRenewOptimistic = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر تحديث التجديد التلقائي: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingAutoRenew = false);
      }
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
                // Alert Banner
                _buildAlertBanner(),
                // Balance Card
                _buildBalanceCard(),
                const SizedBox(height: 24),
                // Charge Button
                _buildChargeButton(),
                const SizedBox(height: 16),
                _buildLicenseCard(),
                const SizedBox(height: 24),
                // Tab selector
                _buildTabSelector(),
                const SizedBox(height: 24),
                // Title
                Text(
                  _showLedger
                      ? 'سجل العمليات الموحد'
                      : 'طلبات الشحن المعلقة والسابقة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                // Content List
                _showLedger
                    ? _buildLedgerList(user.uid)
                    : _buildTransactionsList(user.uid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    if (_alertMessage == null) return const SizedBox.shrink();

    final isExceeded = _balance <= _creditLimit;
    final bannerColor = isExceeded ? Colors.red.shade50 : Colors.orange.shade50;
    final borderColor = isExceeded
        ? Colors.red.shade200
        : Colors.orange.shade200;
    final textColor = isExceeded ? Colors.red.shade800 : Colors.orange.shade800;
    final icon = isExceeded
        ? Icons.error_outline
        : Icons.warning_amber_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _alertMessage!,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showLedger = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _showLedger ? AppColors.mainColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'سجل العمليات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _showLedger ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showLedger = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_showLedger
                      ? AppColors.mainColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'طلبات الشحن',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_showLedger
                        ? Colors.white
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
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
            'الرصيد الفعلي للمحفظة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const CircularProgressIndicator(color: Colors.white)
          else ...[
            Text(
              '${_balance.toStringAsFixed(2)} جنيه',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _showCreditLimitInfo,
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'الحد الائتماني: ${_creditLimit.toStringAsFixed(2)} جنيه',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLedgerList(String userId) {
    return StreamBuilder<List<WalletLedgerEntry>>(
      stream: _walletService.getWalletLedger(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'خطأ في تحميل السجل: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: const Center(
              child: Text(
                'لا توجد عمليات مسجلة حتى الآن',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
              ),
            ),
          );
        }

        return Column(
          children: entries.map((entry) {
            return _buildLedgerCard(entry);
          }).toList(),
        );
      },
    );
  }

  Widget _buildLedgerCard(WalletLedgerEntry entry) {
    Color typeColor;
    IconData typeIcon;
    String typeText = WalletLedgerType.arabicName(entry.type);

    switch (entry.type) {
      case WalletLedgerType.walletRecharge:
        typeColor = Colors.green;
        typeIcon = Icons.add_circle_outline;
        break;
      case WalletLedgerType.orderCommission:
        typeColor = Colors.red;
        typeIcon = Icons.receipt_long_outlined;
        break;
      case WalletLedgerType.subscriptionPayment:
        typeColor = Colors.blue;
        typeIcon = Icons.card_membership_outlined;
        break;
      case WalletLedgerType.manualAdjustment:
        typeColor = Colors.orange;
        typeIcon = Icons.tune_outlined;
        break;
      case WalletLedgerType.refund:
        typeColor = Colors.teal;
        typeIcon = Icons.history_outlined;
        break;
      case WalletLedgerType.autoRenewal:
        typeColor = Colors.purple;
        typeIcon = Icons.autorenew_outlined;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help_outline;
    }

    final isDebit = entry.amount < 0;
    final amountText =
        '${isDebit ? "" : "+"}${entry.amount.toStringAsFixed(2)} جنيه';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description.isNotEmpty ? entry.description : typeText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'yyyy/MM/dd - HH:mm',
                    'ar',
                  ).format(entry.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'قبل: ${entry.balanceBefore.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              Text(
                'بعد: ${entry.balanceAfter.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
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
              secondary: _isTogglingAutoRenew
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              value: _autoRenewOptimistic ?? _licenseStatus!.autoRenewEnabled,
              activeColor: AppColors.mainColor,
              onChanged: _isTogglingAutoRenew
                  ? null
                  : (value) => _onToggleAutoRenew(value),
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
