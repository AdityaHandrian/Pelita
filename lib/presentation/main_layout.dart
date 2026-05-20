import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/audio/audio_engine.dart';
import '../core/haptic/haptic_engine.dart';
import '../core/gesture/gesture_shell.dart';
import '../core/theme/app_theme.dart';
import 'vision/text_scanner_screen.dart';
import 'vision/currency_detector_screen.dart';
import 'vision/medication_assistant_screen.dart';
import 'games/voice_memo_hub_screen.dart';
import 'navigation/spatial_navigation_screen.dart';
import 'islam/islamic_features_screen.dart';
import 'games/entertainment_hub_screen.dart';
import 'audio/audio_center_screen.dart';
import 'settings/settings_screen.dart';
import '../data/services/safety_service.dart';
import '../core/localization/localization_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  List<String> _getMenuItems(L10n l10n) {
    return [
      l10n.translate('text_scanner'),
      l10n.translate('currency_detector'),
      l10n.translate('medication_assistant'),
      l10n.translate('voice_memo'),
      l10n.translate('spatial_nav'),
      l10n.translate('islamic_features'),
      l10n.translate('entertainment'),
      l10n.translate('status_center'),
      l10n.translate('settings'),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Initialize safety service
    final l10n = ref.read(l10nProvider);
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(audioEngineProvider).speak("${l10n.translate('welcome')} ${l10n.translate('nav_hint')}");
    });
  }

  void _announceCurrentMenu(List<String> menuItems) {
    ref.read(audioEngineProvider).speak(menuItems[_currentIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final menuItems = _getMenuItems(l10n);

    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {
            setState(() {
              _currentIndex = (_currentIndex + 1) % menuItems.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentMenu(menuItems);
          },
          onSwipeLeft: () {
            setState(() {
              _currentIndex = (_currentIndex - 1 + menuItems.length) % menuItems.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentMenu(menuItems);
          },
          onSingleTap: () {
            ref.read(audioEngineProvider).speak("${menuItems[_currentIndex]}. ${l10n.translate('tap_to_enter')}");
          },
          onDoubleTap: () {
            final safetyService = ref.read(safetyServiceProvider);
            if (safetyService.isAlertPending) {
              safetyService.cancelAlert();
              return;
            }

            ref.read(hapticEngineProvider).doubleImpact();
            ref.read(audioEngineProvider).speak("${l10n.translate('entering')} ${menuItems[_currentIndex]}");
            
            if (_currentIndex == 0) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const TextScannerScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } else if (_currentIndex == 1) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const CurrencyDetectorScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } else if (_currentIndex == 2) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const MedicationAssistantScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } else if (_currentIndex == 3) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const VoiceMemoHubScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } else if (_currentIndex == 4) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const SpatialNavigationScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } else if (_currentIndex == 5) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const IslamicFeaturesScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } else if (_currentIndex == 6) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const EntertainmentHubScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } else if (_currentIndex == 7) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const AudioCenterScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } else if (_currentIndex == 8) {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            }
          },
          onSingleVerticalSwipeUp: () {},
          onSingleVerticalSwipeDown: () {},
          onTwoFingerDoubleTap: () {
            ref.read(hapticEngineProvider).strongImpact();
            ref.read(audioEngineProvider).speak(l10n.translate('help_hint'));
          },
          onTwoFingerDownwardSwipe: () {
            ref.read(hapticEngineProvider).strongImpact();
            ref.read(audioEngineProvider).speak("Kembali ke menu utama");
          },
          onLongPress: () => ref.read(audioEngineProvider).speak("${l10n.translate('welcome')} ${l10n.translate('nav_hint')}"),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: menuItems[_currentIndex],
                  child: Text(
                    menuItems[_currentIndex].toUpperCase(),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('app_name'),
                  style: TextStyle(
                    color: AppTheme.highlight,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
