import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessage {
  final String id;
  final String senderId;
  final String senderType; // user | admin | system
  final String? text;
  final String? imageUrl;
  final bool isSystem;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderType,
    this.text,
    this.imageUrl,
    required this.isSystem,
    required this.createdAt,
  });

  bool get isFromUser => senderType == 'user';
  bool get isFromAdmin => senderType == 'admin';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory SupportMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final createdAtTimestamp = data['createdAt'] as Timestamp?;
    final createdAt = createdAtTimestamp != null ? createdAtTimestamp.toDate() : DateTime.now();

    return SupportMessage(
      id: doc.id,
      senderId: data['senderId']?.toString() ?? '',
      senderType: data['senderType']?.toString() ?? 'user',
      text: data['text']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      isSystem: data['isSystem'] as bool? ?? false,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderType': senderType,
      'text': text ?? '',
      'imageUrl': imageUrl ?? '',
      'isSystem': isSystem,
      'createdAt': createdAt,
    };
  }
}
