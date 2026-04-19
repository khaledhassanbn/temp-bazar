import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'order_notification_constants.dart';

/// تشغيل صوت التنبيه بشكل مُتكرر حتى يتوقف صراحةً (زر قبول / رفض أو إيقاف خارجي).
class OrderAlertSoundService {
  OrderAlertSoundService();

  AudioPlayer? _player;

  Future<void> startAlertLoop() async {
    try {
      _player ??= AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.stop();
      await _player!.play(AssetSource(kOrderAlertAssetPath));
    } catch (e, st) {
      debugPrint('OrderAlertSoundService.startAlertLoop failed: $e\n$st');
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e, st) {
      debugPrint('OrderAlertSoundService.stop failed: $e\n$st');
    }
  }

  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
    _player = null;
  }
}
