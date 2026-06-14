import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'package:bazar_suez/craftsmen/data/craftsman_categories.dart';
import 'package:bazar_suez/craftsmen/models/craftsman_model.dart';
import 'package:bazar_suez/markets/create_market/models/working_hours.dart';

class CraftsmanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('craftsmen');

  Future<bool> hasProfile(String uid) async {
    final doc = await _col.doc(uid).get();
    return doc.exists;
  }

  Future<CraftsmanModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CraftsmanModel.fromMap(doc.id, doc.data()!);
  }

  Stream<CraftsmanModel?> watchById(String id) {
    return _col.doc(id).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return CraftsmanModel.fromMap(snap.id, snap.data()!);
    });
  }

  Future<List<CraftsmanModel>> fetchPublicCraftsmen({
    String? professionId,
    String? groupId,
    int limit = 200,
  }) async {
    Query<Map<String, dynamic>> q = _col.where('visibility', isEqualTo: 'public');

    if (professionId != null && professionId.isNotEmpty) {
      q = q.where('professionId', isEqualTo: professionId);
    } else if (groupId != null && groupId.isNotEmpty) {
      q = q.where('groupId', isEqualTo: groupId);
    }

    final snap = await q.limit(limit).get();
    final list = <CraftsmanModel>[];
    for (final doc in snap.docs) {
      final m = CraftsmanModel.fromMap(doc.id, doc.data());
      if (m.isSelfHidden || m.visibility == 'banned') continue;
      list.add(m);
    }
    return list;
  }

  Future<void> createOrUpdateProfile({
    required String name,
    required String phone,
    required String whatsapp,
    required String professionId,
    required String description,
    required String areaName,
    GeoPoint? location,
    String? photoUrl,
    String? nationalIdImageUrl,
    String? coverImageUrl,
    List<String> portfolioUrls = const [],
    List<Map<String, dynamic>> priceList = const [],
    WeeklyWorkingHours? workingHours,
    bool isUpdate = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول');

    final profession = findProfessionById(professionId);
    if (profession == null) throw Exception('المهنة غير صالحة');

    final now = DateTime.now();
    final uid = user.uid;
    final ref = _col.doc(uid);

    final data = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'whatsapp': whatsapp.trim(),
      'professionId': professionId,
      'professionName': profession.nameAr,
      'groupId': profession.groupId,
      'description': description.trim(),
      'areaName': areaName.trim(),
      'location': location,
      'photoUrl': photoUrl,
      'coverImageUrl': coverImageUrl,
      'portfolioUrls': portfolioUrls.take(10).toList(),
      'priceList': priceList,
      'workingHours': workingHours?.toMap(),
      'visibility': 'public',
      'isSelfHidden': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

    if (!isUpdate) {
      final subEnd = now.add(const Duration(days: 60));
      data.addAll({
        'createdAt': FieldValue.serverTimestamp(),
        'badges': ['new'],
        'adminStatus': 'none',
        'averageRating': 0.0,
        'totalReviews': 0,
        'responseRate': 0.0,
        'completedJobsCount': 0,
        'isAvailableNow': true,
        'stats': {
          'profileViews': 0,
          'callClicks': 0,
          'whatsappClicks': 0,
          'shareClicks': 0,
          'searchImpressions': 0,
        },
        'subscriptionPlan': 'free_trial',
        'subscriptionStart': Timestamp.fromDate(now),
        'subscriptionEnd': Timestamp.fromDate(subEnd),
        'isFeatured': false,
      });
      if (nationalIdImageUrl != null) {
        data['nationalIdImageUrl'] = nationalIdImageUrl;
      }
      await ref.set(data, SetOptions(merge: true));
      await _firestore.collection('users').doc(uid).set(
        {'craftsmanProfileActive': true},
        SetOptions(merge: true),
      );
    } else {
      if (nationalIdImageUrl != null) {
        data['nationalIdImageUrl'] = nationalIdImageUrl;
      }
      await ref.set(data, SetOptions(merge: true));
    }
  }

  Future<void> updateAvailability({
    required bool isAvailableNow,
    bool? isSelfHidden,
    WeeklyWorkingHours? workingHours,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('يجب تسجيل الدخول');
    final data = <String, dynamic>{
      'isAvailableNow': isAvailableNow,
      'lastActiveAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (isSelfHidden != null) data['isSelfHidden'] = isSelfHidden;
    if (workingHours != null) data['workingHours'] = workingHours.toMap();
    await _col.doc(uid).update(data);
  }

  Future<void> incrementStat(String craftsmanId, String statField) async {
    await _col.doc(craftsmanId).update({
      'stats.$statField': FieldValue.increment(1),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadImage(File file, String folder) async {
    final uid = _auth.currentUser?.uid ?? 'anon';
    final id = _uuid.v4();
    final ref = _storage.ref().child('craftsmen/$uid/$folder/$id.jpg');
    final snap = await ref.putFile(file);
    return snap.ref.getDownloadURL();
  }

  Future<void> touchLastActive() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return;
    await _col.doc(uid).update({
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }
}
