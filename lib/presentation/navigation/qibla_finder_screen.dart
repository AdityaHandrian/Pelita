import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/status_service.dart';

class QiblaFinderScreen extends ConsumerStatefulWidget {
  const QiblaFinderScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QiblaFinderScreen> createState() => _QiblaFinderScreenState();
}

class _QiblaFinderScreenState extends ConsumerState<QiblaFinderScreen> {
  double? _qiblaAngle;
  double? _currentHeading;
  StreamSubscription? _compassSubscription;
  bool _isNearQibla = false;

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  Future<void> _initQibla() async {
    final statusService = ref.read(statusServiceProvider);
    final audioEngine = ref.read(audioEngineProvider);
    
    audioEngine.speak("Pencari Kiblat aktif. Putar tubuh Anda perlahan sampai ponsel bergetar.");

    _qiblaAngle = await statusService.getQiblaAngle();
    
    _compassSubscription = FlutterCompass.events!.listen((event) {
      if (!mounted) return;
      setState(() {
        _currentHeading = event.heading;
        _checkQibla();
      });
    });
  }

  void _checkQibla() {
    if (_qiblaAngle == null || _currentHeading == null) return;

    // Normalize heading to 0-360
    double heading = (_currentHeading! + 360) % 360;
    double diff = (heading - _qiblaAngle!).abs();
    if (diff > 180) diff = 360 - diff;

    // If within 10 degrees, trigger haptic
    if (diff < 10) {
      if (!_isNearQibla) {
        _isNearQibla = true;
        Vibration.vibrate(pattern: [0, 500, 100, 500], intensities: [0, 255, 0, 255], repeat: 0);
        ref.read(audioEngineProvider).speak("Kiblat terdeteksi.");
      }
    } else {
      if (_isNearQibla) {
        _isNearQibla = false;
        Vibration.cancel();
      }
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {},
          onSwipeLeft: () {},
          onSingleTap: () {
             if (_qiblaAngle == null) {
               ref.read(audioEngineProvider).speak("Mencari lokasi GPS...");
             } else {
               ref.read(audioEngineProvider).speak("Arah kiblat di ${_qiblaAngle!.toStringAsFixed(0)} derajat. Putar ponsel Anda.");
             }
          },
          onDoubleTap: () {},
          onSingleVerticalSwipeUp: () {},
          onSingleVerticalSwipeDown: () {},
          onTwoFingerDoubleTap: () {
            ref.read(hapticEngineProvider).strongImpact();
            Navigator.of(context).pop();
          },
          onTwoFingerDownwardSwipe: () {
            ref.read(hapticEngineProvider).strongImpact();
            Navigator.of(context).pop();
          },
          onLongPress: () => ref.read(audioEngineProvider).speak("Bantuan Kiblat: Ponsel akan bergetar terus-menerus jika Anda menghadap ke arah Kiblat."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mosque,
                    size: 120,
                    color: _isNearQibla ? AppTheme.highlight : AppTheme.primaryText.withOpacity(0.3),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isNearQibla ? "KIBLAT TERDETEKSI" : "CARI KIBLAT",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: _isNearQibla ? AppTheme.highlight : AppTheme.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
