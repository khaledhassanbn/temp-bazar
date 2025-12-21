// lib/markets/pages/create_store/map_picker_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';

class MapPickerPage extends StatefulWidget {
  final LatLng? initial;
  const MapPickerPage({Key? key, this.initial}) : super(key: key);

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _controller;
  LatLng _picked = const LatLng(29.9668, 32.5498); // 🟢 مركز السويس الافتراضي
  String? _address;
  bool _isSatellite = false;
  final TextEditingController _searchController = TextEditingController();

  final String apiKey = "AIzaSyA9bJxVt4G17WqaUeIHmpaHfmcOhsJddYA"; // 🔑 ضع مفتاح Google API هنا

  // حدود محافظة السويس التقريبية
  final double minLat = 29.8;
  final double maxLat = 30.2;
  final double minLng = 32.4;
  final double maxLng = 32.7;

  LatLngBounds get _suezBounds => LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

  @override
  void initState() {
    super.initState();
    _picked = widget.initial ?? const LatLng(29.9668, 32.5498);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 🔍 جلب العنوان من Google Geocoding API
  Future<void> _updateAddress(LatLng pos) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${pos.latitude},${pos.longitude}&language=ar&key=$apiKey";

    try {
      final res = await http.get(Uri.parse(url));
      final data = json.decode(res.body);

      if (data["status"] == "OK" && data["results"].isNotEmpty) {
        setState(() {
          _address = data["results"][0]["formatted_address"];
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

  /// 🔁 ضمان بقاء النقطة داخل حدود السويس
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

      final LatLng myPos = LatLng(position.latitude, position.longitude);
      final inside = _clampToBounds(myPos);
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(inside, 16));
      setState(() => _picked = inside);
      await _updateAddress(inside);
    } catch (_) {}
  }

  void _toggleSatelliteView() {
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
      final inside = _clampToBounds(latLng);
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(inside, 16));
      setState(() => _picked = inside);
      await _updateAddress(inside);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اختر موقع المتجر'),
          centerTitle: true,
        ),
        body: Container(
          color: Colors.grey[200],
          child: Stack(
            alignment: Alignment.center,
            children: [
              GoogleMap(
                mapType: _isSatellite ? MapType.satellite : MapType.normal,
                initialCameraPosition:
                    CameraPosition(target: _picked, zoom: 14),
                onMapCreated: (c) {
                  _controller = c;
                  // ✅ أول ما الخريطة تتكون فعلاً، نحرك الكاميرا ونجيب العنوان
                  _controller!.moveCamera(
                      CameraUpdate.newLatLngZoom(_picked, 14));
                  _updateAddress(_picked);
                },
                onCameraMove: (pos) => _picked = _clampToBounds(pos.target),
                onCameraIdle: () => _updateAddress(_picked),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                cameraTargetBounds: CameraTargetBounds(_suezBounds),
              ),

              if (_controller == null)
                const Center(child: CircularProgressIndicator()),

              const Icon(Icons.location_pin, size: 45, color: Colors.red),

              // ✅ مربع البحث
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

              // أزرار التحكم
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
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                  ),
                ),

              // زر تأكيد الموقع
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _picked);
                  },
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
      ),
    );
  }
}
