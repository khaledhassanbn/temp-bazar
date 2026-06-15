import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bazar_suez/admin/craftsmen/models/craftsman_admin_model.dart';
import 'package:bazar_suez/admin/craftsmen/services/craftsmen_admin_service.dart';
import 'package:bazar_suez/authentication/guards/AuthGuard.dart';
import 'package:bazar_suez/theme/app_color.dart';

class CraftsmanAdminDetailPage extends StatefulWidget {
  final String craftsmanId;

  const CraftsmanAdminDetailPage({super.key, required this.craftsmanId});

  @override
  State<CraftsmanAdminDetailPage> createState() =>
      _CraftsmanAdminDetailPageState();
}

class _CraftsmanAdminDetailPageState extends State<CraftsmanAdminDetailPage> {
  final _service = CraftsmenAdminService();
  CraftsmanAdminModel? _craftsman;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getById(widget.craftsmanId);
    if (mounted) {
      setState(() {
        _craftsman = data;
        _loading = false;
      });
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  ({String uid, String name})? _adminInfo() {
    final auth = context.read<AuthGuard>();
    final user = auth.currentUser;
    if (user == null) {
      _showSnack('يجب تسجيل الدخول كمسؤول', isError: true);
      return null;
    }
    return (uid: user.uid, name: user.email ?? 'Admin');
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    if (_actionLoading) return false;
    setState(() => _actionLoading = true);
    try {
      await action();
      return true;
    } catch (e) {
      _showSnack('حدث خطأ: $e', isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _suspend() async {
    final reason = await _showReasonDialog('سبب الإيقاف');
    if (reason == null || reason.isEmpty) return;
    final admin = _adminInfo();
    if (admin == null) return;

    await _runAction(() => _service.suspend(
          craftsmanId: widget.craftsmanId,
          reason: reason,
          adminUid: admin.uid,
          adminName: admin.name,
        ));
    await _load();
    _showSnack('تم إيقاف الحساب مؤقتاً');
  }

  Future<void> _ban() async {
    final reason = await _showReasonDialog('سبب الحظر');
    if (reason == null || reason.isEmpty) return;
    final admin = _adminInfo();
    if (admin == null) return;

    await _runAction(() => _service.ban(
          craftsmanId: widget.craftsmanId,
          reason: reason,
          adminUid: admin.uid,
          adminName: admin.name,
        ));
    await _load();
    _showSnack('تم حظر الحساب');
  }

  Future<void> _reactivate() async {
    final admin = _adminInfo();
    if (admin == null) return;

    await _runAction(() => _service.reactivate(
          craftsmanId: widget.craftsmanId,
          adminUid: admin.uid,
          adminName: admin.name,
        ));
    await _load();
    _showSnack('تم إعادة تفعيل الحساب');
  }

  Future<void> _softDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحساب'),
        content: const Text(
          'سيتم حذف الحساب بشكل ناعم (Soft Delete) ويمكن استعادته لاحقاً من صفحة الحسابات المحذوفة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final admin = _adminInfo();
    if (admin == null) return;

    final ok = await _runAction(() => _service.softDelete(
          craftsmanId: widget.craftsmanId,
          adminUid: admin.uid,
          adminName: admin.name,
        ));
    if (!ok || !mounted) return;

    _showSnack('تم حذف الحساب (Soft Delete)');
    context.pop();
  }

  Future<void> _deletePortfolioImage(String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصورة'),
        content: const Text('هل أنت متأكد من حذف هذه الصورة من معرض أعمال الصنايعي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final admin = _adminInfo();
    if (admin == null) return;

    await _runAction(() => _service.removePortfolioImage(
          craftsmanId: widget.craftsmanId,
          imageUrl: url,
          adminUid: admin.uid,
          adminName: admin.name,
        ));
    await _load();
    _showSnack('تم حذف الصورة من المعرض');
  }

  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = _craftsman;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('غير موجود')),
        body: const Center(child: Text('الصنايعي غير موجود')),
      );
    }

    final isDeleted = c.isDeleted || c.accountStatus == 'deleted';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(c.name),
        backgroundColor: AppColors.mainColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: c.photoUrl != null
                      ? CachedNetworkImageProvider(c.photoUrl!)
                      : null,
                  child: c.photoUrl == null
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _InfoTile('الهاتف', c.phone),
              _InfoTile('المهنة', c.professionName),
              _InfoTile('المنطقة', c.areaName),
              _InfoTile('التقييم', '${c.averageRating} (${c.totalReviews} مراجعة)'),
              _InfoTile('البلاغات', '${c.reportCount}'),
              _InfoTile('الحالة', c.statusLabel),
              const SizedBox(height: 20),
              Text(
                'معرض الأعمال',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),
              if (c.portfolioUrls.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'لا توجد صور في المعرض',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: c.portfolioUrls.length,
                  itemBuilder: (context, index) {
                    final url = c.portfolioUrls[index];
                    return _PortfolioImageTile(
                      url: url,
                      onDelete: () => _deletePortfolioImage(url),
                    );
                  },
                ),
              const SizedBox(height: 24),
              if (!isDeleted && c.accountStatus != 'active')
                FilledButton.icon(
                  onPressed: _actionLoading ? null : _reactivate,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('إعادة تفعيل'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              if (!isDeleted && c.accountStatus == 'active') ...[
                OutlinedButton.icon(
                  onPressed: _actionLoading ? null : _suspend,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('إيقاف مؤقت'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _actionLoading ? null : _ban,
                  icon: const Icon(Icons.block),
                  label: const Text('حظر'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
              if (!isDeleted) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _actionLoading ? null : _softDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('حذف (Soft Delete)'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ],
          ),
          if (_actionLoading)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _PortfolioImageTile extends StatelessWidget {
  const _PortfolioImageTile({required this.url, required this.onDelete});

  final String url;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey.shade200),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
