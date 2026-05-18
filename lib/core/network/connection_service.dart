import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// يتابع حالة الاتصال بالشبكة والإنترنت الفعلي.
class ConnectionService extends ChangeNotifier {
  ConnectionService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _fallbackPollTimer;

  bool _pluginAvailable = true;
  bool _isOnline = true;
  bool _isChecking = false;

  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;

  Future<void> initialize() async {
    if (await _tryStartConnectivityPlugin()) return;

    await _checkInternetOnly(notify: false);
    _startFallbackPolling();
    notifyListeners();
  }

  Future<bool> _tryStartConnectivityPlugin() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _applyConnectivityResults(results, notify: false);

      _subscription = _connectivity.onConnectivityChanged.listen(
        _applyConnectivityResults,
        onError: (_) => _enableFallbackMode(),
      );

      notifyListeners();
      return true;
    } on MissingPluginException {
      _enableFallbackMode();
      return false;
    } on PlatformException {
      _enableFallbackMode();
      return false;
    }
  }

  void _enableFallbackMode() {
    if (!_pluginAvailable) return;
    _pluginAvailable = false;
    _subscription?.cancel();
    _subscription = null;
    _startFallbackPolling();
  }

  void _startFallbackPolling() {
    _fallbackPollTimer?.cancel();
    _fallbackPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkInternetOnly(),
    );
  }

  Future<void> _applyConnectivityResults(
    List<ConnectivityResult> results, {
    bool notify = true,
  }) async {
    if (!_hasNetworkInterface(results)) {
      _setOnline(false, notify: notify);
      return;
    }

    final hasInternet = await _hasInternetAccess();
    _setOnline(hasInternet, notify: notify);
  }

  Future<void> _checkInternetOnly({bool notify = true}) async {
    final hasInternet = await _hasInternetAccess();
    _setOnline(hasInternet, notify: notify);
  }

  /// يتحقق من الاتصال يدوياً (زر إعادة المحاولة).
  Future<bool> checkConnection() async {
    if (_isChecking) return _isOnline;

    _isChecking = true;
    notifyListeners();

    try {
      if (_pluginAvailable) {
        try {
          final results = await _connectivity.checkConnectivity();
          if (!_hasNetworkInterface(results)) {
            _setOnline(false);
            return false;
          }
        } on MissingPluginException {
          _enableFallbackMode();
        } on PlatformException {
          _enableFallbackMode();
        }
      }

      final hasInternet = await _hasInternetAccess();
      _setOnline(hasInternet);
      return hasInternet;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  bool _hasNetworkInterface(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'one.one.one.one',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _setOnline(bool value, {bool notify = true}) {
    if (_isOnline == value) return;
    _isOnline = value;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _fallbackPollTimer?.cancel();
    super.dispose();
  }
}
