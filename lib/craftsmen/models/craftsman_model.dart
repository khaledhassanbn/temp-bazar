import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bazar_suez/markets/create_market/models/working_hours.dart';
import 'package:bazar_suez/craftsmen/models/price_list_item.dart';
import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';

class CraftsmanStats {
  final int profileViews;
  final int callClicks;
  final int whatsappClicks;
  final int shareClicks;
  final int searchImpressions;

  const CraftsmanStats({
    this.profileViews = 0,
    this.callClicks = 0,
    this.whatsappClicks = 0,
    this.shareClicks = 0,
    this.searchImpressions = 0,
  });

  factory CraftsmanStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CraftsmanStats();
    return CraftsmanStats(
      profileViews: (map['profileViews'] ?? 0) as int,
      callClicks: (map['callClicks'] ?? 0) as int,
      whatsappClicks: (map['whatsappClicks'] ?? 0) as int,
      shareClicks: (map['shareClicks'] ?? 0) as int,
      searchImpressions: (map['searchImpressions'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {
        'profileViews': profileViews,
        'callClicks': callClicks,
        'whatsappClicks': whatsappClicks,
        'shareClicks': shareClicks,
        'searchImpressions': searchImpressions,
      };

  int get totalContacts => callClicks + whatsappClicks;
}

class CraftsmanModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String phone;
  final String whatsapp;
  final String professionId;
  final String professionName;
  final String? groupId;
  final String description;
  final String areaName;
  final GeoPoint? location;
  final List<String> portfolioUrls;
  final List<PriceListItem> priceList;
  final WeeklyWorkingHours? workingHours;
  final bool isAvailableNow;
  final bool isSelfHidden;
  final String visibility;
  final String adminStatus;
  final List<String> badges;
  final double averageRating;
  final int totalReviews;
  final double responseRate;
  final int completedJobsCount;
  final CraftsmanStats stats;
  final String? subscriptionPlan;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final bool isFeatured;
  final DateTime? featuredUntil;
  final DateTime? lastActiveAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? fcmToken;
  final String? nationalIdImageUrl;
  final String? coverImageUrl;

  const CraftsmanModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.phone,
    required this.whatsapp,
    required this.professionId,
    required this.professionName,
    this.groupId,
    this.description = '',
    this.areaName = '',
    this.location,
    this.portfolioUrls = const [],
    this.priceList = const [],
    this.workingHours,
    this.isAvailableNow = true,
    this.isSelfHidden = false,
    this.visibility = 'public',
    this.adminStatus = 'none',
    this.badges = const [],
    this.averageRating = 0,
    this.totalReviews = 0,
    this.responseRate = 0,
    this.completedJobsCount = 0,
    this.stats = const CraftsmanStats(),
    this.subscriptionPlan,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.isFeatured = false,
    this.featuredUntil,
    this.lastActiveAt,
    required this.createdAt,
    this.updatedAt,
    this.fcmToken,
    this.nationalIdImageUrl,
    this.coverImageUrl,
  });

  bool get isPublicVisible =>
      visibility == 'public' && !isSelfHidden;

  bool get hasNewBadge => badges.contains('new');
  bool get isVerified => badges.contains('verified');

  factory CraftsmanModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? readDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    WeeklyWorkingHours? wh;
    if (map['workingHours'] != null) {
      wh = WeeklyWorkingHours.fromMap(
        Map<String, dynamic>.from(map['workingHours'] as Map),
      );
    }

