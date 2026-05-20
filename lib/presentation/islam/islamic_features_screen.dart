import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/status_service.dart';
import '../navigation/qibla_finder_screen.dart';

class IslamicFeaturesScreen extends ConsumerStatefulWidget {
  const IslamicFeaturesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IslamicFeaturesScreen> createState() => _IslamicFeaturesScreenState();
}

class _IslamicFeaturesScreenState extends ConsumerState<IslamicFeaturesScreen> {
  final List<String> _subFeatures = [
    "Jadwal Shalat",
    "Pencari Kiblat",
  ];
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(audioEngineProvider).speak("Fitur Islam. Geser kanan kiri untuk memilih sub fitur, ketuk dua kali untuk masuk.");
    });
  }

  void _announceCurrentFeature() {
    ref.read(audioEngineProvider).speak(_subFeatures[_currentIndex]);
  }

  Future<void> _handleAction() async {
    final audioEngine = ref.read(audioEngineProvider);
    final hapticEngine = ref.read(hapticEngineProvider);
    final statusService = ref.read(statusServiceProvider);

    hapticEngine.doubleImpact();

    if (_currentIndex == 0) {
      setState(() => _isLoading = true);
      final prayerTimes = await statusService.getPrayerTimes();
      setState(() => _isLoading = false);
      audioEngine.speak(prayerTimes);
    } else if (_currentIndex == 1) {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const QiblaFinderScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {
            setState(() {
              _currentIndex = (_currentIndex + 1) % _subFeatures.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentFeature();
          },
          onSwipeLeft: () {
            setState(() {
              _currentIndex = (_currentIndex - 1 + _subFeatures.length) % _subFeatures.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentFeature();
          },
          onSingleTap: () {
            ref.read(audioEngineProvider).speak("${_subFeatures[_currentIndex]}. Ketuk dua kali untuk memilih.");
          },
          onDoubleTap: _handleAction,
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
          onLongPress: () => ref.read(audioEngineProvider).speak("Bantuan Fitur Islam: Berisi jadwal shalat dan alat bantu mencari arah kiblat."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Center(
              child: Semantics(
                label: "Fitur Islam: ${_subFeatures[_currentIndex]}",
                child: Text(
                  _isLoading ? "MENGHITUNG..." : _subFeatures[_currentIndex].toUpperCase(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: _isLoading ? AppTheme.highlight : AppTheme.primaryText,
                    fontWeight: FontWeight.bold,
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
