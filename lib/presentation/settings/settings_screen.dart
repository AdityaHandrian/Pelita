import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/isar_db.dart';
import '../../core/localization/localization_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<String> _getSettingCategories(L10n l10n) {
    return [
      l10n.translate('speed'),
      l10n.translate('pitch'),
      l10n.translate('change_language'),
      l10n.translate('contrast_theme'),
      l10n.translate('fall_detection'),
    ];
  }
  int _currentIndex = 0;

  @override
  void initState() {
    final l10n = ref.read(l10nProvider);
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(audioEngineProvider).speak(l10n.translate('settings_welcome'));
    });
  }

  void _announceCurrentCategory(List<String> categories) {
    ref.read(audioEngineProvider).speak(categories[_currentIndex]);
  }

  Future<void> _handleSwipeUp() async {
    final audioEngine = ref.read(audioEngineProvider);
    final hapticEngine = ref.read(hapticEngineProvider);
    hapticEngine.weakImpact();

    if (_currentIndex == 0) {
      await audioEngine.increaseSpeechRate();
    } else if (_currentIndex == 1) {
      await audioEngine.increaseSpeechPitch();
    } else if (_currentIndex == 2) {
      await audioEngine.cycleLanguage();
    } else if (_currentIndex == 3) {
      await _toggleTheme();
    } else if (_currentIndex == 4) {
      final isar = ref.read(isarDbProvider);
      final settings = await isar.getSettings();
      bool newState = !settings.fallDetectionEnabled;
      await isar.updateFallDetectionEnabled(newState);
      audioEngine.speak(newState ? "Deteksi jatuh diaktifkan." : "Deteksi jatuh dimatikan.");
    }
  }

  Future<void> _handleSwipeDown() async {
    final audioEngine = ref.read(audioEngineProvider);
    final hapticEngine = ref.read(hapticEngineProvider);
    hapticEngine.weakImpact();

    if (_currentIndex == 0) {
      await audioEngine.decreaseSpeechRate();
    } else if (_currentIndex == 1) {
      await audioEngine.decreaseSpeechPitch();
    } else if (_currentIndex == 2) {
      await audioEngine.cycleLanguage(); // Same as swipe up for language cycle
    } else if (_currentIndex == 3) {
      await _toggleTheme(); // Same as swipe up for theme toggle
    } else if (_currentIndex == 4) {
      final isar = ref.read(isarDbProvider);
      final settings = await isar.getSettings();
      bool newState = !settings.fallDetectionEnabled;
      await isar.updateFallDetectionEnabled(newState);
      audioEngine.speak(newState ? "Deteksi jatuh diaktifkan." : "Deteksi jatuh dimatikan.");
    }
  }

  Future<void> _toggleTheme() async {
    final isar = ref.read(isarDbProvider);
    final audioEngine = ref.read(audioEngineProvider);
    final settings = await isar.getSettings();
    String newTheme = settings.themeMode == 'black_yellow' ? 'black_white' : 'black_yellow';
    await isar.updateThemeMode(newTheme);
    ref.invalidate(themeProvider);
    audioEngine.speak(newTheme == 'black_yellow' 
        ? "Tema diubah ke kontras kuning." 
        : "Tema diubah ke kontras putih.");
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final categories = _getSettingCategories(l10n);

    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {
            setState(() {
              _currentIndex = (_currentIndex + 1) % categories.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentCategory(categories);
          },
          onSwipeLeft: () {
            setState(() {
              _currentIndex = (_currentIndex - 1 + categories.length) % categories.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentCategory(categories);
          },
          onSingleTap: () {
            ref.read(audioEngineProvider).speak(
                "${categories[_currentIndex]}. ${l10n.translate('swipe_v_to_adjust')}");
          },
          onDoubleTap: () {
            ref.read(audioEngineProvider).speak("Gunakan usap atas bawah untuk mengubah pengaturan ini.");
          },
          onSingleVerticalSwipeUp: _handleSwipeUp,
          onSingleVerticalSwipeDown: _handleSwipeDown,
          onTwoFingerDoubleTap: () {
            ref.read(hapticEngineProvider).strongImpact();
            ref.read(audioEngineProvider).speak("Kembali ke menu utama.");
            Navigator.of(context).pop();
          },
          onTwoFingerDownwardSwipe: () {
            ref.read(hapticEngineProvider).strongImpact();
            Navigator.of(context).pop();
          },
          onLongPress: () => ref.read(audioEngineProvider).speak(
              "Bantuan Pengaturan: Geser kanan kiri untuk ganti kategori. Geser atas bawah untuk mengatur."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Center(
              child: Semantics(
                label: "Pengaturan Kategori: ${categories[_currentIndex]}",
                child: Text(
                  categories[_currentIndex].toUpperCase(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
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
