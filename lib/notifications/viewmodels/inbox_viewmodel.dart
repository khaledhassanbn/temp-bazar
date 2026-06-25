import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/inbox_message_model.dart';
import '../services/inbox_service.dart';

class InboxViewModel extends ChangeNotifier {
  final InboxService _service = InboxService.instance;

  List<InboxMessageModel> _messages = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<InboxMessageModel>>? _subscription;

  List<InboxMessageModel> get messages => _messages;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize({
    required String userStatus,
    bool isCraftsman = false,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    await _service.cleanupOldReadIds();
    final audience =
        InboxService.audienceForUserStatus(userStatus, isCraftsman: isCraftsman);

    await _subscription?.cancel();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _service
        .watchInbox(userId: userId, audience: audience)
        .listen(
      (messages) {
        _messages = messages;
        _unreadCount = messages.where((m) => !m.isRead).length;
        _isLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _refreshUnreadCount(userId: userId, audience: audience);
  }

  Future<void> _refreshUnreadCount({
    required String userId,
    required String audience,
  }) async {
    try {
      _unreadCount =
          await _service.getUnreadCount(userId: userId, audience: audience);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String announcementId) async {
    await _service.markAsRead(announcementId);
    _messages = _messages
        .map((m) => m.id == announcementId ? m.copyWith(isRead: true) : m)
        .toList();
    _unreadCount = _messages.where((m) => !m.isRead).length;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
