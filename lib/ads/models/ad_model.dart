import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final int slotId;
  final String? imageUrl;
  final String? targetStoreId;
  final DateTime? startTime;
  final int durationHours;
  final bool isActive;

  AdModel({
    required this.slotId,
    this.imageUrl,
    this.targetStoreId,
    this.startTime,
    this.durationHours = 24,
    this.isActive = false,
  });

  // تحويل من Firestore
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
    );
  }

  // تحويل إلى Firestore
  Map<String, dynamic> toMap() {
    return {
      'slotId': slotId,
      'imageUrl': imageUrl,
      'targetStoreId': targetStoreId,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'durationHours': durationHours,
      'isActive': isActive,
    };
  }

  // التحقق من صلاحية الإعلان
  bool get isValid {
    if (!isActive ||
        imageUrl == null ||
        imageUrl!.isEmpty ||
        startTime == null) {
      return false;
    }

    final expiryTime = startTime!.add(Duration(hours: durationHours));
    return DateTime.now().isBefore(expiryTime);
  }

  // حساب الوقت المتبقي للإعلان بالساعات
  double get remainingHours {
    if (!isActive || startTime == null) return 0;

    final expiryTime = startTime!.add(Duration(hours: durationHours));
    final now = DateTime.now();

    if (now.isAfter(expiryTime)) return 0;

    final difference = expiryTime.difference(now);
    return difference.inMinutes / 60.0;
  }

  // تاريخ انتهاء الإعلان
  DateTime? get expiryDate {
    if (startTime == null) return null;
    return startTime!.add(Duration(hours: durationHours));
  }

  // نسخ مع تعديل
  AdModel copyWith({
    int? slotId,
    String? imageUrl,
    String? targetStoreId,
    DateTime? startTime,
    int? durationHours,
    bool? isActive,
  }) {
    return AdModel(
      slotId: slotId ?? this.slotId,
      imageUrl: imageUrl ?? this.imageUrl,
      targetStoreId: targetStoreId ?? this.targetStoreId,
      startTime: startTime ?? this.startTime,
      durationHours: durationHours ?? this.durationHours,
      isActive: isActive ?? this.isActive,
    );
  }
}
