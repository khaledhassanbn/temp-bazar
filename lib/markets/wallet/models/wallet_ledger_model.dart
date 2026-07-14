import 'package:cloud_firestore/cloud_firestore.dart';

/// أنواع حركات المحفظة
class WalletLedgerType {
  static const String walletRecharge = 'wallet_recharge';
  static const String subscriptionPayment = 'subscription_payment';
  static const String orderCommission = 'order_commission';
  static const String manualAdjustment = 'manual_adjustment';
  static const String refund = 'refund';
  static const String autoRenewal = 'auto_renewal';

  /// اسم عربي للنوع
  static String arabicName(String type) {
    switch (type) {
      case walletRecharge:
        return 'شحن محفظة';
      case subscriptionPayment:
        return 'دفع اشتراك';
      case orderCommission:
        return 'عمولة طلب';
      case manualAdjustment:
        return 'تعديل يدوي';
      case refund:
        return 'استرداد';
      case autoRenewal:
        return 'تجديد تلقائي';
      default:
        return type;
    }
  }

  /// هل هذا النوع يمثل خصم (مبلغ سالب)؟
  static bool isDebit(String type) {
    return type == orderCommission ||
        type == subscriptionPayment ||
        type == autoRenewal;
  }
}

/// سجل حركة واحدة في المحفظة
class WalletLedgerEntry {
  final String id;
  final String storeId;
  final String userId;
  final String type;
  final double amount; // سالب للخصم، موجب للإيداع
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceId;
  final String? referenceType;
  final String description;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  WalletLedgerEntry({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceId,
    this.referenceType,
    required this.description,
    required this.createdAt,
    this.metadata,
  });

  factory WalletLedgerEntry.fromJson(Map<String, dynamic> json) {
    return WalletLedgerEntry(
      id: json['id'] ?? '',
      storeId: json['storeId'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      amount: _toDouble(json['amount']),
      balanceBefore: _toDouble(json['balanceBefore']),
      balanceAfter: _toDouble(json['balanceAfter']),
      referenceId: json['referenceId'],
      referenceType: json['referenceType'],
      description: json['description'] ?? '',
      createdAt: _parseCreatedAt(json['createdAt']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseCreatedAt(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      return value > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'userId': userId,
      'type': type,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'referenceId': referenceId,
      'referenceType': referenceType,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }

  /// هل هذه العملية خصم؟
  bool get isDebit => amount < 0;

  /// القيمة المطلقة للمبلغ
  double get absoluteAmount => amount.abs();
}
