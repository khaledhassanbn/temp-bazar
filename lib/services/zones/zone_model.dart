import 'dart:math' as math;

class ZoneCenter {
  final double lat;
  final double lng;

  const ZoneCenter({required this.lat, required this.lng});

  factory ZoneCenter.fromJson(Map<String, dynamic> json) {
    return ZoneCenter(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class Zone {
  final String id;
  final String name;
  final String district;
  final String governorate;
  final ZoneCenter center;
  final double radius;
  final List<String> aliases;
  final List<String> keywords;

  const Zone({
    required this.id,
    required this.name,
    required this.district,
    required this.governorate,
    required this.center,
    required this.radius,
    this.aliases = const [],
    this.keywords = const [],
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      center: ZoneCenter.fromJson(
        Map<String, dynamic>.from(json['center'] as Map),
      ),
      radius: (json['radius'] as num?)?.toDouble() ?? 0,
      aliases: (json['aliases'] as List?)?.cast<String>() ?? const [],
      keywords: (json['keywords'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'district': district,
        'governorate': governorate,
        'center': center.toJson(),
        'radius': radius,
        if (aliases.isNotEmpty) 'aliases': aliases,
        if (keywords.isNotEmpty) 'keywords': keywords,
      };
}

class ZoneResult {
  final Zone zone;
  final double distanceMeters;
  final bool isInsideRadius;

  const ZoneResult({
    required this.zone,
    required this.distanceMeters,
    required this.isInsideRadius,
  });
}

double haversineDistanceMeters(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  const earthRadius = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
