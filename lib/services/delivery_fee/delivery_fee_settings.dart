import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج إعدادات رسوم التوصيل
/// يتم تخزينه في Firestore في settings/delivery_fee
class DeliveryFeeSettings {
  /// المسافة الأساسية (افتراضي 2 كم)
  final double baseDistance;
  
  /// الرسوم الأساسية للمسافة الأساسية (افتراضي 30 جنيه)
  final double baseFee;
  
  /// الحد الأقصى للمستوى الأول (افتراضي 5 كم)
  final double tier1MaxDistance;
  
  /// سعر الكيلومتر في المستوى الأول (افتراضي 1 جنيه)
  final double tier1FeePerKm;
  
  /// الحد الأقصى للمستوى الثاني (افتراضي 100 كم)
  final double tier2MaxDistance;
  
  /// سعر الكيلومتر في المستوى الثاني (افتراضي 3 جنيه)
  final double tier2FeePerKm;

  DeliveryFeeSettings({
    this.baseDistance = 2.0,
    this.baseFee = 30.0,
    this.tier1MaxDistance = 5.0,
    this.tier1FeePerKm = 1.0,
    this.tier2MaxDistance = 100.0,
    this.tier2FeePerKm = 3.0,
  });

  /// القيم الافتراضية
  factory DeliveryFeeSettings.defaults() => DeliveryFeeSettings();

  /// إنشاء من Map (Firestore)
  factory DeliveryFeeSettings.fromMap(Map<String, dynamic> map) {
    return DeliveryFeeSettings(
      baseDistance: (map['baseDistance'] ?? 2.0).toDouble(),
      baseFee: (map['baseFee'] ?? 30.0).toDouble(),
      tier1MaxDistance: (map['tier1MaxDistance'] ?? 5.0).toDouble(),
      tier1FeePerKm: (map['tier1FeePerKm'] ?? 1.0).toDouble(),
      tier2MaxDistance: (map['tier2MaxDistance'] ?? 100.0).toDouble(),
      tier2FeePerKm: (map['tier2FeePerKm'] ?? 3.0).toDouble(),
    );
  }

  /// تحويل إلى Map للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'baseDistance': baseDistance,
      'baseFee': baseFee,
      'tier1MaxDistance': tier1MaxDistance,
      'tier1FeePerKm': tier1FeePerKm,
      'tier2MaxDistance': tier2MaxDistance,
      'tier2FeePerKm': tier2FeePerKm,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// نسخ مع تعديل
  DeliveryFeeSettings copyWith({
    double? baseDistance,
    double? baseFee,
    double? tier1MaxDistance,
    double? tier1FeePerKm,
    double? tier2MaxDistance,
    double? tier2FeePerKm,
  }) {
    return DeliveryFeeSettings(
      baseDistance: baseDistance ?? this.baseDistance,
      baseFee: baseFee ?? this.baseFee,
      tier1MaxDistance: tier1MaxDistance ?? this.tier1MaxDistance,
      tier1FeePerKm: tier1FeePerKm ?? this.tier1FeePerKm,
      tier2MaxDistance: tier2MaxDistance ?? this.tier2MaxDistance,
      tier2FeePerKm: tier2FeePerKm ?? this.tier2FeePerKm,
    );
  }

  @override
  String toString() {
    return 'DeliveryFeeSettings(baseDistance: $baseDistance, baseFee: $baseFee, tier1MaxDistance: $tier1MaxDistance, tier1FeePerKm: $tier1FeePerKm, tier2MaxDistance: $tier2MaxDistance, tier2FeePerKm: $tier2FeePerKm)';
  }
}
