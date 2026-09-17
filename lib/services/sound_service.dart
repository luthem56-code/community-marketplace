import 'package:flutter/services.dart';

class SoundService {
  /// Plays a clean, native audio feedback chime on Web and Mobile
  static void playChime() {
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Success chime for completed sales / escrow release
  static void playSuccess() {
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }
}