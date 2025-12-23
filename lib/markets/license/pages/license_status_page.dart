import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_color.dart';
import '../models/license_status.dart';
import '../services/license_service.dart';

class LicenseStatusPage extends StatefulWidget {
  final String? marketId;
  const LicenseStatusPage({super.key, this.marketId});

  @override
  State<LicenseStatusPage> createState() => _LicenseStatusPageState();
}

class _LicenseStatusPageState extends State<LicenseStatusPage> {
  final LicenseService _licenseService = LicenseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LicenseStatus? _status;
  double _balance = 0;
  bool _loading = true;
  String? _marketId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final resolvedId =
        widget.marketId ?? await _licenseService.resolveCurrentUserMarketId();
    if (resolvedId == null || resolvedId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final status = await _licenseService.fetchStatus(resolvedId);
    final balance = await _licenseService.fetchBalance(user.uid);

    if (!mounted) return;
    setState(() {
      _marketId = resolvedId;
      _status = status;
      _balance = balance;
      _loading = false;
    });
  }

  Future<void> _toggleAutoRenew(bool value) async {
    if (_marketId == null) return;
    await _licenseService.toggleAutoRenew(marketId: _marketId!, enabled: value);
    await _load();
  }

  Future<void> _confirmAndDeleteStore() async {
    if (_marketId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المتجر'),
        content: const Text(
          'سيتم حذف المتجر وجميع المنتجات ولن يمكنك استرجاع الترخيص. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
            ),
            child: const Text('حذف المتجر'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _licenseService.deleteStore(_marketId!);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف المتجر بنجاح')));
      context.go('/HomePage');
    } catch (e) {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر الحذف: $e')));
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return DateFormat('yyyy/MM/dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ترخيص المتجر'),
          backgroundColor: AppColors.mainColor,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _status == null
            ? const Center(child: Text('لم يتم العثور على متجر مرتبط بالحساب'))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _InfoCard(
                      title: 'الأيام المتبقية',
                      value: '${_status!.remainingDays} يوم',
                      icon: Icons.timer,
                      color: Colors.blue.shade50,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'تاريخ الانتهاء',
                      value: _formatDate(_status!.endAt),
                      icon: Icons.event,
                      color: Colors.orange.shade50,
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      title: 'الرصيد المتاح بالمحفظة',
                      value: '${_balance.toStringAsFixed(2)} جنيه',
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.green.shade50,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('تفعيل التجديد التلقائي'),
                      subtitle: const Text(
                        'سيتم خصم قيمة الباقة تلقائياً عند توفر رصيد قبل انتهاء الترخيص',
                      ),
                      value: _status!.autoRenewEnabled,
                      onChanged: _toggleAutoRenew,
                      activeColor: AppColors.mainColor,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _marketId == null
                          ? null
                          : () =>
                                context.go('/pricingpage?marketId=$_marketId'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.upgrade),
                      label: const Text(
                        'تجديد / تغيير الباقة',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/wallet'),
                      child: const Text('شحن المحفظة'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _marketId == null
                          ? null
                          : _confirmAndDeleteStore,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text(
                        'حذف المتجر',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.mainColor.withOpacity(0.1),
            child: Icon(icon, color: AppColors.mainColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
