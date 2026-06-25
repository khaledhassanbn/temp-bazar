import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionalPopupModel {
  final String id;
  final String? title;
  final String? description;
  final String imageUrl;
  final PromotionalPopupCTA? cta;
  final String targetAudience;
  final bool isActive;
  final int priority;
  final DateTime startDate;
  final DateTime endDate;
  final int maxImpressions;
  final bool isDismissible;

  PromotionalPopupModel({
    required this.id,
    this.title,
    this.description,
    required this.imageUrl,
    this.cta,
    required this.targetAudience,
    required this.isActive,
    required this.priority,
    required this.startDate,
    required this.endDate,
    required this.maxImpressions,
    required this.isDismissible,
  });

  factory PromotionalPopupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PromotionalPopupModel(
      id: doc.id,
      title: data['title']?.toString(),
      description: data['description']?.toString(),
      imageUrl: data['imageUrl']?.toString() ?? '',
      cta: data['cta'] != null
          ? PromotionalPopupCTA.fromMap(data['cta'] as Map<String, dynamic>)
          : null,
      targetAudience: data['targetAudience']?.toString() ?? 'all',
      isActive: data['isActive'] == true,
      priority: (data['priority'] ?? 0) as int,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      maxImpressions: (data['maxImpressions'] ?? 0) as int,
      isDismissible: data['isDismissible'] != false,
    );
  }
}

class PromotionalPopupCTA {
  final String type;
  final String value;

  PromotionalPopupCTA({required this.type, required this.value});

  factory PromotionalPopupCTA.fromMap(Map<String, dynamic> map) {
    return PromotionalPopupCTA(
      type: map['type']?.toString() ?? 'open_page',
      value: map['value']?.toString() ?? '',
    );
  }
}
