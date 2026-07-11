import 'zone_model.dart';

class ZonesData {
  final int version;
  final List<Zone> zones;
  final List<String> governorates;
  final List<String> districts;

  const ZonesData({
    required this.version,
    required this.zones,
    this.governorates = const [],
    this.districts = const [],
  });

  factory ZonesData.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['zones'];
    if (zonesJson is! List || zonesJson.isEmpty) {
      throw FormatException('ملف المناطق يجب أن يحتوي على قائمة zones غير فارغة');
    }

    final zones = zonesJson
        .whereType<Map>()
        .map((z) => Zone.fromJson(Map<String, dynamic>.from(z)))
        .toList();

    _validateZones(zones);

    return ZonesData(
      version: (json['version'] as num?)?.toInt() ?? 0,
      zones: zones,
      governorates: (json['governorates'] as List?)?.cast<String>() ?? const [],
      districts: (json['districts'] as List?)?.cast<String>() ?? const [],
    );
  }

  static void _validateZones(List<Zone> zones) {
    final ids = <String>{};
    final names = <String>{};

    for (final zone in zones) {
      if (zone.id.isEmpty) {
        throw FormatException('كل منطقة يجب أن تحتوي على id');
      }
      if (zone.name.isEmpty) {
        throw FormatException('كل منطقة يجب أن تحتوي على name');
      }
      if (zone.radius <= 0) {
        throw FormatException('نصف قطر المنطقة "${zone.name}" غير صالح');
      }
      if (!ids.add(zone.id)) {
        throw FormatException('معرّف مكرر: ${zone.id}');
      }
      if (!names.add(zone.name)) {
        throw FormatException('اسم منطقة مكرر: ${zone.name}');
      }
    }
  }
}
