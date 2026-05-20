import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';

class SpatialNavigationScreen extends ConsumerStatefulWidget {
  const SpatialNavigationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SpatialNavigationScreen> createState() => _SpatialNavigationScreenState();
}

class _SpatialNavigationScreenState extends ConsumerState<SpatialNavigationScreen> {
  bool _isActive = false;
  StreamSubscription? _gyroSubscription;
  DateTime _lastSpokeTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(audioEngineProvider).speak("Navigasi Spasial. Ketuk dua kali untuk mengaktifkan sensor arah.");
    });
  }

  void _toggleNavigation() {
    final audioEngine = ref.read(audioEngineProvider);
    final hapticEngine = ref.read(hapticEngineProvider);

    if (_isActive) {
      _gyroSubscription?.cancel();
      setState(() => _isActive = false);
      hapticEngine.strongImpact();
      audioEngine.speak("Sensor arah dimatikan.");
    } else {
      setState(() => _isActive = true);
      hapticEngine.doubleImpact();
      audioEngine.speak("Sensor aktif. Pegang perangkat mendatar.");

      _gyroSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
        if (!mounted || !_isActive) return;
        
        final now = DateTime.now();
        if (now.difference(_lastSpokeTime).inSeconds < 3) return;

        // Extremely simplified directional mapping for prototype purposes
        // In reality, a magnetometer (compass) would be fused with gyro for cardinal directions.
        if (event.y.abs() > 2.0) {
          _lastSpokeTime = DateTime.now();
          hapticEngine.pulsingImpact();
          if (event.y > 0) {
            audioEngine.speak("Berputar ke kiri");
          } else {
            audioEngine.speak("Berputar ke kanan");
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () => ref.read(audioEngineProvider).speak("Usap bawah dua jari untuk kembali."),
          onSwipeLeft: () => ref.read(audioEngineProvider).speak("Usap bawah dua jari untuk kembali."),
          onSingleTap: () {
            ref.read(audioEngineProvider).speak(_isActive ? "Sensor sedang aktif." : "Sensor mati.");
          },
          onDoubleTap: _toggleNavigation,
          onSingleVerticalSwipeUp: () {},
          onSingleVerticalSwipeDown: () {},
          onTwoFingerDoubleTap: () {
            ref.read(hapticEngineProvider).strongImpact();
            ref.read(audioEngineProvider).speak("Kembali.");
            Navigator.of(context).pop();
          },
          onTwoFingerDownwardSwipe: () {
            ref.read(hapticEngineProvider).strongImpact();
            Navigator.of(context).pop();
          },
          onLongPress: () => ref.read(audioEngineProvider).speak("Bantuan: Fitur ini mendeteksi rotasi spasial tubuh menggunakan Giroskop tanpa GPS."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Center(
              child: Semantics(
                label: "Mode Navigasi Spasial. Status: ${_isActive ? 'Aktif' : 'Mati'}.",
                liveRegion: true,
                child: Text(
                  _isActive ? "MENDETEKSI..." : "NAVIGASI\nSPASIAL",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: _isActive ? AppTheme.highlight : AppTheme.primaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