    final priceRaw = map['priceList'];
    final prices = <PriceListItem>[];
    if (priceRaw is List) {
      for (final item in priceRaw) {
        if (item is Map) {
          prices.add(PriceListItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final portfolio = map['portfolioUrls'];
    final urls = portfolio is List
        ? portfolio.map((e) => e.toString()).toList()
        : <String>[];

    final badgeRaw = map['badges'];
    final badgeList = badgeRaw is List
        ? badgeRaw.map((e) => e.toString()).toList()
        : <String>[];

    return CraftsmanModel(
      id: id,
      name: (map['name'] ?? '').toString(),
      photoUrl: map['photoUrl']?.toString(),
      phone: (map['phone'] ?? '').toString(),
      whatsapp: (map['whatsapp'] ?? map['phone'] ?? '').toString(),
      professionId: (map['professionId'] ?? '').toString(),
      professionName: (map['professionName'] ?? '').toString(),
      groupId: map['groupId']?.toString(),
      description: (map['description'] ?? '').toString(),
      areaName: (map['areaName'] ?? '').toString(),
      location: map['location'] is GeoPoint ? map['location'] as GeoPoint : null,
      portfolioUrls: urls,
      priceList: prices,
      workingHours: wh,
      isAvailableNow: map['isAvailableNow'] != false,
      isSelfHidden: map['isSelfHidden'] == true,
      visibility: (map['visibility'] ?? 'public').toString(),
      adminStatus: (map['adminStatus'] ?? 'none').toString(),
      badges: badgeList,
      averageRating: (map['averageRating'] is num)
          ? (map['averageRating'] as num).toDouble()
          : 0,
      totalReviews: (map['totalReviews'] ?? 0) as int,
      responseRate: (map['responseRate'] is num)
          ? (map['responseRate'] as num).toDouble()
          : 0,
      completedJobsCount: (map['completedJobsCount'] ?? 0) as int,
      stats: CraftsmanStats.fromMap(
        map['stats'] is Map
            ? Map<String, dynamic>.from(map['stats'] as Map)
            : null,
      ),
      subscriptionPlan: map['subscriptionPlan']?.toString(),
      subscriptionStart: readDate(map['subscriptionStart']),
      subscriptionEnd: readDate(map['subscriptionEnd']),
      isFeatured: map['isFeatured'] == true,
      featuredUntil: readDate(map['featuredUntil']),
      lastActiveAt: readDate(map['lastActiveAt']),
      createdAt: readDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: readDate(map['updatedAt']),
      fcmToken: map['fcmToken']?.toString(),
      nationalIdImageUrl: map['nationalIdImageUrl']?.toString(),
      coverImageUrl: map['coverImageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap({bool includePrivate = false}) {
    final m = <String, dynamic>{
      'name': name,
      'photoUrl': photoUrl,
      'phone': phone,
      'whatsapp': whatsapp,
      'professionId': professionId,
      'professionName': professionName,
      'groupId': groupId,
      'description': description,
      'areaName': areaName,
      'location': location,
      'portfolioUrls': portfolioUrls,
      'priceList': priceList.map((e) => e.toMap()).toList(),
      'workingHours': workingHours?.toMap(),
      'isAvailableNow': isAvailableNow,
      'isSelfHidden': isSelfHidden,
      'visibility': visibility,
      'adminStatus': adminStatus,
      'badges': badges,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'responseRate': responseRate,
      'completedJobsCount': completedJobsCount,
      'stats': stats.toMap(),
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStart': subscriptionStart != null
          ? Timestamp.fromDate(subscriptionStart!)
          : null,
      'subscriptionEnd':
          subscriptionEnd != null ? Timestamp.fromDate(subscriptionEnd!) : null,
      'isFeatured': isFeatured,
      'featuredUntil':
          featuredUntil != null ? Timestamp.fromDate(featuredUntil!) : null,
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'fcmToken': fcmToken,
    };
    if (includePrivate && nationalIdImageUrl != null) {
      m['nationalIdImageUrl'] = nationalIdImageUrl;
    }
    if (coverImageUrl != null) {
      m['coverImageUrl'] = coverImageUrl;
    }
    return m;
  }

  CraftsmanListItem toListItem() {
    return CraftsmanListItem(
      id: id,
      name: name,
      photoUrl: photoUrl,
      phone: phone,
      whatsapp: whatsapp,
      professionName: professionName,
      areaName: areaName,
      averageRating: averageRating,
      totalReviews: totalReviews,
      callClicks: stats.callClicks,
      whatsappClicks: stats.whatsappClicks,
      completedJobsCount: completedJobsCount,
      badges: badges,
      isAvailableNow: isAvailableNow,
      isFeatured: isFeatured,
      coverImageUrl: coverImageUrl,
      location: location != null
          ? GeoPointHolder(location!.latitude, location!.longitude)
          : null,
    );
  }
}
