import 'package:cloud_firestore/cloud_firestore.dart';

class IndependentCourier {
  final String uid;
  final String name;
  final String phone;
  final String photoUrl;
  final double? rating;
  final String vehicleType;

  final bool isApproved;

  final bool isOnline;
  final String? currentOrderId;
  final double? latitude;
  final double? longitude;

  final double? distanceKmFromStore;

  const IndependentCourier({
    required this.uid,
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.rating,
    required this.vehicleType,
    required this.isApproved,
    required this.isOnline,
    required this.currentOrderId,
    required this.latitude,
    required this.longitude,
    required this.distanceKmFromStore,
  });

  bool get canReceiveOrders =>
      isApproved && isOnline && (currentOrderId == null || currentOrderId!.isEmpty);

  IndependentCourier copyWith({
    String? uid,
    String? name,
    String? phone,
    String? photoUrl,
    double? rating,
    String? vehicleType,
    bool? isApproved,
    bool? isOnline,
    String? currentOrderId,
    double? latitude,
    double? longitude,
    double? distanceKmFromStore,
  }) {
    return IndependentCourier(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      vehicleType: vehicleType ?? this.vehicleType,
      isApproved: isApproved ?? this.isApproved,
      isOnline: isOnline ?? this.isOnline,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKmFromStore: distanceKmFromStore ?? this.distanceKmFromStore,
    );
  }

  static IndependentCourier fromCourierRequestDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status = (data['status'] ?? 'pending').toString().toLowerCase();

    final name = (data['name'] ??
            data['fullName'] ??
            data['full_name'] ??
            data['userName'] ??
            data['user_name'] ??
            data['displayName'] ??
            data['display_name'] ??
            '')
        .toString()
        .trim();

    final phone =
        (data['phone'] ?? data['phoneNumber'] ?? data['phone_number'] ?? '')
            .toString()
            .trim();

    final vehicleType =
        (data['vehicleType'] ?? data['vehicle_type'] ?? data['vehicle'] ?? '')
            .toString()
            .trim();

    final photoUrl = (data['profileImage'] ??
            data['personalPhoto'] ??
            data['personal_photo'] ??
            data['photoUrl'] ??
            data['photo_url'] ??
            data['personalImage'] ??
            data['personal_image'] ??
            data['image'] ??
            data['photo'] ??
            data['avatar'] ??
            data['avatarUrl'] ??
            data['avatar_url'] ??
            '')
        .toString()
        .trim();

    double? rating;
    final ratingRaw = data['rating'] ?? data['rate'];
    if (ratingRaw is num) rating = ratingRaw.toDouble();
    if (rating == null && ratingRaw != null) {
      rating = double.tryParse(ratingRaw.toString());
    }

    return IndependentCourier(
      uid: (data['courierUid'] ?? data['uid'] ?? data['userId'] ?? doc.id)
          .toString(),
      name: name.isEmpty ? 'مندوب' : name,
      phone: phone,
      photoUrl: photoUrl,
      rating: rating,
      vehicleType: vehicleType.isEmpty ? 'غير محدد' : vehicleType,
      isApproved: status == 'approved',
      isOnline: false,
      currentOrderId: null,
      latitude: null,
      longitude: null,
      distanceKmFromStore: null,
    );
  }
}

