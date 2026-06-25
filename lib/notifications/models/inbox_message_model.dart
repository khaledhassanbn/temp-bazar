/// نموذج رسالة مركز الرسائل — مبني من إعلان Firestore + حالة القراءة المحلية
class InboxMessageModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final AnnouncementCTA? cta;
  final DateTime sentAt;
  final bool isRead;

  InboxMessageModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.cta,
    required this.sentAt,
    required this.isRead,
  });

  InboxMessageModel copyWith({bool? isRead}) {
    return InboxMessageModel(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      cta: cta,
      sentAt: sentAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class AnnouncementCTA {
  final String type;
  final String label;
  final String value;

  AnnouncementCTA({
    required this.type,
    required this.label,
    required this.value,
  });

  factory AnnouncementCTA.fromMap(Map<String, dynamic> map) {
    return AnnouncementCTA(
      type: map['type']?.toString() ?? 'open_page',
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }
}
