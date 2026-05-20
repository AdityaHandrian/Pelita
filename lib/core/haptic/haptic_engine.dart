import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

final hapticEngineProvider = Provider<HapticEngine>((ref) => HapticEngine());

class HapticEngine {
  /// Short Weak Vibration: Emitted during menu transitions to provide a spatial illusion of "physical" buttons.
  Future<void> weakImpact() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 50, amplitude: 50);
    }
  }

  /// Double Vibration: Affirmation of successful actions (e.g., execution of command).
  Future<void> doubleImpact() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [0, 50, 100, 50], intensities: [0, 128, 0, 128]);
    }
  }

  /// Strong Impact Vibration: Indicator of structural boundaries or errors.
  Future<void> strongImpact() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(duration: 300, amplitude: 255);
    }
  }

  /// Dynamic Pulsing Vibration: Real-time indicator for proximity or object identification.
  Future<void> pulsingImpact() async {
    bool? hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100], intensities: [0, 100, 0, 150, 0, 200]);
    }
  }
}
