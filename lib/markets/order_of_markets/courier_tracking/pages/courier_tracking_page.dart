// lib/markets/order_of_markets/courier_tracking/pages/courier_tracking_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../viewmodels/courier_tracking_viewmodel.dart';

/// صفحة تتبع المندوب لحظيًا على الخريطة
/// الاستخدام:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => CourierTrackingPage(
///       courierId: 'uid_المندوب',
///       courierName: 'محمد أحمد',
///       merchantLocation: GeoPoint(29.9668, 32.5498),
///     ),
///   ),
/// );
/// ```
class CourierTrackingPage extends StatelessWidget {
  final String courierId;
  final String courierName;
  final GeoPoint? merchantLocation;

  const CourierTrackingPage({
    super.key,
    required this.courierId,
    required this.courierName,
    this.merchantLocation,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CourierTrackingViewModel(
        courierId: courierId,
        courierName: courierName,
        merchantLocation: merchantLocation,
      )..init(),
      child: const _CourierTrackingView(),
    );
  }
}

class _CourierTrackingView extends StatelessWidget {
  const _CourierTrackingView();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Consumer<CourierTrackingViewModel>(
          builder: (context, vm, child) {
            return Stack(
              children: [
                // ── الخريطة ─────────────────────────────────────────────
                _MapLayer(vm: vm),

                // ── AppBar شفاف ─────────────────────────────────────────
                const _TransparentAppBar(),

                // ── بطاقة المعلومات السفلية ──────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _InfoCard(vm: vm),
                ),

                // ── زر ضبط العرض ─────────────────────────────────────────
                Positioned(
                  bottom: 220,
                  left: 16,
                  child: _FitBoundsButton(vm: vm),
                ),

                // ── Loading overlay ──────────────────────────────────────
                if (vm.isLoading)
                  const _LoadingOverlay(),

                // ── Error overlay ────────────────────────────────────────
                if (vm.error != null && !vm.isLoading)
                  _ErrorOverlay(message: vm.error!),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// الخريطة
// ─────────────────────────────────────────────────────────────────────────────
class _MapLayer extends StatelessWidget {
  final CourierTrackingViewModel vm;

  const _MapLayer({required this.vm});

  @override
  Widget build(BuildContext context) {
    // موقع ابتدائي: إذا كان موقع التاجر متاحًا نبدأ منه وإلا مركز السويس
    final LatLng initialTarget = vm.merchantLocation != null
        ? LatLng(vm.merchantLocation!.latitude, vm.merchantLocation!.longitude)
        : const LatLng(29.9668, 32.5498);

    return GoogleMap(
      onMapCreated: vm.onMapCreated,
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 14,
      ),
      markers: vm.markers,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppBar شفاف فوق الخريطة
// ─────────────────────────────────────────────────────────────────────────────
class _TransparentAppBar extends StatelessWidget {
  const _TransparentAppBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  'تتبع المندوب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // توازن مع زر الرجوع
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// بطاقة المعلومات السفلية
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final CourierTrackingViewModel vm;

  const _InfoCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final courier = vm.courierData;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // ── اسم المندوب + الحالة ──
          Row(
            children: [
              // أيقونة المندوب
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: vm.statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delivery_dining_rounded,
                  color: vm.statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.courierName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusBadge(
                      label: vm.statusText,
                      color: vm.statusColor,
                    ),
                  ],
                ),
              ),

              // السرعة (إن كانت متاحة)
              if (courier != null && courier.speed > 0)
                _InfoChip(
                  icon: Icons.speed_rounded,
                  value: '${courier.speed.toStringAsFixed(0)} كم/س',
                  color: Colors.blue,
                ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── المسافة والاتجاه والوقت ──
          Row(
            children: [
              _DetailItem(
                icon: Icons.social_distance_rounded,
                label: 'المسافة',
                value: vm.distanceText,
                color: Colors.orange,
              ),
              const SizedBox(width: 12),
              _DetailItem(
                icon: Icons.navigation_rounded,
                label: 'الاتجاه',
                value: courier != null
                    ? '${courier.heading.toStringAsFixed(0)}°'
                    : '—',
                color: Colors.purple,
              ),
              const SizedBox(width: 12),
              _DetailItem(
                icon: Icons.access_time_rounded,
                label: 'آخر تحديث',
                value: _formatLastUpdate(courier?.lastLocationUpdate),
                color: Colors.teal,
              ),
            ],
          ),

          // ── Live indicator ──
          if (courier != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PulsingDot(color: vm.statusColor),
                  const SizedBox(width: 6),
                  Text(
                    'تتبع مباشر',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatLastUpdate(int? timestamp) {
    if (timestamp == null || timestamp == 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    return 'منذ ${diff.inHours} س';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets مساعدة
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// نقطة نابضة تدل على الاتصال المباشر
class _PulsingDot extends StatefulWidget {
  final Color color;

  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// زر لضبط الكاميرا لتشمل موقعي التاجر والمندوب
class _FitBoundsButton extends StatelessWidget {
  final CourierTrackingViewModel vm;

  const _FitBoundsButton({required this.vm});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'fit_bounds',
      backgroundColor: Colors.white,
      elevation: 4,
      onPressed: vm.fitBothLocations,
      child: const Icon(Icons.fit_screen_rounded, color: Colors.black87),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('جاري تحميل موقع المندوب...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  final String message;

  const _ErrorOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
