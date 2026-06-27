import 'package:flutter/material.dart';
import 'package:bazar_suez/theme/app_color.dart';
import 'package:bazar_suez/markets/order_of_markets/widget/OrderActionButtons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  final String? rejectedMessage;
  final VoidCallback? onChangeIndependentCourier;

  const OrderCard({
    super.key,
    required this.order,
    required this.animController,
    required this.onStatusChange,
    required this.marketLocation,
    this.distanceAndDuration,
    this.onRequestDelivery,
    this.rejectedMessage,
    this.onChangeIndependentCourier,
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

  String _formatPrice(dynamic value) {
    final num numericValue = value is num ? value : num.tryParse('$value') ?? 0;
    return numericValue.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    // دعم كلا الطريقتين: items (الجديدة) و requiredOptions (القديمة)
    final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
    final requiredOptions = List<Map<String, dynamic>>.from(order['requiredOptions'] ?? []);
    final extraOptions = List<Map<String, dynamic>>.from(order['extraOptions'] ?? []);
    
    // إذا كانت items فارغة، استخدم requiredOptions
    final displayItems = items.isNotEmpty ? items : requiredOptions;
    
    final GeoPoint? clientLocation = order['customerLocation'] as GeoPoint?;
    final String assignedDriverName =
        (order['assignedDriverName'] ?? '').toString();
    final String assignedDriverPhone =
        (order['assignedDriverPhone'] ?? '').toString();
    final String generalNotes = (order['notes'] ?? '').toString();
    final Map<String, dynamic>? deliveryRating =
        order['deliveryRating'] is Map
            ? Map<String, dynamic>.from(order['deliveryRating'] as Map)
            : null;
    final Map<String, dynamic>? independentDispatch =
        order['independentDispatch'] as Map<String, dynamic>?;
    final Map<String, dynamic> independentCouriersDirectory =
        (order['independentCouriersDirectory'] is Map)
            ? Map<String, dynamic>.from(order['independentCouriersDirectory'])
            : <String, dynamic>{};
    final String cancelReason = (order['cancelReason'] ?? '').toString();
    final dynamic cancelledAtRaw = order['cancelledAt'];
    String? cancelledAtFormatted;
    if (cancelledAtRaw is Timestamp) {
      final dt = cancelledAtRaw.toDate();
      cancelledAtFormatted =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ================== Header مع التصميم الجديد ==================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.mainColor.withOpacity(0.1),
                  AppColors.mainColor.withOpacity(0.05),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // أيقونة الطلب
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.mainColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mainColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // معلومات الطلب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رقم الطلب كامل
                      Text(
                        'طلب رقم: ${order['id']}',
                        style: const TextStyle(
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // حالة الطلب تحت الرقم
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order['status']),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(order['status']).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          order['status'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatOrderTime(order['orderTime']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order['createdAt'] != null
                                    ? _formatOrderDate(
                                        (order['createdAt'] as Timestamp).toDate(),
                                      )
                                    : _formatOrderDate(order['orderTime']),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================== رسالة الرفض (إن وجدت) ==================
                if (rejectedMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            rejectedMessage!,
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ================== سبب الإلغاء (إن وُجد) ==================
                if (cancelReason.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cancel_rounded,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'سبب الإلغاء',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cancelReason,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (cancelledAtFormatted != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'وقت الإلغاء: $cancelledAtFormatted',
                                style: TextStyle(
                                  color: Colors.red.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ================== معلومات العميل ==================
                _buildSectionCard(
                  title: 'معلومات العميل',
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.mainColor,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        label: 'الاسم',
                        value: order['customerName'] ?? 'غير معروف',
                      ),
                      if (order['customerReliability'] != null) ...[
                        const Divider(height: 20),
                        _buildInfoRow(
                          icon: Icons.verified_user_outlined,
                          label: 'نسبة الالتزام',
                          value:
                              '${(order['customerReliability'] as num).toStringAsFixed(1)}%',
                        ),
                      ],
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'الهاتف',
                        value: order['customerPhone'] ?? '',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.phone, size: 18),
                              color: Colors.green,
                              onPressed: () async {
                                final phone = order['customerPhone']?.toString() ?? '';
                                if (phone.isNotEmpty) {
                                  final url = Uri.parse('tel:$phone');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              color: Colors.blue,
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: order['customerPhone'].toString(),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم نسخ رقم الهاتف'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'العنوان',
                        value: order['customerAddress'] ?? 'غير متوفر',
                        trailing: IconButton(
                          icon: const Icon(Icons.navigation, size: 20),
                          color: Colors.green,
                          onPressed: () async {
                            if (clientLocation != null) {
                              final lat = clientLocation.latitude;
                              final lng = clientLocation.longitude;
                              final url =
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                            }
                          },
                        ),
                      ),
                      if (marketLocation != null && clientLocation != null) ...[
                        const Divider(height: 20),
                        _buildInfoRow(
                          icon: Icons.social_distance_outlined,
                          label: 'المسافة',
                          value: distanceAndDuration != null
                              ? '${distanceAndDuration!['distance'] ?? ''} (${distanceAndDuration!['duration'] ?? ''})'
                              : 'جارٍ الحساب...',
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================== معلومات المندوب (إن وجد) ==================
                if (assignedDriverName.isNotEmpty ||
                    assignedDriverPhone.isNotEmpty) ...[
                  _buildSectionCard(
                    title: 'معلومات المندوب',
                    icon: Icons.delivery_dining_rounded,
                    iconColor: Colors.orange,
                    child: Column(
                      children: [
                        if (assignedDriverName.isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.person_pin_outlined,
                            label: 'اسم المندوب',
                            value: assignedDriverName,
                          ),
                        if (assignedDriverName.isNotEmpty &&
                            assignedDriverPhone.isNotEmpty)
                          const Divider(height: 20),
                        if (assignedDriverPhone.isNotEmpty)
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            label: 'هاتف المندوب',
                            value: assignedDriverPhone,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.phone, size: 18),
                                  color: Colors.green,
                                  onPressed: () async {
                                    final url = Uri.parse('tel:$assignedDriverPhone');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  color: Colors.blue,
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: assignedDriverPhone),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('تم نسخ رقم هاتف المندوب'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ================== تقييم المندوب من العميل ==================
                if (deliveryRating != null &&
                    (assignedDriverName.isNotEmpty || assignedDriverPhone.isNotEmpty)) ...[
                  _buildSectionCard(
                    title: 'تقييم المندوب',
                    icon: Icons.star_rate_rounded,
                    iconColor: Colors.amber.shade700,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.star_rounded,
                          label: 'التقييم',
                          value:
                              '${(deliveryRating['rating'] ?? 0).toString()}/5',
                        ),
                        if ((deliveryRating['comment'] ?? '').toString().isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildInfoRow(
                            icon: Icons.comment_outlined,
                            label: 'تعليق العميل',
                            value: (deliveryRating['comment'] ?? '').toString(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ================== ردود المناديب المستقلين (Realtime) ==================
                if (independentDispatch != null) ...[
                  _buildSectionCard(
                    title: 'ردود المناديب',
                    icon: Icons.how_to_reg_rounded,
                    iconColor: Colors.orange,
                    child: _IndependentCourierResponsesView(
                      dispatch: independentDispatch,
                      couriersDirectory: independentCouriersDirectory,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ================== المنتجات المطلوبة ==================
                if (displayItems.isNotEmpty)
                  _buildSectionCard(
                    title: 'المنتجات المطلوبة (${displayItems.length})',
                    icon: Icons.shopping_bag_outlined,
                    iconColor: Colors.purple,
                    child: Column(
                      children: [
                        for (int i = 0; i < displayItems.length; i++) ...[
                          items.isNotEmpty 
                            ? _buildProductItem(displayItems[i])
                            : _buildProductItemFromOldFormat(displayItems[i]),
                          if (i < displayItems.length - 1)
                            Divider(
                              height: 24,
                              color: Colors.grey.shade200,
                              thickness: 1,
                            ),
                        ],
                      ],
                    ),
                  ),
                
                // ================== الإضافات (إن وجدت) ==================
                if (extraOptions.isNotEmpty)
                  _buildSectionCard(
                    title: 'إضافات إضافية',
                    icon: Icons.add_circle_outline,
                    iconColor: Colors.green,
                    child: Column(
                      children: [
                        for (int i = 0; i < extraOptions.length; i++) ...[
                          _buildProductItemFromOldFormat(extraOptions[i]),
                          if (i < extraOptions.length - 1)
                            Divider(
                              height: 24,
                              color: Colors.grey.shade200,
                              thickness: 1,
                            ),
                        ],
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // ================== الملحوظات العامة ==================
                if (generalNotes.isNotEmpty) ...[
                  _buildSectionCard(
                    title: 'ملحوظات عامة على الطلب',
                    icon: Icons.note_alt_outlined,
                    iconColor: Colors.deepOrange,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        generalNotes,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ================== الفاتورة ==================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.mainColor.withOpacity(0.08),
                        AppColors.mainColor.withOpacity(0.03),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.mainColor.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المجموع الفرعي:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_formatPrice(order['subtotal'] ?? 0)} جنيه',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'رسوم التوصيل:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_formatPrice(order['deliveryFee'] ?? 0)} جنيه',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'رسوم الخدمة:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_formatPrice(order['serviceFee'] ?? 0)} جنيه',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Divider(
                        height: 24,
                        color: AppColors.mainColor.withOpacity(0.3),
                        thickness: 1.5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '💰 الإجمالي:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.mainColor,
                            ),
                          ),
                          Text(
                            '${_formatPrice(order['totalAmount'] ?? order['totalPrice'] ?? 0)} جنيه',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.mainColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================== Timer ==================
                Center(
                  child: ScaleTransition(
                    scale: animController,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'منذ: ${_timeSinceOrder(order['orderTime'])}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================== Independent courier quick actions (2x2) ==================
                if (independentDispatch != null) ...[
                  _IndependentDispatchQuickActions(
                    onChangeCourier: onChangeIndependentCourier,
                    onDeliverSelf: () => onStatusChange('تم التسليم للطيار'),
                    onCancel: () => onStatusChange('تم رفض الطلب'),
                  ),
                  const SizedBox(height: 12),
                ],

                // ================== Actions ==================
                OrderActionButtons(
                  order: order,
                  onStatusChange: onStatusChange,
                  onRequestDelivery: onRequestDelivery != null
                      ? () => onRequestDelivery!(order, distanceAndDuration)
                      : null,
                  independentDispatch: independentDispatch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== بناء قسم بتصميم موحد ==================
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ================== بناء صف معلومات ==================
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ================== بناء عنصر المنتج (الطريقة القديمة) ==================
  Widget _buildProductItemFromOldFormat(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'منتج';
    final details = List<Map<String, dynamic>>.from(item['details'] ?? []);
    
    // محاولة استخراج صورة المنتج من التفاصيل إن وجدت
    String? productImage;
    for (var detail in details) {
      if (detail['label']?.toString().toLowerCase().contains('image') == true ||
          detail['label']?.toString().toLowerCase().contains('صورة') == true) {
        productImage = detail['value']?.toString();
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم المنتج
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: productImage != null && productImage.isNotEmpty
                    ? Image.network(
                        productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fastfood_rounded,
                            color: Colors.purple.shade400,
                            size: 24,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.purple.shade400,
                              ),
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.fastfood_rounded,
                        color: Colors.purple.shade400,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          // التفاصيل
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...details.map((detail) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.mainColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${detail['label']}: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              detail['value']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 12,
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
          ],
        ],
      ),
    );
  }

  // ================== بناء عنصر المنتج ==================
  Widget _buildProductItem(Map<String, dynamic> item) {
    final productNote = item['productNote']?.toString() ?? '';
    final selectedOptions = item['selectedOptions'] as Map<String, dynamic>?;
    final productImage = item['productImage']?.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم المنتج والكمية
          Row(
            children: [
              // صورة المنتج أو أيقونة
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: productImage != null && productImage.isNotEmpty
                    ? Image.network(
                        productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.fastfood_rounded,
                            color: Colors.purple.shade400,
                            size: 24,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.purple.shade400,
                              ),
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.fastfood_rounded,
                        color: Colors.purple.shade400,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['productName'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'الكمية: ${item['quantity']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatPrice(item['totalPrice'])} جنيه',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // الخيارات المختارة
          if (selectedOptions != null && selectedOptions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'الخيارات المختارة:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...selectedOptions.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.mainColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.key}: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              entry.value?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 12,
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
          ],

          // ملحوظة المنتج
          if (productNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ملحوظة خاصة:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          productNote,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      case 'المكتب رفض الطلب':
        return Colors.deepOrange;
      case 'التسليم الذاتي':
        return Colors.purple;
      // حالات المندوب المستقل
      case 'المندوب قبل الطلب':
        return Colors.teal;
      case 'تم استلام الطلب من المتجر':
        return Colors.indigo;
      case 'الطلب مكتمل':
        return Colors.green;
      case 'الزبون رفض الاستلام':
        return Colors.red;
      case 'تم إلغاء الطلب':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _IndependentDispatchQuickActions extends StatelessWidget {
  final VoidCallback? onChangeCourier;
  final VoidCallback onDeliverSelf;
  final VoidCallback onCancel;

  const _IndependentDispatchQuickActions({
    required this.onChangeCourier,
    required this.onDeliverSelf,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                title: 'تغيير المندوب',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.mainColor,
                onTap: onChangeCourier,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionTile(
                title: 'هسلمه بنفسى',
                icon: Icons.person,
                color: Colors.green,
                onTap: onDeliverSelf,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ActionTile(
          title: 'إلغاء الطلب',
          icon: Icons.cancel,
          color: Colors.redAccent,
          onTap: onCancel,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled ? color.withOpacity(0.22) : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: enabled ? color : Colors.grey),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: enabled ? color : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndependentCourierResponsesView extends StatelessWidget {
  final Map<String, dynamic> dispatch;
  final Map<String, dynamic> couriersDirectory;

  const _IndependentCourierResponsesView({
    required this.dispatch,
    required this.couriersDirectory,
  });

  String _dispatchOrderStatusArabic(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'pending':
      case 'accepted':
        return 'الطلب في انتظار التعيين';
      case 'assigned':
      case 'notified_multiple':
        return 'تم إرساله للمناديب وبانتظار القبول';
      case 'driver_accepted':
        return 'قبل المندوب الطلب وهو في الطريق للمتجر';
      case 'picked_up':
        return 'استلم المندوب الشحنة وهو في الطريق للزبون';
      case 'completed':
        return 'تم التسليم بنجاح';
      case 'customer_rejected':
        return 'رفض الزبون استلام الشحنة';
      case 'returned_to_merchant':
        return 'تم إلغاء الطلب وإرجاعه للمتجر';
      case 'cancelled':
        return 'تم إلغاء الطلب';
      case 'reassigned_by_merchant':
        return 'تم سحب الطلب من المندوب بواسطة التاجر';
      default:
        return 'قيد المتابعة';
    }
  }

  String _dispatchStatusArabic(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'waiting_courier_response':
        return 'بانتظار رد المناديب';
      case 'courier_assigned':
        return 'تم تعيين مندوب';
      case 'fallback_to_office':
        return 'تم التحويل لمكتب توصيل';
      default:
        return 'قيد المتابعة';
    }
  }

  String _courierResponseArabic(String value) {
    final v = value.trim().toLowerCase();
    switch (v) {
      case 'accepted':
        return 'وافق';
      case 'rejected':
        return 'رفض';
      case 'pending':
      default:
        return 'بانتظار الرد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusRaw = (dispatch['status'] ?? '').toString();
    final statusText = _dispatchOrderStatusArabic(statusRaw);
    final dispatchStatusRaw = (dispatch['dispatchStatus'] ?? '').toString();
    final dispatchStatus = _dispatchStatusArabic(dispatchStatusRaw);
    final assignedCourierId = (dispatch['assignedCourierId'] ?? '').toString();
    final availableCouriers = (dispatch['availableCouriers'] is List)
        ? List<String>.from(dispatch['availableCouriers'] as List)
        : const <String>[];

    final responsesRaw = dispatch['courierResponses'];
    final Map<String, dynamic> responses = responsesRaw is Map
        ? Map<String, dynamic>.from(responsesRaw)
        : <String, dynamic>{};

    int pending = 0;
    int accepted = 0;
    int rejected = 0;

    // حساب العدادات مع مراعاة assignedCourierId
    final assignedId = (dispatch['assignedCourierId'] ?? '').toString();

    for (final uid in availableCouriers) {
      // لو المندوب هو المعيّن → نعدّه accepted بغض النظر عن courierResponses
      if (assignedId.isNotEmpty && uid == assignedId) {
        accepted++;
        continue;
      }
      final v = (responses[uid] ?? 'pending').toString().toLowerCase();
      if (v == 'accepted') accepted++;
      else if (v == 'rejected') rejected++;
      else pending++;
    }
    // لو المندوب المعيّن مش في availableCouriers بس موجود → نعدّه برضو
    if (assignedId.isNotEmpty && !availableCouriers.contains(assignedId)) {
      accepted++;
    }

    final createdAtRaw = dispatch['createdAt'];
    DateTime? createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    }
    final bool timedOut = createdAt != null &&
        DateTime.now().difference(createdAt).inMinutes >= 3 &&
        accepted == 0 &&
        assignedCourierId.isEmpty &&
        (statusRaw.toLowerCase() == 'searching' ||
            statusRaw.toLowerCase() == 'assigned' ||
            statusRaw.toLowerCase() == 'notified_multiple');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _miniChip(statusText, Colors.blueGrey),
            _miniChip(dispatchStatus, Colors.blueGrey),
            _miniChip('بانتظار الرد: $pending', Colors.orange),
            _miniChip('رفض: $rejected', Colors.red),
            _miniChip('موافقة: $accepted', Colors.green),
          ],
        ),
        if (timedOut) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.25)),
            ),
            child: const Text(
              'لم يتم قبول الطلب بعد. يمكنك إعادة الإرسال أو اختيار مناديب آخرين.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
        if (assignedCourierId.isNotEmpty) ...[
          const SizedBox(height: 10),
          _AssignedIndependentCourierCard(
            courierUid: assignedCourierId,
            courierData: couriersDirectory[assignedCourierId] is Map
                ? Map<String, dynamic>.from(couriersDirectory[assignedCourierId])
                : null,
          ),
        ],
        if (availableCouriers.isNotEmpty) ...[
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: availableCouriers.map((uid) {
              final v = (responses[uid] ?? 'pending').toString().toLowerCase();
              Color c;
              String t;
              if (v == 'accepted') {
                c = Colors.green;
                t = _courierResponseArabic(v);
              } else if (v == 'rejected') {
                c = Colors.red;
                t = _courierResponseArabic(v);
              } else {
                c = Colors.orange;
                t = _courierResponseArabic(v);
              }
              final courierDataRaw = couriersDirectory[uid];
              final courierData =
                  courierDataRaw is Map ? Map<String, dynamic>.from(courierDataRaw) : null;
              final name = (courierData?['name'] ?? 'مندوب').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Text(
                      t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: c,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

}

class _AssignedIndependentCourierCard extends StatelessWidget {
  final String courierUid;
  final Map<String, dynamic>? courierData;

  const _AssignedIndependentCourierCard({
    required this.courierUid,
    required this.courierData,
  });

  @override
  Widget build(BuildContext context) {
    final name = (courierData?['name'] ?? 'مندوب').toString();
    final phone = (courierData?['phone'] ?? '').toString();
    final photoUrl = (courierData?['photoUrl'] ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: ClipOval(
              child: photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      key: ValueKey(photoUrl),
                      cacheKey: photoUrl,
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (c, _) => const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (c, _, __) => const Icon(Icons.person),
                    )
                  : const Icon(Icons.person),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم قبول الطلب بواسطة:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              onPressed: () async {
                final url = Uri.parse('tel:$phone');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              icon: const Icon(Icons.phone_rounded),
              color: Colors.green,
              tooltip: 'اتصال',
            ),
        ],
      ),
    );
  }
}
