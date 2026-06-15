import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/admin/services/admin_account_service.dart';
import 'package:bazar_suez/admin/security/services/deleted_accounts_service.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/theme/app_color.dart';

class DeletedAccountsPage extends StatelessWidget {
  const DeletedAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DeletedAccountsService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('الحسابات المحذوفة'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DeletedAccountModel>>(
        stream: service.watchDeletedAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }

          final accounts = snapshot.data ?? [];
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد حسابات محذوفة',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _DeletedAccountCard(account: accounts[index]),
          );
        },
      ),
    );
  }
}

class _DeletedAccountCard extends StatelessWidget {
  const _DeletedAccountCard({required this.account});

  final DeletedAccountModel account;

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}/${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthGuard>();
    final accountService = AdminAccountService();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade50,
                  child: Icon(Icons.person_off_outlined, color: Colors.red.shade400),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (account.email != null)
                        Text(account.email!, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    _accountTypeLabel(account.accountType),
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'حُذف في: ${_formatDate(account.deletedAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('استعادة الحساب'),
                        content: Text(
                          'هل تريد استعادة حساب ${account.displayName}؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('إلغاء'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('استعادة'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true || !context.mounted) return;

                    try {
                      // استخدام الخدمة المحلية بدلاً من Cloud Function
                      await accountService.restoreAccount(
                        accountId: account.uid,
                        accountType: account.accountType ?? 'craftsman',
                        adminId: auth.currentUser!.uid,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تمت استعادة الحساب بنجاح')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('خطأ: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('استعادة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _accountTypeLabel(String? type) {
    switch (type) {
      case 'craftsman':
        return 'صنايعي';
      case 'store':
        return 'متجر';
      case 'courier':
        return 'مندوب';
      default:
        return 'مستخدم';
    }
  }
}
