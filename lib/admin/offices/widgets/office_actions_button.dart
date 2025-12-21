import 'package:flutter/material.dart';
import '../../../theme/app_color.dart';
import '../services/offices_service.dart';

class OfficeActionsButton extends StatelessWidget {
  final String officeId;
  final bool isActive;
  final OfficesService service;
  final VoidCallback? onActionCompleted;

  const OfficeActionsButton({
    super.key,
    required this.officeId,
    required this.isActive,
    required this.service,
    this.onActionCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PopupMenuButton<String>(
        onSelected: (value) async {
          switch (value) {
            case 'edit':
              // سيتم التعامل مع التعديل في الصفحة الرئيسية
              break;
            case 'block':
              await _handleBlock(context);
              break;
            case 'activate':
              await _handleActivate(context);
              break;
            case 'delete':
              await _handleDelete(context);
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.mainColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.mainColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.more_vert, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'إدارة المكتب',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down, color: Colors.white, size: 24),
            ],
          ),
        ),
        itemBuilder: (BuildContext context) => [
          if (isActive)
            PopupMenuItem<String>(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'تعطيل المكتب',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          if (!isActive)
            PopupMenuItem<String>(
              value: 'activate',
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'تفعيل المكتب',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red[700], size: 20),
                const SizedBox(width: 12),
                Text(
                  'حذف المكتب',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.white,
      ),
    );
  }

  Future<void> _handleBlock(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعطيل المكتب'),
        content: const Text('هل أنت متأكد من تعطيل هذا المكتب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // إظهار loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await service.blockOffice(officeId);

    if (!context.mounted) return;
    Navigator.pop(context); // إغلاق loading

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'تم التعطيل بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      onActionCompleted?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'حدث خطأ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleActivate(BuildContext context) async {
    // إظهار loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await service.activateOffice(officeId);

    if (!context.mounted) return;
    Navigator.pop(context); // إغلاق loading

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'تم التفعيل بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      onActionCompleted?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'حدث خطأ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المكتب'),
        content: const Text(
          'هل أنت متأكد من حذف هذا المكتب؟\n'
          'سيتم حذف جميع البيانات المرتبطة به ولا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // إظهار loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await service.deleteOffice(officeId);

    if (!context.mounted) return;
    Navigator.pop(context); // إغلاق loading

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'تم الحذف بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      onActionCompleted?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'حدث خطأ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
