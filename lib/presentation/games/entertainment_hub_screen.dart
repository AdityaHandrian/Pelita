import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import 'quiz_screen.dart';
import 'safe_cracker_screen.dart';

class EntertainmentHubScreen extends ConsumerStatefulWidget {
  const EntertainmentHubScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EntertainmentHubScreen> createState() => _EntertainmentHubScreenState();
}

class _EntertainmentHubScreenState extends ConsumerState<EntertainmentHubScreen> {
  final List<String> _games = [
    "Kuis Pelita",
    "Buka Brankas",
  ];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(audioEngineProvider).speak("Pusat Hiburan. Geser kanan kiri untuk memilih game, ketuk dua kali untuk bermain.");
    });
  }

  void _announceCurrentGame() {
    ref.read(audioEngineProvider).speak(_games[_currentIndex]);
  }

  void _handleGameSelection() {
    ref.read(hapticEngineProvider).doubleImpact();
    if (_currentIndex == 0) {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const QuizScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ));
    } else {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SafeCrackerScreen(),
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
              _currentIndex = (_currentIndex + 1) % _games.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentGame();
          },
          onSwipeLeft: () {
            setState(() {
              _currentIndex = (_currentIndex - 1 + _games.length) % _games.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentGame();
          },
          onSingleTap: () {
            ref.read(audioEngineProvider).speak("${_games[_currentIndex]}. Ketuk dua kali untuk masuk.");
          },
          onDoubleTap: _handleGameSelection,
          onSingleVerticalSwipeUp: () {},
          onSingleVerticalSwipeDown: () {},
          onTwoFingerDoubleTap: () {
            ref.read(hapticEngineProvider).strongImpact();
            Navigator.of(context).pop();
          },
          onTwoFingerDownwardSwipe: () {
            Navigator.of(context).pop();
          },
          onLongPress: () => ref.read(audioEngineProvider).speak("Bantuan Hiburan: Berisi koleksi game yang dioptimalkan untuk tunanetra."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Center(
              child: Semantics(
                label: "Pilih Game: ${_games[_currentIndex]}",
                child: Text(
                  _games[_currentIndex].toUpperCase(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.primaryText,
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
