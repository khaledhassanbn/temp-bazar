import 'delivery_fee_zone.dart';

/// نموذج إعدادات رسوم التوصيل
/// يتم تخزينه في Firestore في settings/delivery_fee
class DeliveryFeeSettings {
  final List<DeliveryFeeZone> zones;

  DeliveryFeeSettings({
    List<DeliveryFeeZone>? zones,
  }) : zones = zones ?? _defaultZones;

  static const List<DeliveryFeeZone> _defaultZones = [
    DeliveryFeeZone(from: 0, to: 2, fee: 25),
    DeliveryFeeZone(from: 2, to: 5, fee: 35),
    DeliveryFeeZone(from: 5, to: 8, fee: 50),
  ];

  /// القيم الافتراضية
  factory DeliveryFeeSettings.defaults() => DeliveryFeeSettings();

  /// إنشاء من Map (Firestore)
  factory DeliveryFeeSettings.fromMap(Map<String, dynamic> map) {
    final zonesData = map['zones'];
    if (zonesData is List && zonesData.isNotEmpty) {
      return DeliveryFeeSettings(
        zones: zonesData
            .whereType<Map>()
            .map((zone) => DeliveryFeeZone.fromMap(Map<String, dynamic>.from(zone)))
            .toList(),
      );
    }
    return DeliveryFeeSettings.defaults();
  }

  /// تحويل إلى Map للحفظ في Firestore
  Map<String, dynamic> toMap() {
    return {
      'zones': sortedZones.map((zone) => zone.toMap()).toList(),
    };
  }

  List<DeliveryFeeZone> get sortedZones {
    final sorted = List<DeliveryFeeZone>.from(zones);
    sorted.sort((a, b) => a.from.compareTo(b.from));
    return sorted;
  }

  /// رسوم افتراضية عند عدم توفر المسافة
  double get fallbackFee {
    final sorted = sortedZones;
    if (sorted.isEmpty) return 0;
    return sorted.first.fee;
  }

  /// التحقق من صحة النطاقات قبل الحفظ
  static String? validateZones(List<DeliveryFeeZone> zones) {
    if (zones.isEmpty) {
      return 'يجب إضافة منطقة واحدة على الأقل';
    }

    for (var i = 0; i < zones.length; i++) {
      final zone = zones[i];
      if (zone.from >= zone.to) {
        return 'في المنطقة ${i + 1}: قيمة "من" يجب أن تكون أقل من "إلى"';
      }
      if (zone.fee <= 0) {
        return 'في المنطقة ${i + 1}: الرسوم يجب أن تكون أكبر من صفر';
      }
    }

    final sorted = List<DeliveryFeeZone>.from(zones)
      ..sort((a, b) => a.from.compareTo(b.from));

    for (var i = 0; i < sorted.length; i++) {
      for (var j = i + 1; j < sorted.length; j++) {
        if (sorted[i].from == sorted[j].from && sorted[i].to == sorted[j].to) {
          return 'يوجد نطاقات مكررة (${sorted[i].from} - ${sorted[i].to} كم)';
        }
      }
      if (i > 0 && sorted[i].from < sorted[i - 1].to) {
        return 'النطاقات متداخلة بين ${sorted[i - 1].from}-${sorted[i - 1].to} و ${sorted[i].from}-${sorted[i].to} كم';
      }
    }

    return null;
  }

  /// نسخ مع تعديل
  DeliveryFeeSettings copyWith({
    List<DeliveryFeeZone>? zones,
  }) {
    return DeliveryFeeSettings(
      zones: zones ?? this.zones,
    );
  }

  @override
  String toString() {
    return 'DeliveryFeeSettings(zones: $zones)';
  }
}
