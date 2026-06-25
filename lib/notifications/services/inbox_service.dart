import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inbox_message_model.dart';

/// خدمة مركز الرسائل — استعلام مركزي من `announcements/` + تتبع قراءة محلي
class InboxService {
  InboxService._();
  static final InboxService instance = InboxService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _readIdsKey = 'read_announcements';
  static const _readDatesKey = 'read_announcement_dates';

  static String audienceForUserStatus(String status, {bool isCraftsman = false}) {
    if (status == 'market_owner') return 'merchants';
    if (status == 'craftsman' || isCraftsman) return 'craftsmen';
    return 'customers';
  }

  Future<Set<String>> _getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_readIdsKey) ?? []).toSet();
  }

  Future<void> _saveReadIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readIdsKey, ids.toList());
  }

  bool _matchesAudience(Map<String, dynamic> data, String audience, String userId) {
    final targetAudience = data['targetAudience']?.toString() ?? '';
    if (targetAudience == 'all' || targetAudience == audience) return true;
    if (targetAudience == 'individual') {
      return data['targetUserId']?.toString() == userId;
    }
    return false;
  }

  InboxMessageModel? _mapDoc(DocumentSnapshot doc, Set<String> readIds) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    final deliveryType = data['deliveryType']?.toString() ?? 'both';
    if (deliveryType == 'push_only') return null;

    final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
    if (sentAt == null) return null;

    return InboxMessageModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      cta: data['cta'] != null
          ? AnnouncementCTA.fromMap(data['cta'] as Map<String, dynamic>)
          : null,
      sentAt: sentAt,
      isRead: readIds.contains(doc.id),
    );
  }

  Future<List<InboxMessageModel>> _buildMessageList(
    QuerySnapshot snap, {
    required String userId,
    required String audience,
  }) async {
    final readIds = await _getReadIds();
    final messages = <InboxMessageModel>[];

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (!_matchesAudience(data, audience, userId)) continue;

      final msg = _mapDoc(doc, readIds);
      if (msg != null && !messages.any((m) => m.id == msg.id)) {
        messages.add(msg);
      }
    }

    messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    if (messages.length > 50) {
      return messages.sublist(0, 50);
    }
    return messages;
  }

  /// استعلام بفلتر `status` فقط لتجنب الحاجة لـ composite index،
  /// ثم فلترة وترتيب محلياً.
  Stream<List<InboxMessageModel>> watchInbox({
    required String userId,
    required String audience,
  }) {
    return _firestore
        .collection('announcements')
        .where('status', isEqualTo: 'sent')
        .limit(100)
        .snapshots()
        .asyncMap((snap) async {
          try {
            return await _buildMessageList(
              snap,
              userId: userId,
              audience: audience,
            );
          } catch (e) {
            return <InboxMessageModel>[];
          }
        });
  }

  Future<int> getUnreadCount({
    required String userId,
    required String audience,
  }) async {
    try {
      final snap = await _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'sent')
          .limit(100)
          .get();

      final messages = await _buildMessageList(
        snap,
        userId: userId,
        audience: audience,
      );
      return messages.where((m) => !m.isRead).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAsRead(String announcementId) async {
    final readIds = await _getReadIds();
    if (readIds.contains(announcementId)) return;

    readIds.add(announcementId);
    await _saveReadIds(readIds);

    final prefs = await SharedPreferences.getInstance();
    final dates = Map<String, String>.from(
      (prefs.getStringList(_readDatesKey) ?? []).fold<Map<String, String>>(
        {},
        (map, entry) {
          final parts = entry.split(':');
          if (parts.length == 2) map[parts[0]] = parts[1];
          return map;
        },
      ),
    );
    dates[announcementId] = DateTime.now().toIso8601String();
    await prefs.setStringList(
      _readDatesKey,
      dates.entries.map((e) => '${e.key}:${e.value}').toList(),
    );

    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'stats.inAppReadCount': FieldValue.increment(1),
      });
    } catch (_) {}
  }

  Future<InboxMessageModel?> getMessage(String announcementId) async {
    final doc =
        await _firestore.collection('announcements').doc(announcementId).get();
    if (!doc.exists) return null;
    final readIds = await _getReadIds();
    return _mapDoc(doc, readIds);
  }

  Future<void> cleanupOldReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final readIds = (prefs.getStringList(_readIdsKey) ?? []).toSet();
    final dateEntries = prefs.getStringList(_readDatesKey) ?? [];

    final keptDates = <String>[];
    final keptIds = <String>{};

    for (final entry in dateEntries) {
      final parts = entry.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final date = DateTime.tryParse(parts[1]);
      if (date != null && date.isAfter(cutoff)) {
        keptDates.add(entry);
        keptIds.add(id);
      }
    }

    final prunedIds = readIds.intersection(keptIds);
    await prefs.setStringList(_readIdsKey, prunedIds.toList());
    await prefs.setStringList(_readDatesKey, keptDates);
  }

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
}
