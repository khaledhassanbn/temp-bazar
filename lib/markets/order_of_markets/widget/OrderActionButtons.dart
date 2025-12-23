import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';

class OrderActionButtons extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onStatusChange;
  final VoidCallback? onRequestDelivery;

  const OrderActionButtons({
    super.key,
    required this.order,
    required this.onStatusChange,
    this.onRequestDelivery,
  });

  void _confirmAction(BuildContext context, String message, String newStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد العملية"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("إلغاء"),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
            ),
            child: const Text("تأكيد"),
            onPressed: () {
              Navigator.pop(ctx);
              onStatusChange(newStatus);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // الحالة الأولى: قيد المراجعة
          if (status == 'قيد المراجعة') ...[
            Expanded(
              child: _buildActionButton(
                'استلام الطلب',
                Icons.assignment_turned_in,
                Colors.blueAccent,
                () => _confirmAction(
                  context,
                  'هل أنت متأكد من استلام الأوردر؟',
                  'تم استلام الطلب',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                'رفض الطلب',
                Icons.cancel,
                Colors.redAccent,
                () => _confirmAction(
                  context,
                  'هل أنت متأكد من رفض الأوردر؟',
                  'تم رفض الطلب',
                ),
              ),
            ),
          ],

          // الحالة الثانية: تم استلام الطلب
          if (status == 'تم استلام الطلب') ...[
            Expanded(
              child: _buildActionButton(
                'طلب طيار',
                Icons.delivery_dining,
                Colors.orangeAccent,
                () {
                  if (onRequestDelivery != null) {
                    onRequestDelivery!();
                  } else {
                    _confirmAction(
                      context,
                      'هل أنت متأكد من طلب الطيار؟',
                      'جارى تسليم للدليفري',
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                'هسلمه بنفسى',
                Icons.person,
                Colors.green,
                () => _confirmAction(
                  context,
                  'هل أنت متأكد أنك هتسلمه بنفسك؟',
                  'تم التسليم للطيار',
                ),
              ),
            ),
          ],

          // الحالة الثالثة: جارى تسليم للدليفري
          if (status == 'جارى تسليم للدليفري')
            Expanded(
              child: _buildActionButton(
                'تم التسليم للطيار',
                Icons.done_all,
                Colors.green,
                () => _confirmAction(
                  context,
                  'هل أنت متأكد من تسليم الأوردر للطيار؟',
                  'تم التسليم للطيار',
                ),
              ),
            ),

          // الحالة الرابعة: تم التسليم للطيار
          if (status == 'تم التسليم للطيار')
            _statusChip(Icons.check_circle, 'تم التسليم', Colors.green),

          // الحالة الخامسة: تم رفض الطلب
          if (status == 'تم رفض الطلب')
            _statusChip(Icons.cancel, 'تم الرفض', Colors.red),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      onPressed: onPressed,
    );
  }
}
