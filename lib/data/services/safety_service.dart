import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../local/isar_db.dart';

final safetyServiceProvider = Provider<SafetyService>((ref) {
  final service = SafetyService(ref);
  service.init();
  return service;
});

class SafetyService {
  final Ref _ref;
  StreamSubscription? _accelerometerSubscription;
  
  // Thresholds
  static const double fallImpactThreshold = 30.0; // m/s^2
  static const double stillThreshold = 1.5; // m/s^2
  static const double shakeThreshold = 15.0; // m/s^2
  
  DateTime? _lastImpactTime;
  bool _isAlertPending = false;
  bool get isAlertPending => _isAlertPending;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;

  SafetyService(this._ref);

  void init() {
    _startListening();
  }

  void _startListening() {
    _accelerometerSubscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      _handleAccelerometerData(event);
    });
  }

  Future<void> _handleAccelerometerData(UserAccelerometerEvent event) async {
    if (_isAlertPending) return;

    final settings = await _ref.read(isarDbProvider).getSettings();
    if (!settings.fallDetectionEnabled) return;

    final double totalAcceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // 1. Fall Detection Logic
    if (totalAcceleration > fallImpactThreshold) {
      _lastImpactTime = DateTime.now();
    }

    if (_lastImpactTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastImpactTime!).inSeconds < 2) {
        // Checking for stillness after impact
        if (totalAcceleration < stillThreshold) {
          // Potential fall detected
          _triggerFallAlert();
          _lastImpactTime = null;
        }
      } else {
        // Reset if too much time passed without stillness
        _lastImpactTime = null;
      }
    }

    // 2. Shake/Panic Gesture Logic
    if (totalAcceleration > shakeThreshold) {
      final now = DateTime.now();
      if (_lastShakeTime == null || now.difference(_lastShakeTime!).inMilliseconds > 500) {
        if (_lastShakeTime != null && now.difference(_lastShakeTime!).inSeconds < 2) {
          _shakeCount++;
        } else {
          _shakeCount = 1;
        }
        _lastShakeTime = now;

        if (_shakeCount >= 3) {
          _triggerPanicAlert();
          _shakeCount = 0;
        }
      }
    }
  }

  void _triggerFallAlert() async {
    _isAlertPending = true;
    final audioEngine = _ref.read(audioEngineProvider);
    final hapticEngine = _ref.read(hapticEngineProvider);

    hapticEngine.strongImpact();
    await audioEngine.speak("Deteksi benturan keras. Apakah Anda baik-baik saja? Ketuk layar dua kali untuk membatalkan alarm.");
    
    // Wait for user response (handled in UI usually, but we can use a timer here)
    Timer(const Duration(seconds: 10), () {
      if (_isAlertPending) {
        _executeEmergencyProtocol("JATUH");
      }
    });
  }

  void _triggerPanicAlert() async {
    _isAlertPending = true;
    final audioEngine = _ref.read(audioEngineProvider);
    final hapticEngine = _ref.read(hapticEngineProvider);

    hapticEngine.doubleImpact();
    await audioEngine.speak("Guncangan panik terdeteksi. Mengirim lokasi darurat dalam lima detik. Ketuk dua kali untuk membatalkan.");

    Timer(const Duration(seconds: 5), () {
      if (_isAlertPending) {
        _executeEmergencyProtocol("PANIK");
      }
    });
  }

  void cancelAlert() {
    if (_isAlertPending) {
      _isAlertPending = false;
      _ref.read(audioEngineProvider).speak("Alarm dibatalkan. Status aman.");
    }
  }

  Future<void> _executeEmergencyProtocol(String reason) async {
    _isAlertPending = false;
    final audioEngine = _ref.read(audioEngineProvider);
    
    audioEngine.speak("Memicu protokol darurat. Membunyikan sirine.");
    
    // In a real app, we would send SMS here. 
    // Since we don't have an SMS plugin, we'll simulate it and use TTS to scream for help.
    
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {}

    String locationMsg = position != null 
        ? "Lokasi saya di ${position.latitude}, ${position.longitude}" 
        : "Lokasi tidak tersedia";

    // Simulate sending SMS
    print("SENDING EMERGENCY SMS: Alert $reason. $locationMsg");
    
    // Repeat help message
    final safetyAudio = _ref.read(audioEngineProvider);
    safetyAudio.setEmergencyMode(true);
    for (int i = 0; i < 5; i++) {
      await safetyAudio.speak("Tolong! Pengguna aplikasi Pelita mengalami keadaan darurat $reason. $locationMsg", interrupt: false);
      // Give enough time for the full sentence to finish
      await Future.delayed(const Duration(seconds: 8));
    }
    safetyAudio.setEmergencyMode(false);
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
  }
}
