import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inbox_message_model.dart';

/// خدمة مركز الرسائل — استعلام مركزي من `announcements/` + تتبع قراءة محلي
class InboxService {
  InboxService._();
  static final InboxService instance = InboxService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _readIdsKey = 'read_announcements';
  static const _readDatesKey = 'read_announcement_dates';
  static const _dateEntrySeparator = '|';

  Set<String>? _readIdsCache;
  String? _readIdsCacheUserId;

  String _scopedKey(String baseKey) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return userId != null ? '${baseKey}_$userId' : baseKey;
  }

  /// id|iso8601 — الفاصل | لأن تواريخ ISO8601 تحتوي على :
  static (String id, DateTime date)? _parseDateEntry(String entry) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains(_dateEntrySeparator)) {
      final sepIndex = trimmed.indexOf(_dateEntrySeparator);
      final id = trimmed.substring(0, sepIndex);
      final date = DateTime.tryParse(trimmed.substring(sepIndex + 1));
      if (id.isNotEmpty && date != null) return (id, date);
      return null;
    }

    // دعم الإدخالات القديمة: أول : فقط يفصل بين المعرّف والتاريخ
    final colonIndex = trimmed.indexOf(':');
    if (colonIndex <= 0) return null;
    final id = trimmed.substring(0, colonIndex);
    final date = DateTime.tryParse(trimmed.substring(colonIndex + 1));
    if (id.isEmpty || date == null) return null;
    return (id, date);
  }

  static String _formatDateEntry(String id, DateTime date) {
    return '$id$_dateEntrySeparator${date.toIso8601String()}';
  }

  Future<Set<String>> _getReadIds() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (_readIdsCache != null && _readIdsCacheUserId == userId) {
      return Set<String>.from(_readIdsCache!);
    }

    final prefs = await SharedPreferences.getInstance();
    final scopedKey = _scopedKey(_readIdsKey);
    var ids = (prefs.getStringList(scopedKey) ?? []).toSet();

    // ترحيل البيانات القديمة (مفتاح عام بدون userId)
    if (ids.isEmpty && userId != null) {
      final legacyIds = (prefs.getStringList(_readIdsKey) ?? []).toSet();
      if (legacyIds.isNotEmpty) {
        ids = legacyIds;
        await prefs.setStringList(scopedKey, ids.toList());
      }
    }

    _readIdsCache = ids;
    _readIdsCacheUserId = userId;
    return Set<String>.from(ids);
  }

  Future<void> _saveReadIds(Set<String> ids) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    _readIdsCache = Set<String>.from(ids);
    _readIdsCacheUserId = userId;

    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
      _scopedKey(_readIdsKey),
      ids.toList(),
    );
    if (!saved) {
      debugPrint('InboxService: failed to persist read announcement ids');
    }
  }

  static String audienceForUserStatus(String status, {bool isCraftsman = false}) {
    if (status == 'market_owner') return 'merchants';
    if (status == 'craftsman' || isCraftsman) return 'craftsmen';
    return 'customers';
  }

  Future<List<String>> _loadDateEntries(SharedPreferences prefs) async {
    final scopedDatesKey = _scopedKey(_readDatesKey);
    var entries = prefs.getStringList(scopedDatesKey) ?? [];

    if (entries.isEmpty) {
      final legacyEntries = prefs.getStringList(_readDatesKey) ?? [];
      if (legacyEntries.isNotEmpty) {
        entries = legacyEntries;
        await prefs.setStringList(scopedDatesKey, entries);
      }
    }

    return entries;
  }

  Future<Map<String, DateTime>> _loadReadDates(SharedPreferences prefs) async {
    final dates = <String, DateTime>{};
    for (final entry in await _loadDateEntries(prefs)) {
      final parsed = _parseDateEntry(entry);
      if (parsed != null) {
        dates[parsed.$1] = parsed.$2;
      }
    }
    return dates;
  }

  Future<void> _saveReadDates(
    SharedPreferences prefs,
    Map<String, DateTime> dates,
  ) async {
    final entries =
        dates.entries.map((e) => _formatDateEntry(e.key, e.value)).toList();
    await prefs.setStringList(_scopedKey(_readDatesKey), entries);
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

  /// حفظ معرفات الرسائل المقروءة محلياً فقط (SharedPreferences).
  Future<void> _appendReadIds(Iterable<String> ids) async {
    final readIds = await _getReadIds();
    final prefs = await SharedPreferences.getInstance();
    final dates = await _loadReadDates(prefs);
    final now = DateTime.now();
    var changed = false;

    for (final id in ids) {
      if (readIds.add(id)) {
        dates[id] = now;
        changed = true;
      }
    }

    if (!changed) return;

    await _saveReadIds(readIds);
    await _saveReadDates(prefs, dates);
  }

  Future<void> markAsRead(String announcementId) async {
    await _appendReadIds([announcementId]);
  }

  Future<void> markAllAsRead(Iterable<String> announcementIds) async {
    await _appendReadIds(announcementIds);
  }

  Future<InboxMessageModel?> getMessage(String announcementId) async {
    final doc =
        await _firestore.collection('announcements').doc(announcementId).get();
    if (!doc.exists) return null;
    final readIds = await _getReadIds();
    return _mapDoc(doc, readIds);
  }

  /// يحذف فقط السجلات الأقدم من 90 يوماً — لا يمسح كل القراءات عند فشل التحليل.
  Future<void> cleanupOldReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final readIds = await _getReadIds();
    final dateEntries = await _loadDateEntries(prefs);

    final keptDates = <String>[];
    final expiredIds = <String>{};

    for (final entry in dateEntries) {
      final parsed = _parseDateEntry(entry);
      if (parsed == null) {
        keptDates.add(entry);
        continue;
      }

      final (id, date) = parsed;
      if (date.isAfter(cutoff)) {
        keptDates.add(_formatDateEntry(id, date));
      } else {
        expiredIds.add(id);
      }
    }

    if (expiredIds.isEmpty && keptDates.length == dateEntries.length) {
      return;
    }

    if (expiredIds.isNotEmpty) {
      readIds.removeAll(expiredIds);
      await _saveReadIds(readIds);
    }

    await prefs.setStringList(_scopedKey(_readDatesKey), keptDates);
  }

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
}
