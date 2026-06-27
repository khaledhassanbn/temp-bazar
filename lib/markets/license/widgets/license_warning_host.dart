import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/markets/license/services/license_service.dart';
import 'package:bazar_suez/theme/app_color.dart';

/// يعرض رسالة تحذيرية عند فتح التطبيق لصاحب المتجر
/// إذا كان الترخيص منتهياً أو يتبقى 5 أيام أو أقل.
class LicenseWarningHost extends StatefulWidget {
  const LicenseWarningHost({super.key});

  @override
  State<LicenseWarningHost> createState() => _LicenseWarningHostState();
}

class _LicenseWarningHostState extends State<LicenseWarningHost> {
  static const int _warningDays = 5;

  late final AuthGuard _auth;
  final LicenseService _licenseService = LicenseService();

  String? _lastLocation;
  String? _sessionUid;
  bool _shownThisSession = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthGuard>();
    _auth.addListener(_onAuthChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthChanged());
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  bool _isEligibleLocation(String? location) {
    if (location == null || location.isEmpty) return false;
    if (location.startsWith('/HomePage')) return true;
    if (location.startsWith('/myorder')) return true;
    if (location.startsWith('/PastOrders')) return true;
    if (location.startsWith('/addproduct')) return true;
    if (location.startsWith('/MyStorePage')) return true;
    if (location.startsWith('/ManageProducts')) return true;
    if (location.startsWith('/SalesStatsPage')) return true;
    if (location.startsWith('/AccountPage')) return true;
    if (location.startsWith('/pricingpage')) return true;
    if (location.startsWith('/edit-store')) return true;
    if (location.startsWith('/market-dashboard')) return true;
    if (location.startsWith('/license-status')) return true;
    if (location.startsWith('/wallet')) return true;
    return false;
  }

  Future<void> _onAuthChanged() async {
    if (_busy || !mounted) return;

    final location = _lastLocation;
    final uid = _auth.currentUser?.uid;

    if (uid == null || !_auth.isMarketOwner) {
      _sessionUid = null;
      _shownThisSession = false;
      return;
    }

    if (_sessionUid != uid) {
      _sessionUid = uid;
      _shownThisSession = false;
    }

    if (!_isEligibleLocation(location) || _shownThisSession) return;

    final marketId = _auth.marketId;
    if (marketId == null || marketId.isEmpty) return;

    _busy = true;
    try {
      final status = await _licenseService.fetchStatus(marketId);
      final balance = await _licenseService.fetchBalance(uid);

      final marketSnap =
          await FirebaseFirestore.instance.collection('markets').doc(marketId).get();
      final marketData = marketSnap.data() ?? {};
      final failedReason =
          marketData['licenseRenewalFailedReason'] as String?;

      final endAt = status.endAt;
      final isExpired =
          endAt == null || DateTime.now().isAfter(endAt);
      final shouldWarn =
          isExpired || (!isExpired && status.remainingDays <= _warningDays);

      if (!shouldWarn || !mounted) return;

      _shownThisSession = true;
      await _showWarningDialog(
        isExpired: isExpired,
        remainingDays: status.remainingDays,
        packageName: status.fallbackPackageName,
        balance: balance,
        failedReason: failedReason,
      );
    } catch (_) {
      // لا نعطل التطبيق إذا فشل التحميل
    } finally {
      _busy = false;
    }
  }

  Future<void> _showWarningDialog({
    required bool isExpired,
    required int remainingDays,
    required String packageName,
    required double balance,
    String? failedReason,
  }) async {
    if (!mounted) return;

    final title = isExpired ? 'انتهى ترخيص متجرك' : 'اقترب موعد انتهاء الترخيص';

    String body;
    if (isExpired) {
      body =
          'انتهى ترخيص باقة "$packageName". لن يظهر متجرك للعملاء حتى يتم التجديد.';
    } else if (remainingDays == 0) {
      body = 'ينتهي ترخيص باقة "$packageName" اليوم.';
    } else if (remainingDays == 1) {
      body = 'يتبقى يوم واحد على انتهاء باقة "$packageName".';
    } else {
      body = 'يتبقى $remainingDays أيام على انتهاء باقة "$packageName".';
    }

    final autoRenewNote =
        'التجديد التلقائي مفعّل دائماً وسيتم خصم قيمة الباقة من محفظتك عند توفر رصيد كافٍ.';

    final balanceNote =
        'رصيد المحفظة الحالي: ${balance.toStringAsFixed(2)} ج.م';

    final failedNote = failedReason == 'insufficient_balance'
        ? '\n\nتعذّر التجديد التلقائي لعدم كفاية الرصيد. يرجى شحن المحفظة الآن.'
        : '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isExpired ? Icons.error_outline : Icons.warning_amber_rounded,
                color: isExpired ? Colors.red : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              '$body\n\n$autoRenewNote\n$balanceNote$failedNote',
              style: const TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('تم'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) context.go('/license-status');
              },
              child: const Text('تجديد الآن'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) context.go('/wallet');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('شحن المحفظة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (_lastLocation != location) {
      _lastLocation = location;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthChanged());
    }
    return const SizedBox.shrink();
  }
}
