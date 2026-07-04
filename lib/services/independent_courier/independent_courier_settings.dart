import 'package:cloud_firestore/cloud_firestore.dart';

/// إعدادات تفعيل طلب المناديب على مستوى التطبيق
/// يُخزَّن في Firestore: settings/independent_courier
class IndependentCourierSettings {
  final bool enabled;

  const IndependentCourierSettings({this.enabled = true});

  factory IndependentCourierSettings.defaults() =>
      const IndependentCourierSettings(enabled: true);

  factory IndependentCourierSettings.fromMap(Map<String, dynamic> map) {
    return IndependentCourierSettings(
      enabled: map['enabled'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  IndependentCourierSettings copyWith({bool? enabled}) {
    return IndependentCourierSettings(enabled: enabled ?? this.enabled);
  }
}
