import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/markets/order_of_markets/widget/OrderActionButtons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final AnimationController animController;
  final Function(String) onStatusChange;
  final GeoPoint? marketLocation;
  final Map<String, String>? distanceAndDuration;
  final Future<void> Function(
    Map<String, dynamic> order,
    Map<String, String>? distanceAndDuration,
  )?
  onRequestDelivery;
  final String? rejectedMessage; // رسالة الرفض من المكتب

  const OrderCard({
    super.key,
    required this.order,
    required this.animController,
    required this.onStatusChange,
    required this.marketLocation,
    this.distanceAndDuration,
    this.onRequestDelivery,
    this.rejectedMessage,
  });

  String _timeSinceOrder(DateTime orderTime) {
    final diff = DateTime.now().difference(orderTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (hours > 0) return '$hours ساعة و $minutes دقيقة و $seconds ثانية';
    if (minutes > 0) return '$minutes دقيقة و $seconds ثانية';
    return '$seconds ثانية';
  }

  String _formatOrderTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

  String _formatOrderDate(DateTime time) =>
      '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';

  @override
  Widget build(BuildContext context) {
    final requiredOptions = List<Map<String, dynamic>>.from(
      order['requiredOptions'],
    );
    final extraOptions = List<Map<String, dynamic>>.from(order['extraOptions']);
    final GeoPoint? clientLocation = order['customerLocation'] as GeoPoint?;
    final String assignedDriverName =
        (order['assignedDriverName'] ?? '').toString();
    final String assignedDriverPhone =
        (order['assignedDriverPhone'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================== Header ==================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طلب رقم: ${order['id']}',
                style: const TextStyle(
                  color: AppColors.mainColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order['status'],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ================== رسالة الرفض (إن وجدت) ==================
          if (rejectedMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rejectedMessage!,
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ================== Info ==================
          // ================== Customer Info (منسق واحترافي + الوقت والمسافة) ==================
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 العنوان الرئيسي
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.mainColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.mainColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "معلومات العميل",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 🔹 جدول المعلومات (الكل منسق بشكل ثابت)
                Table(
                  columnWidths: const {
                    0: FixedColumnWidth(75),
                    1: FlexColumnWidth(),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // الاسم
                    _infoRow(
                      "الاسم",
                      Text(order['customerName'] ?? "غير معروف"),
                    ),

                    // الهاتف
                    _infoRow(
                      "الهاتف",
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order['customerPhone'] ?? "",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: order['customerPhone'].toString(),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ رقم الهاتف'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.copy,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // العنوان
                    _infoRow(
                      "العنوان",
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order['customerAddress'] ?? "غير متوفر",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final GeoPoint? clientLocation =
                                  order['customerLocation'] as GeoPoint?;
                              if (clientLocation != null) {
                                final lat = clientLocation.latitude;
                                final lng = clientLocation.longitude;
                                final url =
                                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('لا يمكن فتح الخريطة'),
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // المسافة (في حالة متاحة)
                    if (marketLocation != null && clientLocation != null)
                      _infoRow(
                        "المسافة",
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                distanceAndDuration != null
                                    ? '${distanceAndDuration!['distance'] ?? ''} (تقريباً ${distanceAndDuration!['duration'] ?? ''})'
                                    : 'جارٍ الحساب...',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // وقت الطلب
                    _infoRow(
                      "الوقت",
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _formatOrderTime(order['orderTime']),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // تاريخ الطلب (من createdAt)
                    _infoRow(
                      "التاريخ",
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order['createdAt'] != null
                                  ? _formatOrderDate(
                                      (order['createdAt'] as Timestamp)
                                          .toDate(),
                                    )
                                  : _formatOrderDate(order['orderTime']),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ================== Driver Info (مندوب التوصيل) ==================
          if (assignedDriverName.isNotEmpty ||
              assignedDriverPhone.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "معلومات المندوب",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FixedColumnWidth(90),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      if (assignedDriverName.isNotEmpty)
                        _infoRow(
                          "اسم المندوب",
                          Text(
                            assignedDriverName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      if (assignedDriverPhone.isNotEmpty)
                        _infoRow(
                          "هاتف المندوب",
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  assignedDriverPhone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: assignedDriverPhone),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('تم نسخ رقم هاتف المندوب'),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.copy,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // ================== Order Details ==================
          const Text(
            'تفاصيل الطلب:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          OrderDetailsTable(
            requiredOptions: requiredOptions,
            extraOptions: extraOptions,
          ),
          const SizedBox(height: 12),

          // ================== Total ==================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '💰 الإجمالي:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${order['totalPrice']} جنيه',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.mainColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ================== Timer ==================
          ScaleTransition(
            scale: animController,
            child: Text(
              '⏱ منذ: ${_timeSinceOrder(order['orderTime'])}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ================== Actions ==================
          OrderActionButtons(
            order: order,
            onStatusChange: onStatusChange,
            onRequestDelivery: onRequestDelivery != null
                ? () => onRequestDelivery!(order, distanceAndDuration)
                : null,
          ),
        ],
      ),
    );
  }

  // ================== Helper Colors ==================
  Color _getStatusColor(String status) {
    switch (status) {
      case 'تم استلام الطلب':
        return Colors.blue;
      case 'جارى تسليم للدليفري':
        return Colors.orange;
      case 'تم التسليم للطيار':
        return Colors.green;
      case 'تم رفض الطلب':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }
}

// ================== تفاصيل الطلب (جدول احترافي) ==================
class OrderDetailsTable extends StatelessWidget {
  final List<Map<String, dynamic>> requiredOptions;
  final List<Map<String, dynamic>> extraOptions;

  const OrderDetailsTable({
    super.key,
    required this.requiredOptions,
    required this.extraOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (requiredOptions.isNotEmpty)
          _buildSection(
            title: "الخيارات الأساسية",
            options: requiredOptions,
            iconColor: Colors.blue,
          ),
        if (extraOptions.isNotEmpty)
          _buildSection(
            title: "الإضافات",
            options: extraOptions,
            iconColor: Colors.green,
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> options,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          _buildOptionsTable(options, iconColor),
        ],
      ),
    );
  }

  Widget _buildOptionsTable(
    List<Map<String, dynamic>> options,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==== اسم المنتج الرئيسي ====
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i]['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ==== التفاصيل الخاصة بالمنتج ====
                ...List.generate((options[i]['details'] as List).length, (j) {
                  final detail =
                      (options[i]['details'] as List<Map<String, dynamic>>)[j];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          "${detail['label']}: ",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            detail['value'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (i < options.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.grey.shade300, thickness: 0.8),
            ),
        ],
      ],
    );
  }
}

// ================== دالة مساعدة لتنسيق كل سطر ==================
TableRow _infoRow(String label, Widget valueWidget) {
  return TableRow(
    children: [
      _infoLabel(label),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: valueWidget,
      ),
    ],
  );
}

Widget _infoLabel(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      "$text:",
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Colors.black54,
      ),
      textAlign: TextAlign.right,
    ),
  );
}
