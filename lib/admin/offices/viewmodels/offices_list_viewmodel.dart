import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/offices_service.dart';

class OfficesListViewModel extends ChangeNotifier {
  final OfficesService _service = OfficesService();

  // متغيرات الفرز والبحث
  String _sortBy = 'createdAt'; // name, createdAt, status
  bool _isAscending = false; // false = تنازلي (الأحدث أولاً)
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, active, blocked

  // Getters
  String get sortBy => _sortBy;
  bool get isAscending => _isAscending;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;

  // Service getter
  OfficesService get service => _service;

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

  // فرز وتصفية المكاتب
  List<QueryDocumentSnapshot> sortAndFilterOffices(
    List<QueryDocumentSnapshot> offices,
  ) {
    // تصفية حسب الحالة
    List<QueryDocumentSnapshot> filtered = offices.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (_filterStatus == 'all') return true;
      if (_filterStatus == 'active') return data['status'] == 'active';
      if (_filterStatus == 'blocked') return data['status'] == 'blocked';
      return true;
    }).toList();

    // تصفية حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final phone = (data['phone'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            phone.contains(query);
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
        case 'createdAt':
          final dateA = dataA['createdAt'] as Timestamp?;
          final dateB = dataB['createdAt'] as Timestamp?;
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
          final statusA = dataA['status'] == 'active' ? 1 : 0;
          final statusB = dataB['status'] == 'active' ? 1 : 0;
          comparison = statusA.compareTo(statusB);
          break;
      }

      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }
}
