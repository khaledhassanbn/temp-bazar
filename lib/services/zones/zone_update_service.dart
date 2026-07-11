import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'zones_data.dart';

class ZoneUpdateService {
  static const _prefsVersionKey = 'zones_version';
  static const _localFileName = 'zones_current.json';
  static const _fallbackAsset = 'assets/zones/zones_v1.json';
  static const _configDocPath = 'system/config';

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ZoneUpdateService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  Future<String> loadZonesJson() async {
    try {
      final remote = await _tryLoadRemote();
      if (remote != null) return remote;
    } catch (e) {
      debugPrint('ZoneUpdateService remote load failed: $e');
    }

    try {
      final local = await _tryLoadLocalFile();
      if (local != null) return local;
    } catch (e) {
      debugPrint('ZoneUpdateService local file load failed: $e');
    }

    return rootBundle.loadString(_fallbackAsset);
  }

  Future<String> loadFallbackAsset() => rootBundle.loadString(_fallbackAsset);

  Future<String?> _tryLoadRemote() async {
    final config = await _getRemoteConfig();
    if (config == null) return null;

    final remoteVersion = (config['currentZonesVersion'] as num?)?.toInt();
    final storagePath = config['zonesStoragePath'] as String?;
    if (remoteVersion == null || storagePath == null || storagePath.isEmpty) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final localVersion = prefs.getInt(_prefsVersionKey) ?? 0;

    if (remoteVersion <= localVersion) {
      return _tryLoadLocalFile();
    }

    final ref = _storage.ref(storagePath);
    final bytes = await ref.getData();
    if (bytes == null || bytes.isEmpty) return null;

    final jsonString = utf8.decode(bytes);
    ZonesData.fromJson(json.decode(jsonString) as Map<String, dynamic>);

    final file = await _localFile();
    await file.writeAsString(jsonString, flush: true);
    await prefs.setInt(_prefsVersionKey, remoteVersion);

    return jsonString;
  }

  Future<Map<String, dynamic>?> _getRemoteConfig() async {
    final doc = await _firestore.doc(_configDocPath).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<String?> _tryLoadLocalFile() async {
    final file = await _localFile();
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    if (content.trim().isEmpty) return null;
    return content;
  }

  Future<File> _localFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_localFileName');
  }
}
