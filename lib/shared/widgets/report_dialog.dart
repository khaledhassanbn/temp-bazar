import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bazar_suez/shared/services/user_report_service.dart';

/// Dialog للإبلاغ عن صنايعي، متجر، أو كورير
class ReportDialog extends StatefulWidget {
  final String targetId;
  final String targetType; // 'craftsman' | 'store' | 'courier'
  final String targetName;

  const ReportDialog({
    Key? key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _reportService = UserReportService();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول للإبلاغ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reportService.createReport(
        reporterId: currentUser.uid,
        targetId: widget.targetId,
        targetType: widget.targetType,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال البلاغ بنجاح. شكراً لك.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('إبلاغ'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أنت على وشك الإبلاغ عن: ${widget.targetName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'سبب البلاغ *',
                  hintText: 'اشرح سبب البلاغ بالتفصيل...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال سبب البلاغ';
                  }
                  if (value.trim().length < 10) {
                    return 'يجب أن يكون السبب 10 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'ملاحظة: سيتم مراجعة البلاغ من قبل الإدارة',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('إرسال البلاغ'),
          ),
        ],
      ),
    );
  }
}

/// دالة مساعدة لعرض Dialog الإبلاغ
Future<void> showReportDialog(
  BuildContext context, {
  required String targetId,
  required String targetType,
  required String targetName,
}) {
  return showDialog(
    context: context,
    builder: (context) => ReportDialog(
      targetId: targetId,
      targetType: targetType,
      targetName: targetName,
    ),
  );
}
