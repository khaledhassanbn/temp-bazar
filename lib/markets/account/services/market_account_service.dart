import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSummary {
  final String uid;
  final String email;
  final String displayName;
  final String status;
  final String? avatarUrl;
  final int loyaltyPoints;
  final MarketSummary? market;

  const AccountSummary({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.status,
    required this.avatarUrl,
    required this.loyaltyPoints,
    required this.market,
  });

  bool get isMarketOwner => status == 'market_owner';
  bool get isAdmin => status == 'admin';
}

class MarketSummary {
  final String id;
  final String name;
  final String? logoUrl;

  const MarketSummary({required this.id, required this.name, this.logoUrl});
}

class ManagerProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;

  const ManagerProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'ب';
    final splitted = trimmed.split(' ');
    if (splitted.length >= 2) {
      final first = splitted[0].isNotEmpty ? splitted[0][0] : '';
      final second = splitted[1].isNotEmpty ? splitted[1][0] : '';
      final combined = '$first$second'.trim();
      return combined.isNotEmpty ? combined : trimmed[0];
    }
    return trimmed[0];
  }
}

class MarketAccountService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<AccountSummary> loadAccountSummary() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('لا يوجد مستخدم مسجل دخول');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? <String, dynamic>{};

    final status = (data['status'] as String?) ?? 'user';
    final firstName = (data['firstName'] as String?)?.trim() ?? '';
    final lastName = (data['lastName'] as String?)?.trim() ?? '';
    final customName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ').trim();
    final fallbackName = user.displayName?.trim();
    final storedEmail = data['email'];
    final resolvedEmail = storedEmail is String && storedEmail.isNotEmpty
        ? storedEmail
        : (user.email ?? '');
    final emailHandle = resolvedEmail.isNotEmpty
        ? resolvedEmail
        : 'مستخدم بازاري';
    final displayName = (customName.isNotEmpty
        ? customName
        : (fallbackName ?? emailHandle));

    final avatarUrl = (data['avatarUrl'] as String?) ?? user.photoURL;
    final pointsValue = data['points'];
    final points = pointsValue is num ? pointsValue.toInt() : 0;

    final marketId = _resolveMarketId(data);
    MarketSummary? marketSummary;
    if (marketId != null) {
      final marketSnap = await _firestore
          .collection('markets')
          .doc(marketId)
          .get();
      if (marketSnap.exists) {
        final marketData = marketSnap.data();
        if (marketData != null) {
          marketSummary = MarketSummary(
            id: marketSnap.id,
            name: (marketData['name'] as String?) ?? 'متجري',
            logoUrl: marketData['logoUrl'] as String?,
          );
        }
      }
    }

    return AccountSummary(
      uid: user.uid,
      email: emailHandle,
      displayName: displayName,
      status: status,
      avatarUrl: avatarUrl,
      loyaltyPoints: points,
      market: marketSummary,
    );
  }

  Stream<List<ManagerProfile>> watchManagers(String marketId) {
    final baseStream = _firestore
        .collection('users')
        .where('market_id', isEqualTo: marketId)
        .snapshots();

    return baseStream.asyncMap((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map(_mapManagerDoc).toList();
      }

      final fallback = await _firestore
          .collection('users')
          .where('marketId', isEqualTo: marketId)
          .get();
      if (fallback.docs.isNotEmpty) {
        return fallback.docs.map(_mapManagerDoc).toList();
      }
      return <ManagerProfile>[];
    });
  }

  Future<void> addManager(String email, String marketId) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw Exception('الرجاء إدخال البريد الإلكتروني');
    }

    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('لم يتم العثور على حساب بهذا البريد الإلكتروني');
    }

    final userDoc = query.docs.first;
    final userData = userDoc.data();
    final status = (userData['status'] as String?) ?? 'user';
    final existingMarketId = _resolveMarketId(userData);

    if (status == 'market_owner' && existingMarketId != marketId) {
      throw Exception('هذا الحساب مسؤول عن متجر آخر');
    }

    await userDoc.reference.update({
      'status': 'market_owner',
      'market_id': marketId,
    });
  }

  Future<void> removeManager(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'status': 'user',
      'market_id': FieldValue.delete(),
      'marketId': FieldValue.delete(),
      'market': FieldValue.delete(),
    });
  }

  ManagerProfile _mapManagerDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final firstName = (data['firstName'] as String?) ?? '';
    final lastName = (data['lastName'] as String?) ?? '';
    final fallbackName =
        (data['displayName'] as String?) ??
        (doc.id.substring(0, doc.id.length >= 4 ? 4 : doc.id.length));
    final displayName = [
      firstName,
      lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();

    return ManagerProfile(
      uid: doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: displayName.isNotEmpty ? displayName : fallbackName,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  String? _resolveMarketId(Map<String, dynamic> data) {
    final snake = data['market_id'];
    final camel = data['marketId'];
    final nested = data['market'];

    if (snake is String && snake.isNotEmpty) return snake;
    if (camel is String && camel.isNotEmpty) return camel;
    if (nested is Map && nested['id'] is String && nested['id'].isNotEmpty) {
      return nested['id'] as String;
    }
    return null;
  }
}
