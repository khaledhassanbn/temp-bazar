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
  final String? rejectedMessage;

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
                      Text(
                        'طلب رقم: ${order['id']}',
                        style: const TextStyle(
                          color: AppColors.mainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
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
                // حالة الطلب
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order['status']),
                    borderRadius: BorderRadius.circular(12),
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
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
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
                      const Divider(height: 20),
                      _buildInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'الهاتف',
                        value: order['customerPhone'] ?? '',
                        trailing: IconButton(
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
                            trailing: IconButton(
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
                          ),
                      ],
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
      default:
        return Colors.grey;
    }
  }
}
