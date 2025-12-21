import 'package:cloud_firestore/cloud_firestore.dart';

/// نموذج العنوان المحفوظ
class SavedLocation {
  final String id;
  final String name; // اسم العنوان (البيت، العمل، المتجر، إلخ)
  final String address; // العنوان النصي
  final GeoPoint location; // الإحداثيات
  final bool isDefault; // هل هو العنوان الافتراضي
  final DateTime createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    this.isDefault = false,
    required this.createdAt,
  });

  /// إنشاء من Firestore
  factory SavedLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedLocation(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// تحويل لـ Map للحفظ في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'location': location,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// نسخة معدلة
  SavedLocation copyWith({
    String? id,
    String? name,
    String? address,
    GeoPoint? location,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// أيقونة حسب اسم العنوان
  String get iconName {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('بيت') || lowerName.contains('منزل') || lowerName.contains('home')) {
      return 'home';
    } else if (lowerName.contains('عمل') || lowerName.contains('شغل') || lowerName.contains('work') || lowerName.contains('office')) {
      return 'work';
    } else if (lowerName.contains('متجر') || lowerName.contains('محل') || lowerName.contains('store') || lowerName.contains('shop')) {
      return 'store';
    }
    return 'location';
  }
}
