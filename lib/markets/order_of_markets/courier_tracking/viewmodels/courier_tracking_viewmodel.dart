// lib/markets/order_of_markets/courier_tracking/viewmodels/courier_tracking_viewmodel.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/courier_live_data.dart';
import '../services/courier_live_tracking_service.dart';

/// ViewModel لصفحة تتبع المندوب
/// يدير:
/// - الاستماع الفوري لبيانات RTDB
/// - حساب المسافة (Haversine) بين التاجر والمندوب لحظيًا
/// - بناء Markers وتحديث الخريطة
class CourierTrackingViewModel extends ChangeNotifier {
  final String courierId;
  final String courierName;
  final GeoPoint? merchantLocation;

  final CourierLiveTrackingService _service;

  CourierTrackingViewModel({
    required this.courierId,
    required this.courierName,
    this.merchantLocation,
    CourierLiveTrackingService? service,
  }) : _service = service ?? CourierLiveTrackingService();

  // ─── State ────────────────────────────────────────────────────────────────
  CourierLiveData? _courierData;
  CourierLiveData? get courierData => _courierData;

  /// المسافة بالمتر بين التاجر والمندوب
  double? get distanceInMeters {
    if (_courierData == null || merchantLocation == null) return null;
    if (_courierData!.latitude == 0 && _courierData!.longitude == 0) {
      return null;
    }
    return CourierLiveData.haversineMeters(
      merchantLocation!.latitude,
      merchantLocation!.longitude,
      _courierData!.latitude,
      _courierData!.longitude,
    );
  }

  /// المسافة بالكيلومتر
  double? get distanceInKm {
    final m = distanceInMeters;
    if (m == null) return null;
    return m / 1000.0;
  }

  /// نص المسافة للعرض
  String get distanceText {
    final m = distanceInMeters;
    if (m == null) return '—';
    if (m < 1000) return '${m.round()} م';
    return '${(m / 1000).toStringAsFixed(1)} كم';
  }

  /// نص الحالة للعرض
  String get statusText {
    switch (_courierData?.status) {
      case CourierStatus.online:
        return 'متاح';
      case CourierStatus.busy:
        return 'مشغول';
      case CourierStatus.offline:
        return 'غير متاح';
      case null:
        return '—';
    }
  }

  /// لون الحالة
  Color get statusColor {
    switch (_courierData?.status) {
      case CourierStatus.online:
        return const Color(0xFF4CAF50); // 🟢
      case CourierStatus.busy:
        return const Color(0xFFFF9800); // 🟠
      case CourierStatus.offline:
        return const Color(0xFF757575); // ⚫
      case null:
        return const Color(0xFF757575);
    }
  }

  /// موقع المندوب الحالي كـ LatLng
  LatLng? get courierLatLng {
    if (_courierData == null) return null;
    if (_courierData!.latitude == 0 && _courierData!.longitude == 0) {
      return null;
    }
    return LatLng(_courierData!.latitude, _courierData!.longitude);
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ─── Google Map Controller ────────────────────────────────────────────────
  GoogleMapController? _mapController;

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // إذا كان الموقع متاحًا بالفعل نتوجه إليه
    final loc = courierLatLng;
    if (loc != null) {
      _animateToLocation(loc);
    }
  }

  // ─── Markers ──────────────────────────────────────────────────────────────
  Set<Marker> get markers {
    final Set<Marker> result = {};

    // Marker موقع التاجر
    if (merchantLocation != null) {
      result.add(
        Marker(
          markerId: const MarkerId('merchant'),
          position: LatLng(
            merchantLocation!.latitude,
            merchantLocation!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'موقع المتجر'),
        ),
      );
    }

    // Marker المندوب مع Rotation باستخدام heading
    final loc = courierLatLng;
    if (loc != null) {
      result.add(
        Marker(
          markerId: MarkerId('courier_$courierId'),
          position: loc,
          rotation: _courierData?.heading ?? 0.0,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _courierMarkerHue,
          ),
          infoWindow: InfoWindow(
            title: courierName,
            snippet: statusText,
          ),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    return result;
  }

  /// لون Marker المندوب حسب الحالة
  double get _courierMarkerHue {
    switch (_courierData?.status) {
      case CourierStatus.online:
        return BitmapDescriptor.hueGreen;
      case CourierStatus.busy:
        return BitmapDescriptor.hueOrange;
      case CourierStatus.offline:
        return BitmapDescriptor.hueViolet;
      case null:
        return BitmapDescriptor.hueViolet;
    }
  }

  // ─── Stream subscription ──────────────────────────────────────────────────
  StreamSubscription<CourierLiveData?>? _subscription;

  void init() {
    _subscription = _service.streamCourierLive(courierId).listen(
      (data) {
        _courierData = data;
        _isLoading = false;
        _error = null;

        // تحريك الكاميرا لموقع المندوب الجديد
        final loc = courierLatLng;
        if (loc != null && _mapController != null) {
          _animateToLocation(loc);
        }

        notifyListeners();
      },
      onError: (e) {
        _error = 'تعذر تحميل بيانات المندوب: $e';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _animateToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(location),
    );
  }

  /// إعادة ضبط الكاميرا لتشمل موقع التاجر والمندوب معًا
  void fitBothLocations() {
    final courierLoc = courierLatLng;
    if (merchantLocation == null || courierLoc == null) return;

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        [merchantLocation!.latitude, courierLoc.latitude].reduce(
          (a, b) => a < b ? a : b,
        ),
        [merchantLocation!.longitude, courierLoc.longitude].reduce(
          (a, b) => a < b ? a : b,
        ),
      ),
      northeast: LatLng(
        [merchantLocation!.latitude, courierLoc.latitude].reduce(
          (a, b) => a > b ? a : b,
        ),
        [merchantLocation!.longitude, courierLoc.longitude].reduce(
          (a, b) => a > b ? a : b,
        ),
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
