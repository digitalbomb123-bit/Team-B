import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Audio manager supporting local death sound effects and playback.
class AudioManager {
  static final AudioPlayer _deathPlayer = AudioPlayer();
  static bool _hasDeathSound = false;
  static bool _checked = false;

  /// Check if the local death.mp3 audio asset exists in assets/audio/
  static Future<void> init() async {
    if (_checked) return;
    _checked = true;
    try {
      await rootBundle.load('assets/audio/death.mp3');
      _hasDeathSound = true;
    } catch (_) {
      _hasDeathSound = false;
    }
  }

  /// Plays the local death sound if assets/audio/death.mp3 exists
  static Future<void> playDeathSound() async {
    await init();
    if (!_hasDeathSound) return;
    try {
      await _deathPlayer.stop();
      await _deathPlayer.play(AssetSource('audio/death.mp3'));
    } catch (_) {
      // Audio playback fails gracefully without breaking game state
    }
  }
}
