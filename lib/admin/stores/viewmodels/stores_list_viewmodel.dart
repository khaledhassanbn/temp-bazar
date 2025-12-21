import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stores_service.dart';

class StoresListViewModel extends ChangeNotifier {
  final StoresService _service = StoresService();

  // متغيرات الفرز والبحث
  String _sortBy = 'name'; // name, expiryDate, productCount, status
  bool _isAscending = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, inactive

  // Getters
  String get sortBy => _sortBy;
  bool get isAscending => _isAscending;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;

  // Service getter
  StoresService get service => _service;

  // تحديث معايير الفرز
  void setSortBy(String value) {
    if (_sortBy != value) {
      _sortBy = value;
      notifyListeners();
    }
  }

  // تبديل اتجاه الفرز
  void toggleSortOrder() {
    _isAscending = !_isAscending;
    notifyListeners();
  }

  // تحديث البحث
  void setSearchQuery(String value) {
    if (_searchQuery != value) {
      _searchQuery = value;
      notifyListeners();
    }
  }

  // تحديث فلتر الحالة
  void setFilterStatus(String value) {
    if (_filterStatus != value) {
      _filterStatus = value;
      notifyListeners();
    }
  }

  // فرز وتصفية المتاجر
  List<QueryDocumentSnapshot> sortAndFilterStores(
    List<QueryDocumentSnapshot> stores,
  ) {
    // تصفية حسب الحالة
    List<QueryDocumentSnapshot> filtered = stores.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (_filterStatus == 'all') return true;
      if (_filterStatus == 'active') return data['isActive'] == true;
      if (_filterStatus == 'inactive') return data['isActive'] != true;
      return true;
    }).toList();

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // الفرز
    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      int comparison = 0;

      switch (_sortBy) {
        case 'name':
          comparison = (dataA['name'] ?? '').toString().compareTo(
            (dataB['name'] ?? '').toString(),
          );
          break;
        case 'expiryDate':
          final dateA = dataA['expiryDate'] as Timestamp?;
          final dateB = dataB['expiryDate'] as Timestamp?;
          if (dateA == null && dateB == null) {
            comparison = 0;
          } else if (dateA == null) {
            comparison = 1;
          } else if (dateB == null) {
            comparison = -1;
          } else {
            comparison = dateA.compareTo(dateB);
          }
          break;
        case 'status':
          final statusA = dataA['isActive'] == true ? 1 : 0;
          final statusB = dataB['isActive'] == true ? 1 : 0;
          comparison = statusA.compareTo(statusB);
          break;
        case 'productCount':
          final countA = dataA['totalProducts'] as int? ?? 0;
          final countB = dataB['totalProducts'] as int? ?? 0;
          comparison = countA.compareTo(countB);
          break;
      }

      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }
}
