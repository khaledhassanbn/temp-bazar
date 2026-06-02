import 'package:cloud_firestore/cloud_firestore.dart';

/// أدوات مشتركة لتحديد حالة الطلب واكتمال التوصيل
class OrderStatusHelper {
  static const _deliveredStatuses = {
    'تم التسليم للطيار',
    'الطلب مكتمل',
    'تم التسليم',
    'التسليم الذاتي',
    'completed',
    'delivered',
    'self_delivery',
  };

  static const _rejectedStatuses = {
    'تم رفض الطلب',
    'مرفوض نهائياً',
    'الزبون رفض الاستلام',
    'rejected',
    'customer_rejected',
    'cancelled_by_customer',
    'تم إلغاء الطلب',
  };

  static bool _matchesSet(String value, Set<String> set) {
    if (value.isEmpty) return false;
    return set.contains(value) || set.contains(value.toLowerCase());
  }

  /// هل الطلب تم توصيله بنجاح؟
  static bool isDelivered(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    final orderStatus = (data['orderStatus'] ?? '').toString();

    if (_matchesSet(status, _deliveredStatuses) ||
        _matchesSet(orderStatus, _deliveredStatuses)) {
      return true;
    }

    final deliveryRequest =
        data['deliveryRequest'] as Map<String, dynamic>?;
    if (deliveryRequest != null) {
      final drStatus = (deliveryRequest['status'] ?? '').toString();
      if (drStatus.toLowerCase() == 'completed') return true;
    }

    if (data['dispatchType'] == 'independent_courier') {
      final dispatchStatus = (data['status'] ?? '').toString();
      if (dispatchStatus.toLowerCase() == 'completed') return true;
    }

    return false;
  }

  /// هل الطلب مرفوض/ملغى نهائياً؟
  static bool isRejected(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    final orderStatus = (data['orderStatus'] ?? '').toString();

    if (_matchesSet(status, _rejectedStatuses) ||
        _matchesSet(orderStatus, _rejectedStatuses)) {
      return true;
    }

    if (data['isActive'] == false && !isDelivered(data)) {
      return _matchesSet(status, _rejectedStatuses) ||
          status.contains('رفض') ||
          orderStatus == 'rejected';
    }

    return false;
  }

  /// هل يجب أن يكون الطلب غير نشط (مكتمل أو مرفوض)؟
  static bool shouldBeInactive(Map<String, dynamic> data) {
    return isDelivered(data) || isRejected(data);
  }

  /// تاريخ الإكمال — يُستخدم فى الإحصائيات والفلترة
  static DateTime? getRelevantDate(Map<String, dynamic> data) {
    final completedAt = data['completedAt'];
    if (completedAt is Timestamp) return completedAt.toDate();

    final updatedAt = data['updatedAt'];
    if (updatedAt is Timestamp) return updatedAt.toDate();

    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();

    return null;
  }

  /// الحالة الخام الأكثر دقة للعرض
  static String resolveRawStatus(Map<String, dynamic> data) {
    final deliveryRequest =
        data['deliveryRequest'] as Map<String, dynamic>?;
    if (deliveryRequest != null && deliveryRequest['status'] != null) {
      return deliveryRequest['status'].toString();
    }

    if (data['dispatchType'] == 'independent_courier' &&
        data['status'] != null) {
      return data['status'].toString();
    }

    final rawStatus = (data['status'] as String?)?.trim();
    final rawOrderStatus = (data['orderStatus'] as String?)?.trim();

    const notificationOnly = {'new', 'accepted', 'rejected'};
    if (rawStatus != null &&
        notificationOnly.contains(rawStatus.toLowerCase()) &&
        rawOrderStatus != null &&
        rawOrderStatus.isNotEmpty) {
      return rawOrderStatus;
    }
    if (rawStatus != null && rawStatus.isNotEmpty) return rawStatus;
    if (rawOrderStatus != null && rawOrderStatus.isNotEmpty) {
      return rawOrderStatus;
    }
    return 'pending';
  }

  /// تحويل الحالة إلى عربية للعرض فى واجهة العميل
  static String toCustomerArabic(String status) {
    if (status == 'قيد المراجعة' ||
        status == 'تم استلام الطلب' ||
        status == 'جارى تسليم للدليفري' ||
        status == 'تم التسليم للطيار' ||
        status == 'تم التسليم' ||
        status == 'الطلب مكتمل' ||
        status == 'تم رفض الطلب' ||
        status == 'في انتظار قبول المكتب' ||
        status == 'تم قبوله من المكتب' ||
        status == 'تم تعيين مندوب' ||
        status == 'المندوب قبل الطلب' ||
        status == 'المندوب في الطريق' ||
        status == 'تم استلام الطلب من المتجر') {
      return status;
    }

    switch (status.toLowerCase()) {
      case 'new':
      case 'pending':
        return 'قيد المراجعة';
      case 'accepted':
        return 'تم استلام الطلب';
      case 'preparing':
      case 'delivering':
        return 'جارى تسليم للدليفري';
      case 'delivered':
      case 'completed':
        return 'تم التسليم';
      case 'rejected':
        return 'تم رفض الطلب';
      case 'cancelled_by_customer':
        return 'تم إلغاء الطلب';
      case 'assigned':
        return 'تم تعيين مندوب';
      case 'driver_accepted':
        return 'المندوب قبل الطلب';
      case 'picked_up':
        return 'المندوب في الطريق';
      case 'self_delivery':
        return 'التسليم الذاتي';
      default:
        return status;
    }
  }

  static int statusColor(String status) {
    final lower = status.toLowerCase();
    if (isDelivered({'status': status})) return 0xFF4CAF50;
    if (_matchesSet(status, _rejectedStatuses)) return 0xFFF44336;

    switch (lower) {
      case 'pending':
      case 'preparing':
      case 'delivering':
      case 'assigned':
      case 'driver_accepted':
      case 'picked_up':
        return 0xFFFF9800;
      case 'accepted':
        return 0xFF2196F3;
      default:
        return 0xFF9E9E9E;
    }
  }

  /// هل الطلب نشط (لم يكتمل بعد)؟
  static bool isActiveOrder(Map<String, dynamic> data) {
    if (data['isActive'] == false) return false;
    if (isDelivered(data) || isRejected(data)) return false;
    return true;
  }
}
