import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bazar_suez/craftsmen/models/craftsman_filter_options.dart';
import 'package:bazar_suez/craftsmen/services/craftsman_search_service.dart';

class CraftsmenHomeViewModel extends ChangeNotifier {
  final CraftsmanSearchService _search = CraftsmanSearchService();

  List<CraftsmanSearchResult> featured = [];
  List<CraftsmanSearchResult> nearby = [];
  List<CraftsmanSearchResult> topRated = [];
  List<CraftsmanSearchResult> mostContacted = [];
  List<CraftsmanSearchResult> newest = [];

  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;

  Future<void> load({GeoPoint? userLoc, bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing = true;
    } else {
      isLoading = true;
    }
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _search.featured(userLoc: userLoc),
        _search.nearby(userLoc: userLoc),
        _search.topRated(userLoc: userLoc),
        _search.mostContacted(userLoc: userLoc),
        _search.newest(userLoc: userLoc),
      ]);
      featured = results[0];
      nearby = results[1];
      topRated = results[2];
      mostContacted = results[3];
      newest = results[4];
    } catch (e) {
      errorMessage = 'حدث خطأ أثناء تحميل البيانات. يرجى التحقق من اتصال الإنترنت.';
      featured = [];
      nearby = [];
      topRated = [];
      mostContacted = [];
      newest = [];
    }

    isLoading = false;
    isRefreshing = false;
    notifyListeners();
  }
}
