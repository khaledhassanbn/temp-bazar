import 'package:cloud_firestore/cloud_firestore.dart';

import 'independent_courier_settings.dart';

class IndependentCourierSettingsService {
  final FirebaseFirestore _firestore;

  IndependentCourierSettingsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  IndependentCourierSettings? _cachedSettings;
  DateTime? _cacheTime;
  static const _cacheValidityMinutes = 5;

  static const String _settingsPath = 'settings';
  static const String _settingsDoc = 'independent_courier';

  static const String serviceUnavailableMessage =
      'هذه الخدمة غير متاحة حاليا';

  Future<IndependentCourierSettings> getSettings({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedSettings != null && _cacheTime != null) {
      final cacheAge = DateTime.now().difference(_cacheTime!);
      if (cacheAge.inMinutes < _cacheValidityMinutes) {
        return _cachedSettings!;
      }
    }

    try {
      final doc = await _firestore
          .collection(_settingsPath)
          .doc(_settingsDoc)
          .get();

      if (doc.exists && doc.data() != null) {
        _cachedSettings = IndependentCourierSettings.fromMap(doc.data()!);
      } else {
        _cachedSettings = IndependentCourierSettings.defaults();
      }
      _cacheTime = DateTime.now();
      return _cachedSettings!;
    } catch (e) {
      return IndependentCourierSettings.defaults();
    }
  }

  Future<bool?> getStoreOverride(String marketId) async {
    try {
      final doc = await _firestore.collection('markets').doc(marketId).get();
      if (!doc.exists) return null;
      final value = doc.data()?['independentCourierEnabled'];
      if (value == null) return null;
      return value == true;
    } catch (e) {
      return null;
    }
  }

  bool isEnabled({
    required bool globalEnabled,
    required bool? storeOverride,
  }) {
    return computeEffectiveEnabled(
      globalEnabled: globalEnabled,
      storeOverride: storeOverride,
    );
  }

  static bool computeEffectiveEnabled({
    required bool globalEnabled,
    required bool? storeOverride,
  }) {
    return globalEnabled && (storeOverride ?? true);
  }

  Future<bool> isIndependentCourierEnabledForStore(String marketId) async {
    final settings = await getSettings();
    final storeOverride = await getStoreOverride(marketId);
    return isEnabled(
      globalEnabled: settings.enabled,
      storeOverride: storeOverride,
    );
  }
}
