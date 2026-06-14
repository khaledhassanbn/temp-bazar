import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_service.dart';

/// بحث وفلترة الصنايعية: المسافة، التقييم، عدد التواصلات (الطلبات).
class CraftsmanSearchService {
  final CraftsmanService _craftsmanService = CraftsmanService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double d) => d * math.pi / 180;

  Future<GeoPoint?> _userLocation() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data();
    if (data?['location'] is GeoPoint) return data!['location'] as GeoPoint;

    final saved = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_locations')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();

    if (saved.docs.isNotEmpty &&
        saved.docs.first.data()['location'] is GeoPoint) {
      return saved.docs.first.data()['location'] as GeoPoint;
    }

    final any = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('saved_locations')
        .limit(1)
        .get();
    if (any.docs.isNotEmpty && any.docs.first.data()['location'] is GeoPoint) {
      return any.docs.first.data()['location'] as GeoPoint;
    }
    return null;
  }

  /// جلب وفلترة وترتيب الصنايعية حسب اختيارات المستخدم.
  Future<List<CraftsmanSearchResult>> search(CraftsmanFilterOptions filters, {GeoPoint? userLoc}) async {
    final craftsmen = await _craftsmanService.fetchPublicCraftsmen(
      professionId: filters.professionId,
      groupId: filters.groupId,
    );

    final loc = userLoc ?? await _userLocation();
    final areaQ = filters.areaQuery?.trim().toLowerCase() ?? '';

    final results = <CraftsmanSearchResult>[];

    for (final c in craftsmen) {
      if (areaQ.isNotEmpty &&
          !c.areaName.toLowerCase().contains(areaQ) &&
          !c.name.toLowerCase().contains(areaQ)) {
        continue;
      }

      if (filters.minRating > 0 && c.averageRating < filters.minRating) {
        continue;
      }

      final contacts = c.stats.totalContacts;
      if (filters.minContactCount > 0 && contacts < filters.minContactCount) {
        continue;
      }

      double? distKm;
      if (c.location != null && loc != null) {
        distKm = _haversineKm(
          loc.latitude,
          loc.longitude,
          c.location!.latitude,
          c.location!.longitude,
        );
        if (filters.maxDistanceKm != null &&
            distKm > filters.maxDistanceKm!) {
          continue;
        }
      } else if (filters.maxDistanceKm != null && loc != null) {
        continue;
      }

      results.add(CraftsmanSearchResult(
        craftsman: c.toListItem(),
        distanceKm: distKm,
      ));
    }

    _sortResults(results, filters);
    return results;
  }

  void _sortResults(List<CraftsmanSearchResult> list, CraftsmanFilterOptions f) {
    int compare<T extends Comparable>(T a, T b) =>
        f.sortAscending ? a.compareTo(b) : b.compareTo(a);

    switch (f.sortBy) {
      case CraftsmanSortBy.distance:
        list.sort((a, b) {
          final da = a.distanceKm;
          final db = b.distanceKm;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return compare(da, db);
        });
        break;
      case CraftsmanSortBy.rating:
        list.sort((a, b) {
          final cmp = compare(
            a.craftsman.averageRating,
            b.craftsman.averageRating,
          );
          if (cmp != 0) return cmp;
          return compare(
            a.craftsman.totalReviews,
            b.craftsman.totalReviews,
          );
        });
        break;
      case CraftsmanSortBy.contactCount:
        list.sort((a, b) => compare(
              a.totalContacts + a.craftsman.completedJobsCount,
              b.totalContacts + b.craftsman.completedJobsCount,
            ));
        break;
      case CraftsmanSortBy.newest:
        list.sort((a, b) {
          if (a.craftsman.hasNewBadge && !b.craftsman.hasNewBadge) return -1;
          if (!a.craftsman.hasNewBadge && b.craftsman.hasNewBadge) return 1;
          return 0;
        });
        break;
    }
  }

  Future<List<CraftsmanSearchResult>> featured({int limit = 10, GeoPoint? userLoc}) async {
    final all = await search(const CraftsmanFilterOptions(
      sortBy: CraftsmanSortBy.rating,
      sortAscending: false,
    ), userLoc: userLoc);
    return all.where((r) => r.craftsman.isFeatured).take(limit).toList();
  }

  Future<List<CraftsmanSearchResult>> nearby({int limit = 10, GeoPoint? userLoc}) async {
    return (await search(const CraftsmanFilterOptions(
      maxDistanceKm: 50,
      sortBy: CraftsmanSortBy.distance,
    ), userLoc: userLoc))
        .take(limit)
        .toList();
  }

  Future<List<CraftsmanSearchResult>> topRated({int limit = 10, GeoPoint? userLoc}) async {
    return (await search(const CraftsmanFilterOptions(
      minRating: 1,
      sortBy: CraftsmanSortBy.rating,
      sortAscending: false,
    ), userLoc: userLoc))
        .where((r) => r.craftsman.averageRating >= 3)
        .take(limit)
        .toList();
  }

  Future<List<CraftsmanSearchResult>> mostContacted({int limit = 10, GeoPoint? userLoc}) async {
    return (await search(const CraftsmanFilterOptions(
      sortBy: CraftsmanSortBy.contactCount,
      sortAscending: false,
    ), userLoc: userLoc))
        .take(limit)
        .toList();
  }

  Future<List<CraftsmanSearchResult>> newest({int limit = 10, GeoPoint? userLoc}) async {
    final craftsmen = await _craftsmanService.fetchPublicCraftsmen();
    craftsmen.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final loc = userLoc ?? await _userLocation();
    final out = <CraftsmanSearchResult>[];
    for (final c in craftsmen.take(limit)) {
      double? dist;
      if (c.location != null && loc != null) {
        dist = _haversineKm(
          loc.latitude,
          loc.longitude,
          c.location!.latitude,
          c.location!.longitude,
        );
      }
      out.add(CraftsmanSearchResult(craftsman: c.toListItem(), distanceKm: dist));
    }
    return out;
  }
}
