import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/status_service.dart';

class AudioCenterScreen extends ConsumerStatefulWidget {
  const AudioCenterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AudioCenterScreen> createState() => _AudioCenterScreenState();
}

class _AudioCenterScreenState extends ConsumerState<AudioCenterScreen> {
  final List<String> _statusCategories = [
    "Waktu dan Tanggal",
    "Cuaca dan Suhu",
    "Lokasi GPS Presisi",
    "Titik Kenal POI",
    "Kompas",
    "Status Baterai",
  ];
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(audioEngineProvider).speak("Pusat Status Perangkat. Geser kanan kiri untuk kategori, ketuk dua kali untuk detail.");
    });
  }

  Future<void> _fetchAndSpeakDetail() async {
    setState(() => _isLoading = true);
    final statusService = ref.read(statusServiceProvider);
    final audioEngine = ref.read(audioEngineProvider);
    final hapticEngine = ref.read(hapticEngineProvider);

    hapticEngine.doubleImpact();
    String message = "";

    switch (_currentIndex) {
      case 0: message = await statusService.getTimeAndDate(); break;
      case 1: message = await statusService.getWeatherMock(); break;
      case 2: message = await statusService.getLocationAndPoi(); break;
      case 3: message = await statusService.getNearestPoi(); break;
      case 4: message = await statusService.getCompassHeading(); break;
      case 5: message = await statusService.getBatteryStatus(); break;
    }

    setState(() => _isLoading = false);
    audioEngine.speak(message, interrupt: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {
            setState(() {
              _currentIndex = (_currentIndex + 1) % _statusCategories.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            ref.read(audioEngineProvider).speak(_statusCategories[_currentIndex]);
          },
          onSwipeLeft: () {
            setState(() {
              _currentIndex = (_currentIndex - 1 + _statusCategories.length) % _statusCategories.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            ref.read(audioEngineProvider).speak(_statusCategories[_currentIndex]);
          },
          onSingleTap: () {
            ref.read(audioEngineProvider).speak("Kategori: ${_statusCategories[_currentIndex]}. Ketuk dua kali untuk dengar detail.");
          },
          onDoubleTap: _fetchAndSpeakDetail,
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
          onLongPress: () => ref.read(audioEngineProvider).speak("Bantuan Status: Memberikan informasi lingkungan dan perangkat secara luring."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Center(
              child: Semantics(
                label: "Kategori Pusat Status: ${_statusCategories[_currentIndex]}",
                liveRegion: true,
                child: Text(
                  _isLoading ? "MEMUAT..." : _statusCategories[_currentIndex].toUpperCase(),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: _isLoading ? AppTheme.highlight : AppTheme.primaryText,
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
