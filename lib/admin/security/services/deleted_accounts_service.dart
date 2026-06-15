import 'package:cloud_firestore/cloud_firestore.dart';

class DeletedAccountModel {
  final String uid;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? status;
  final String? accountType;
  final DateTime? deletedAt;
  final String? deletedBy;

  const DeletedAccountModel({
    required this.uid,
    this.email,
    this.firstName,
    this.lastName,
    this.status,
    this.accountType,
    this.deletedAt,
    this.deletedBy,
  });

  String get displayName {
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : (email ?? uid);
  }

  factory DeletedAccountModel.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    return DeletedAccountModel(
      uid: uid,
      email: data['email'] as String?,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      status: data['status'] as String?,
      accountType: _resolveAccountType(data),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      deletedBy: data['deletedBy'] as String?,
    );
  }

  static String _resolveAccountType(Map<String, dynamic> data) {
    if (data['craftsmanProfileActive'] == true) return 'craftsman';
    if (data['market_id'] != null || data['marketId'] != null) {
      return 'store';
    }
    final status = data['status'] as String?;
    if (status == 'courier') return 'courier';
    return 'user';
  }
}

class DeletedAccountsService {
  DeletedAccountsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<DeletedAccountModel>> watchDeletedAccounts({int limit = 50}) {
    return _firestore
        .collection('users')
        .where('isDeleted', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snap) => _sortByDeletedAt(
              snap.docs
                  .map((d) => DeletedAccountModel.fromFirestore(d.id, d.data()))
                  .toList(),
            ));
  }

  Future<List<DeletedAccountModel>> fetchDeletedAccounts({int limit = 50}) async {
    final snap = await _firestore
        .collection('users')
        .where('isDeleted', isEqualTo: true)
        .limit(limit)
        .get();
    return _sortByDeletedAt(
      snap.docs
          .map((d) => DeletedAccountModel.fromFirestore(d.id, d.data()))
          .toList(),
    );
  }

  List<DeletedAccountModel> _sortByDeletedAt(List<DeletedAccountModel> accounts) {
    final sorted = List<DeletedAccountModel>.from(accounts);
    sorted.sort((a, b) {
      final aDate = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return sorted;
  }
}
