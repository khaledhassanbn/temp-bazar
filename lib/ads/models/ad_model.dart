import 'package:cloud_firestore/cloud_firestore.dart';

/// أنواع التوجيه عند النقر على الإعلان
class AdTargetType {
  static const String store = 'store';
  static const String craftsman = 'craftsman';
  static const String imageOnly = 'image_only';
}

/// من أنشأ الإعلان
class AdCreatedBy {
  static const String admin = 'admin';
  static const String merchant = 'merchant';
  static const String craftsman = 'craftsman';
}

class AdModel {
  final int slotId;
  final String? imageUrl;
  final String? targetStoreId;
  final DateTime? startTime;
  final int durationHours;
  final bool isActive;
  final String? createdBy;
  final String? ownerUid;
  final String? ownerName;
  final bool isPaused;
  final String? targetType;
  final double price;
  final String? requestId;

  AdModel({
    required this.slotId,
    this.imageUrl,
    this.targetStoreId,
    this.startTime,
    this.durationHours = 24,
    this.isActive = false,
    this.createdBy,
    this.ownerUid,
    this.ownerName,
    this.isPaused = false,
    this.targetType,
    this.price = 0,
    this.requestId,
  });

  factory AdModel.fromMap(Map<String, dynamic> map) {
    return AdModel(
      slotId: map['slotId'] ?? 0,
      imageUrl: map['imageUrl'],
      targetStoreId: map['targetStoreId'],
      startTime: map['startTime'] != null
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      durationHours: map['durationHours'] ?? 24,
      isActive: map['isActive'] ?? false,
      createdBy: map['createdBy'],
      ownerUid: map['ownerUid'],
      ownerName: map['ownerName'],
      isPaused: map['isPaused'] ?? false,
      targetType: map['targetType'] ?? AdTargetType.store,
      price: (map['price'] ?? 0.0).toDouble(),
      requestId: map['requestId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slotId': slotId,
      'imageUrl': imageUrl,
      'targetStoreId': targetStoreId,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'durationHours': durationHours,
      'isActive': isActive,
      if (createdBy != null) 'createdBy': createdBy,
      if (ownerUid != null) 'ownerUid': ownerUid,
      if (ownerName != null) 'ownerName': ownerName,
      'isPaused': isPaused,
      if (targetType != null) 'targetType': targetType,
      'price': price,
      if (requestId != null) 'requestId': requestId,
    };
  }

  bool get isValid {
    if (!isActive ||
        isPaused ||
        imageUrl == null ||
        imageUrl!.isEmpty ||
        startTime == null) {
      return false;
    }

    final expiryTime = startTime!.add(Duration(hours: durationHours));
    return DateTime.now().isBefore(expiryTime);
  }

  bool get isExpired {
    if (startTime == null) return false;
    return DateTime.now().isAfter(
      startTime!.add(Duration(hours: durationHours)),
    );
  }

  bool get isScheduled {
    if (!isActive || isPaused || startTime == null) return false;
    return DateTime.now().isBefore(startTime!);
  }

  double get remainingHours {
    if (!isActive || startTime == null) return 0;

    final expiryTime = startTime!.add(Duration(hours: durationHours));
    final now = DateTime.now();

    if (now.isAfter(expiryTime)) return 0;

    return expiryTime.difference(now).inMinutes / 60.0;
  }

  DateTime? get expiryDate {
    if (startTime == null) return null;
    return startTime!.add(Duration(hours: durationHours));
  }

  String get effectiveTargetType => targetType ?? AdTargetType.store;

  AdModel copyWith({
    int? slotId,
    String? imageUrl,
    String? targetStoreId,
    DateTime? startTime,
    int? durationHours,
    bool? isActive,
    String? createdBy,
    String? ownerUid,
    String? ownerName,
    bool? isPaused,
    String? targetType,
    double? price,
    String? requestId,
  }) {
    return AdModel(
      slotId: slotId ?? this.slotId,
      imageUrl: imageUrl ?? this.imageUrl,
      targetStoreId: targetStoreId ?? this.targetStoreId,
      startTime: startTime ?? this.startTime,
      durationHours: durationHours ?? this.durationHours,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
      isPaused: isPaused ?? this.isPaused,
      targetType: targetType ?? this.targetType,
      price: price ?? this.price,
      requestId: requestId ?? this.requestId,
    );
  }
}
