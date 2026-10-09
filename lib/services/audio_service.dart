import 'package:flutter/services.dart';

enum SoundEffectType {
  pointAdded,
  pointDeducted,
  newLeader,
  reset,
}

class AudioService {
  static void play(SoundEffectType type, {bool enabled = true}) {
    if (!enabled) return;

    // Use Flutter's system haptic and audio feedback triggers
    switch (type) {
      case SoundEffectType.pointAdded:
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
        break;
      case SoundEffectType.pointDeducted:
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.selectionClick();
        break;
      case SoundEffectType.newLeader:
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.heavyImpact();
        break;
      case SoundEffectType.reset:
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.mediumImpact();
        break;
    }
  }
}
