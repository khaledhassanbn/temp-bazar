import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initial;
  const MapPickerPage({Key? key, this.initial}) : super(key: key);

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _controller;
  LatLng _center = const LatLng(30.0444, 31.2357);
  String? _address;
  bool _isInsideSuez = true;
  bool _isSatellite = false;
  final TextEditingController _searchController = TextEditingController();

  final String apiKey = "AIzaSyA9bJxVt4G17WqaUeIHmpaHfmcOhsJddYA";

  // حدود السويس التقريبية
  final double minLat = 29.8;
  final double maxLat = 30.2;
  final double minLng = 32.4;
  final double maxLng = 32.7;

  LatLng get _defaultSuezCenter => const LatLng(29.9668, 32.5498);

  LatLngBounds get _suezBounds => LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? _defaultSuezCenter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAddress(_center);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 🔍 جلب العنوان بدقة باستخدام Google Geocoding API (مع اللغة العربية)
  /// 🔍 جلب العنوان بدقة باستخدام Google Geocoding API (مع اللغة العربية)
  Future<void> _updateAddress(LatLng pos) async {
    if (!mounted) return;

    if (pos.latitude < minLat ||
        pos.latitude > maxLat ||
        pos.longitude < minLng ||
        pos.longitude > maxLng) {
      setState(() {
        _isInsideSuez = false;
        _address = "خارج نطاق محافظة السويس";
      });
      final clamped = _clampToBounds(pos);
      _controller?.animateCamera(CameraUpdate.newLatLng(clamped));
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&language=ar&key=$apiKey";
    try {
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);

      if (data["status"] == "OK" && data["results"].isNotEmpty) {
        final results = data["results"] as List;

        // 🔍 نحاول نلاقي النتيجة اللي فيها نوع "neighborhood"
        Map<String, dynamic>? neighborhoodResult;
        for (var r in results) {
          final types = (r["types"] as List?)?.cast<String>() ?? [];
          if (types.contains("neighborhood")) {
            neighborhoodResult = r;
            break;
          }
        }

        String? neighborhoodName;

        if (neighborhoodResult != null) {
          // نبحث داخل address_components
          final comps = (neighborhoodResult["address_components"] as List)
              .cast<Map<String, dynamic>>();
          for (var c in comps) {
            final types = (c["types"] as List?)?.cast<String>() ?? [];
            if (types.contains("neighborhood")) {
              neighborhoodName = c["short_name"] ?? c["long_name"];
              break;
            }
          }
        }

        // لو لاقينا اسم الحي نعرضه، غير كده نعرض أول عنوان عادي
        setState(() {
          _isInsideSuez = true;
          _address =
              neighborhoodName ?? data["results"][0]["formatted_address"];
        });
      } else {
        setState(() {
          _address = "تعذر تحديد العنوان";
        });
      }
    } catch (e) {
      setState(() {
        _address = "حدث خطأ أثناء جلب العنوان";
      });
    }
  }

  LatLng _clampToBounds(LatLng pos) {
    final lat = pos.latitude.clamp(minLat, maxLat);
    final lng = pos.longitude.clamp(minLng, maxLng);
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      final LatLng myPos = LatLng(position.latitude, position.longitude);
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(myPos, 16));
      await _updateAddress(myPos);
    } catch (_) {}
  }

  void _toggleSatelliteView() {
    if (!mounted || _controller == null) return;
    setState(() {
      _isSatellite = !_isSatellite;
    });
  }

  /// ✅ عند اختيار اقتراح من GooglePlacesAutocomplete
  Future<void> _onPlaceSelected(Prediction p) async {
    final placeId = p.placeId;
    if (placeId == null) return;

    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&language=ar&key=$apiKey";
    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data["status"] == "OK") {
      final loc = data["result"]["geometry"]["location"];
      final latLng = LatLng(loc["lat"], loc["lng"]);
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      await _updateAddress(latLng);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تحديد عنوان العميل'),
          centerTitle: true,
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            GoogleMap(
              mapType: _isSatellite ? MapType.satellite : MapType.normal,
              initialCameraPosition: CameraPosition(target: _center, zoom: 14),
              onMapCreated: (c) => _controller = c,
              onCameraMove: (pos) => _center = pos.target,
              onCameraIdle: () => _updateAddress(_center),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              buildingsEnabled: true,
              zoomControlsEnabled: false,
              cameraTargetBounds: CameraTargetBounds(_suezBounds),
            ),

            const Icon(Icons.location_pin, size: 45, color: Colors.red),

            // ✅ مربع البحث مع اقتراحات Google Places
            Positioned(
              top: 10,
              left: 15,
              right: 15,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _searchController,
                  googleAPIKey: apiKey,
                  debounceTime: 400,
                  countries: const ["eg"],
                  isLatLngRequired: false,
                  getPlaceDetailWithLatLng: (Prediction p) async {
                    await _onPlaceSelected(p);
                  },
                  itemClick: (Prediction p) async {
                    _searchController.text = p.description ?? "";
                    FocusScope.of(context).unfocus();
                    await _onPlaceSelected(p);
                  },
                  inputDecoration: const InputDecoration(
                    hintText: "ابحث عن عنوان...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  boxDecoration: const BoxDecoration(color: Colors.white),
                ),
              ),
            ),

            Positioned(
              top: 90,
              left: 20,
              child: FloatingActionButton(
                heroTag: "my_location",
                onPressed: _goToMyLocation,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),

            Positioned(
              top: 160,
              left: 20,
              child: FloatingActionButton(
                heroTag: "satellite_toggle",
                onPressed: _toggleSatelliteView,
                backgroundColor: Colors.white,
                child: Icon(
                  _isSatellite ? Icons.satellite_alt : Icons.map,
                  color: Colors.deepOrange,
                ),
              ),
            ),

            if (_address != null)
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _address!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isInsideSuez ? Colors.black87 : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _isInsideSuez
                    ? () {
                        Navigator.pop(context, {
                          "location": GeoPoint(
                            _center.latitude,
                            _center.longitude,
                          ), // GeoPoint بدلاً من نص
                          "address": _address ?? "عنوان غير معروف",
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "تأكيد الموقع",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
