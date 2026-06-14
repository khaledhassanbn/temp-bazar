/// خيارات فلترة وترتيب عرض الصنايعية.
enum CraftsmanSortBy {
  distance,
  rating,
  contactCount,
  newest,
}

class CraftsmanFilterOptions {
  final String? professionId;
  final String? groupId;
  final String? areaQuery;
  final double? maxDistanceKm;
  final double minRating;
  final int minContactCount;
  final CraftsmanSortBy sortBy;
  final bool sortAscending;

  const CraftsmanFilterOptions({
    this.professionId,
    this.groupId,
    this.areaQuery,
    this.maxDistanceKm,
    this.minRating = 0,
    this.minContactCount = 0,
    this.sortBy = CraftsmanSortBy.distance,
    this.sortAscending = true,
  });

  CraftsmanFilterOptions copyWith({
    String? professionId,
    String? groupId,
    String? areaQuery,
    double? maxDistanceKm,
    double? minRating,
    int? minContactCount,
    CraftsmanSortBy? sortBy,
    bool? sortAscending,
    bool clearMaxDistance = false,
  }) {
    return CraftsmanFilterOptions(
      professionId: professionId ?? this.professionId,
      groupId: groupId ?? this.groupId,
      areaQuery: areaQuery ?? this.areaQuery,
      maxDistanceKm:
          clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      minRating: minRating ?? this.minRating,
      minContactCount: minContactCount ?? this.minContactCount,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  bool get hasActiveFilters =>
      (professionId != null && professionId!.isNotEmpty) ||
      (groupId != null && groupId!.isNotEmpty) ||
      (areaQuery != null && areaQuery!.trim().isNotEmpty) ||
      maxDistanceKm != null ||
      minRating > 0 ||
      minContactCount > 0;

  static const List<double> distancePresetsKm = [5, 10, 20, 50];
  static const List<double> ratingPresets = [3, 4, 4.5];
  static const List<int> contactCountPresets = [5, 20, 50];
}

/// نتيجة بحث مع بيانات مشتقة للعرض.
class CraftsmanSearchResult {
  final CraftsmanListItem craftsman;
  final double? distanceKm;

  const CraftsmanSearchResult({required this.craftsman, this.distanceKm});

  int get totalContacts =>
      craftsman.callClicks + craftsman.whatsappClicks;

  String get distanceText {
    final d = distanceKm;
    if (d == null) return '—';
    if (d < 1) return '${(d * 1000).round()} م';
    return '${d.toStringAsFixed(1)} كم';
  }
}

/// نسخة خفيفة للقوائم.
class CraftsmanListItem {
  final String id;
  final String name;
  final String? photoUrl;
  final String phone;
  final String whatsapp;
  final String professionName;
  final String? areaName;
  final double averageRating;
  final int totalReviews;
  final int callClicks;
  final int whatsappClicks;
  final int completedJobsCount;
  final List<String> badges;
  final bool isAvailableNow;
  final bool isFeatured;
  final GeoPointHolder? location;
  final String? coverImageUrl;

  bool get hasNewBadge => badges.contains('new');

  const CraftsmanListItem({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.phone,
    required this.whatsapp,
    required this.professionName,
    this.areaName,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.callClicks = 0,
    this.whatsappClicks = 0,
    this.completedJobsCount = 0,
    this.badges = const [],
    this.isAvailableNow = true,
    this.isFeatured = false,
    this.location,
    this.coverImageUrl,
  });
}

/// تجنب استيراد cloud_firestore في ملف الفلتر للعرض فقط.
class GeoPointHolder {
  final double latitude;
  final double longitude;
  const GeoPointHolder(this.latitude, this.longitude);
}
