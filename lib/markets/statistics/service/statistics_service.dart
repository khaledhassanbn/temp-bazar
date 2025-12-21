import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StatisticsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<String?> getCurrentUserMarketId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final snake = data['market_id'];
    final camel = data['marketId'];
    final nested = data['market'];
    if (snake is String && snake.isNotEmpty) return snake;
    if (camel is String && camel.isNotEmpty) return camel;
    if (nested is Map &&
        nested['id'] is String &&
        (nested['id'] as String).isNotEmpty) {
      return nested['id'] as String;
    }
    return null;
  }

  Future<Map<String, double>> fetchMonthlyTotals({
    required String marketId,
    required int year,
  }) async {
    final doc = await _firestore
        .collection('markets')
        .doc(marketId)
        .collection('statistics')
        .doc(year.toString())
        .get();

    if (!doc.exists) return {};
    final data = doc.data() ?? {};

    final dynamic monthly = data['monthly'];
    if (monthly != null) {
      return _normalizeNumericMap(monthly, keyPad: 2);
    }
    final dynamic months = data['months'];
    if (months is Map) {
      final Map<String, double> result = {};
      months.forEach((k, v) {
        final String key = _stringKey(k, keyPad: 2);
        double? value;
        if (v is Map) {
          value = _asDouble(v['totalSales'] ?? v['sales'] ?? v['value']);
        } else {
          value = _asDouble(v);
        }
        if (value != null) result[key] = value;
      });
      return result;
    }
    return {};
  }

  Future<Map<String, double>> fetchDailyTotals({
    required String marketId,
    required int year,
    required int month,
  }) async {
    final doc = await _firestore
        .collection('markets')
        .doc(marketId)
        .collection('statistics')
        .doc(year.toString())
        .get();

    if (!doc.exists) return {};
    final data = doc.data() ?? {};

    final dynamic daily = data['daily'];
    if (daily is Map) {
      final Object? monthNode =
          daily[_monthKey(month)] ?? daily[month] ?? daily[month.toString()];
      return _normalizeNumericMap(monthNode, keyPad: 2);
    }
    // Alternative structure: days: { 'YYYY-MM-DD': { totalSales, totalOrders } }
    final dynamic days = data['days'];
    if (days is Map) {
      final String monthPrefix = '${year.toString()}-${_monthKey(month)}-';
      final Map<String, double> result = {};
      days.forEach((k, v) {
        if (k is String && k.startsWith(monthPrefix)) {
          final String day = k.substring(k.length - 2);
          double? value;
          if (v is Map) {
            value = _asDouble(v['totalSales'] ?? v['sales'] ?? v['value']);
          } else {
            value = _asDouble(v);
          }
          if (value != null) result[day] = value;
        }
      });
      return result;
    }
    return {};
  }

  Map<String, double> _normalizeNumericMap(dynamic node, {int? keyPad}) {
    final Map<String, double> result = {};

    if (node is Map) {
      node.forEach((k, v) {
        final String key = _stringKey(k, keyPad: keyPad);
        final double? numValue = _asDouble(v);
        if (numValue != null) {
          result[key] = numValue;
        }
      });
    } else if (node is List) {
      for (int i = 0; i < node.length; i++) {
        final double? numValue = _asDouble(node[i]);
        if (numValue != null) {
          final int oneBased = i + 1;
          final String key = keyPad != null
              ? oneBased.toString().padLeft(keyPad, '0')
              : oneBased.toString();
          result[key] = numValue;
        }
      }
    }
    return result;
  }

  String _monthKey(int month) => month.toString().padLeft(2, '0');

  String _stringKey(dynamic key, {int? keyPad}) {
    if (key is int) {
      return keyPad != null
          ? key.toString().padLeft(keyPad, '0')
          : key.toString();
    }
    if (key is String) {
      if (keyPad != null) {
        final parsed = int.tryParse(key);
        if (parsed != null) return parsed.toString().padLeft(keyPad, '0');
      }
      return key;
    }
    return key.toString();
  }

  double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v);
      return parsed;
    }
    return null;
  }
}
