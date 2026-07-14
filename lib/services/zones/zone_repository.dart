import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'zone_model.dart';
import 'zone_update_service.dart';
import 'zones_data.dart';

class ZoneRepository {
  ZoneRepository._();

  static final ZoneRepository instance = ZoneRepository._();

  final ZoneUpdateService _updateService = ZoneUpdateService();

  ZonesData? _data;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized && _data != null) return;

    try {
      final jsonString = await _updateService.loadZonesJson();
      _loadFromJsonString(jsonString);
    } catch (e, st) {
      debugPrint('ZoneRepository init failed, trying asset fallback: $e\n$st');
      try {
        final jsonString = await _updateService.loadFallbackAsset();
        _loadFromJsonString(jsonString);
      } catch (fallbackError) {
        debugPrint('ZoneRepository fallback failed: $fallbackError');
        _data = null;
        _initialized = false;
      }
    }
  }

  /// يضمن تحميل بيانات المناطق قبل الاستخدام (مثلاً عند فتح الخريطة).
  Future<void> ensureInitialized() async {
    if (_initialized && _data != null) return;
    await initialize();
  }

  void _loadFromJsonString(String jsonString) {
    final decoded = json.decode(jsonString) as Map<String, dynamic>;
    _data = ZonesData.fromJson(decoded);
    _initialized = true;
    debugPrint(
      'ZoneRepository initialized: v${_data!.version}, ${_data!.zones.length} zones',
    );
  }

  ZoneResult? findNearestZone(double lat, double lng) {
    final zones = _data?.zones;
    if (zones == null || zones.isEmpty) return null;

    Zone? insideZone;
    double? insideDistance;

    for (final zone in zones) {
      final distance = haversineDistanceMeters(
        lat,
        lng,
        zone.center.lat,
        zone.center.lng,
      );
      if (distance <= zone.radius) {
        if (insideDistance == null || distance < insideDistance) {
          insideZone = zone;
          insideDistance = distance;
        }
      }
    }

    if (insideZone != null && insideDistance != null) {
      return ZoneResult(
        zone: insideZone,
        distanceMeters: insideDistance,
        isInsideRadius: true,
      );
    }

    Zone nearest = zones.first;
    double nearestDistance = haversineDistanceMeters(
      lat,
      lng,
      nearest.center.lat,
      nearest.center.lng,
    );

    for (final zone in zones.skip(1)) {
      final distance = haversineDistanceMeters(
        lat,
        lng,
        zone.center.lat,
        zone.center.lng,
      );
      if (distance < nearestDistance) {
        nearest = zone;
        nearestDistance = distance;
      }
    }

    return ZoneResult(
      zone: nearest,
      distanceMeters: nearestDistance,
      isInsideRadius: false,
    );
  }

  String getZoneName(double lat, double lng) {
    final result = findNearestZone(lat, lng);
    if (result == null) return 'موقع غير معروف';
    return result.zone.name;
  }

  List<Zone> getAllZones() => List.unmodifiable(_data?.zones ?? const []);
}
