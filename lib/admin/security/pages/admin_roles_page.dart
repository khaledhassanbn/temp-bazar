import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/admin/security/models/admin_permission.dart';
import 'package:bazar_suez/admin/security/models/admin_role.dart';
import 'package:bazar_suez/admin/security/models/admin_role_model.dart';
import 'package:bazar_suez/admin/security/repositories/admin_role_repository.dart';
import 'package:bazar_suez/admin/security/services/admin_management_service.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/theme/app_color.dart';

class AddAdminPage extends StatefulWidget {
  const AddAdminPage({super.key});

  @override
  State<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _service = AdminManagementService();

  AdminRoleType _selectedRole = AdminRoleType.admin;
  late Map<String, bool> _permissions;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _permissions = Map<String, bool>.from(
      AdminRoleType.defaultPermissions(_selectedRole),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onRoleChanged(AdminRoleType? role) {
    if (role == null) return;
    setState(() {
      _selectedRole = role;
      _permissions = Map<String, bool>.from(
        AdminRoleType.defaultPermissions(role),
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthGuard>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _service.assignAdminByEmail(
        email: _emailController.text,
        role: _selectedRole,
        permissions: _permissions,
        adminUid: uid,
        adminName: auth.currentUser?.email ?? 'Admin',
        displayName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعيين المسؤول بنجاح')),
      );
      context.pop();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إضافة مسؤول'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                if (!v.contains('@')) return 'بريد إلكتروني غير صالح';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AdminRoleType>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'الدور',
                border: OutlineInputBorder(),
              ),
              items: AdminRoleType.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.labelAr),
                    ),
                  )
                  .toList(),
              onChanged: _onRoleChanged,
            ),
            const SizedBox(height: 24),
            const Text(
              'الصلاحيات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...AdminPermission.values.map(
              (p) => SwitchListTile(
                title: Text(p.labelAr),
                value: _permissions[p.firestoreKey] ?? false,
                activeColor: AppColors.mainColor,
                onChanged: _selectedRole == AdminRoleType.superAdmin
                    ? null
                    : (v) => setState(() => _permissions[p.firestoreKey] = v),
              ),
            ),
            if (_selectedRole == AdminRoleType.superAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'المسؤول الأعلى يمتلك جميع الصلاحيات تلقائياً',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mainColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('تعيين المسؤول'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminRolesPage extends StatelessWidget {
  const AdminRolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = AdminRoleRepository();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('إدارة المسؤولين'),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'إضافة مسؤول',
            onPressed: () => context.push('/admin/add-admin'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/add-admin'),
        backgroundColor: AppColors.mainColor,
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة مسؤول'),
      ),
      body: StreamBuilder<List<AdminRoleModel>>(
        stream: repository.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final admins = snapshot.data ?? [];
          if (admins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('لا يوجد مسؤولون مسجلون',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/admin/add-admin'),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة أول مسؤول'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: admins.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final admin = admins[index];
              return _AdminRoleCard(admin: admin);
            },
          );
        },
      ),
    );
  }
}

class _AdminRoleCard extends StatelessWidget {
  const _AdminRoleCard({required this.admin});

  final AdminRoleModel admin;

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthGuard>().currentUser?.uid;
    final service = AdminManagementService();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.mainColor.withOpacity(0.15),
          child: Icon(Icons.shield_outlined, color: AppColors.mainColor),
        ),
        title: Text(admin.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(admin.email),
            const SizedBox(height: 4),
            Chip(
              label: Text(admin.role.labelAr, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.mainColor.withOpacity(0.1),
            ),
          ],
        ),
        trailing: admin.uid == currentUid
            ? null
            : IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                tooltip: 'إزالة صلاحيات المسؤول',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('إزالة المسؤول'),
                      content: Text('هل تريد إزالة صلاحيات ${admin.name}؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('تأكيد'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;

                  try {
                    await service.removeAdminRole(
                      targetUid: admin.uid,
                      adminUid: currentUid!,
                      adminName: context.read<AuthGuard>().currentUser?.email ?? 'Admin',
                      targetName: admin.name,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إزالة صلاحيات المسؤول')),
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
              ),
      ),
    );
  }
}
