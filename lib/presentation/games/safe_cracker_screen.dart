import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';

class SafeCrackerScreen extends ConsumerStatefulWidget {
  const SafeCrackerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SafeCrackerScreen> createState() => _SafeCrackerScreenState();
}

class _SafeCrackerScreenState extends ConsumerState<SafeCrackerScreen> {
  int _currentStage = 1;
  final int _totalStages = 3;
  double? _targetAngle;
  double? _currentHeading;
  StreamSubscription? _compassSubscription;
  Timer? _vibrationTimer;
  bool _isUnlocked = false;
  DateTime? _lockStartTime;

  @override
  void initState() {
    super.initState();
    _startNewStage();
    _initCompass();
  }

  void _startNewStage() {
    setState(() {
      _targetAngle = Random().nextDouble() * 360;
      _isUnlocked = false;
      _lockStartTime = null;
    });
    ref.read(audioEngineProvider).speak("Kunci nomor $_currentStage. Putar ponsel untuk mencari getaran.");
  }

  void _initCompass() {
    _compassSubscription = FlutterCompass.events!.listen((event) {
      if (!mounted) return;
      setState(() {
        _currentHeading = event.heading;
        _updateGameLogic();
      });
    });

    // Vibration feedback loop
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || _isUnlocked || _currentHeading == null || _targetAngle == null) return;

      double heading = (_currentHeading! + 360) % 360;
      double diff = (heading - _targetAngle!).abs();
      if (diff > 180) diff = 360 - diff;

      if (diff < 30) {
        // Map distance 0-30 to intensity/frequency
        int intensity = (255 * (1 - (diff / 30))).toInt();
        if (diff < 5) {
          Vibration.vibrate(duration: 100, amplitude: 255);
        } else {
          Vibration.vibrate(duration: 50, amplitude: intensity);
        }
      }
    });
  }

  void _updateGameLogic() {
    if (_targetAngle == null || _currentHeading == null || _isUnlocked) return;

    double heading = (_currentHeading! + 360) % 360;
    double diff = (heading - _targetAngle!).abs();
    if (diff > 180) diff = 360 - diff;

    if (diff < 5) {
      _lockStartTime ??= DateTime.now();
      if (DateTime.now().difference(_lockStartTime!).inSeconds >= 2) {
        _handleUnlock();
      }
    } else {
      _lockStartTime = null;
    }
  }

  void _handleUnlock() {
    setState(() => _isUnlocked = true);
    Vibration.cancel();
    ref.read(hapticEngineProvider).doubleImpact();

    if (_currentStage < _totalStages) {
      ref.read(audioEngineProvider).speak("Kunci $_currentStage terbuka! Bagus sekali.");
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _currentStage++;
        });
        _startNewStage();
      });
    } else {
      ref.read(audioEngineProvider).speak("Selamat! Brankas berhasil dibuka. Anda memenangkan permainan.");
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _vibrationTimer?.cancel();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {},
          onSwipeLeft: () {},
          onSingleTap: () {
            ref.read(audioEngineProvider).speak("Buka Brankas. Kunci ke $_currentStage dari $_totalStages.");
          },
          onDoubleTap: () {},
          onSingleVerticalSwipeUp: () {},
          onSingleVerticalSwipeDown: () {},
          onTwoFingerDoubleTap: () {
             Navigator.of(context).pop();
          },
          onTwoFingerDownwardSwipe: () {
             Navigator.of(context).pop();
          },
          onLongPress: () => ref.read(audioEngineProvider).speak("Bantuan: Putar ponsel. Semakin dekat dengan angka rahasia, getaran semakin kuat. Tahan jika getar sangat kencang."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  _isUnlocked ? Colors.green.withOpacity(0.3) : AppTheme.highlight.withOpacity(0.1),
                  Colors.black,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isUnlocked ? Icons.lock_open : Icons.lock,
                    size: 150,
                    color: _isUnlocked ? Colors.green : AppTheme.highlight,
                  ),
                  const SizedBox(height: 48),
                  Text(
                    "KUNCI $_currentStage / $_totalStages",
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "PUTAR PONSEL ANDA",
                    style: TextStyle(color: Colors.white54, letterSpacing: 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
