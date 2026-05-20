import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/quiz_service.dart';

final quizServiceProvider = Provider((ref) => QuizService());

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizQuestion? _currentQuestion;
  int _score = 0;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _loadNewQuestion();
  }

  void _loadNewQuestion() {
    setState(() {
      _currentQuestion = ref.read(quizServiceProvider).getRandomQuestion();
      _isAnswered = false;
    });
    
    _announceQuestion();
  }

  void _announceQuestion() {
    if (_currentQuestion == null) return;
    
    String msg = "Pertanyaan: ${_currentQuestion!.question}. "
        "Pilihan. Atas: ${_currentQuestion!.options[0]}. "
        "Bawah: ${_currentQuestion!.options[1]}. "
        "Kiri: ${_currentQuestion!.options[2]}. "
        "Kanan: ${_currentQuestion!.options[3]}.";
    
    ref.read(audioEngineProvider).speak(msg);
  }

  void _handleAnswer(int index) {
    if (_isAnswered || _currentQuestion == null) return;

    setState(() => _isAnswered = true);
    final isCorrect = index == _currentQuestion!.correctIndex;
    final audioEngine = ref.read(audioEngineProvider);
    final hapticEngine = ref.read(hapticEngineProvider);

    if (isCorrect) {
      _score++;
      hapticEngine.doubleImpact();
      audioEngine.speak("Benar! ${_currentQuestion!.explanation}. Ketuk dua kali untuk soal selanjutnya.");
    } else {
      hapticEngine.strongImpact();
      audioEngine.speak("Kurang tepat. Jawaban yang benar adalah ${_currentQuestion!.options[_currentQuestion!.correctIndex]}. "
          "${_currentQuestion!.explanation}. Ketuk dua kali untuk soal selanjutnya.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () => _handleAnswer(3), // D
          onSwipeLeft: () => _handleAnswer(2),  // C
          onSingleTap: () {
            if (!_isAnswered) {
              _announceQuestion();
            } else {
              ref.read(audioEngineProvider).speak("Ketuk dua kali untuk soal selanjutnya. Skor Anda $_score.");
            }
          },
          onDoubleTap: () {
            if (_isAnswered) {
              _loadNewQuestion();
            } else {
              ref.read(audioEngineProvider).speak("Selesaikan soal ini dulu. Skor Anda $_score.");
            }
          },
          onSingleVerticalSwipeUp: () => _handleAnswer(0),   // A
          onSingleVerticalSwipeDown: () => _handleAnswer(1), // B
          onTwoFingerDoubleTap: () {
            ref.read(audioEngineProvider).speak("Permainan berakhir. Skor akhir Anda $_score. Kembali.");
            Navigator.of(context).pop();
          },
          onTwoFingerDownwardSwipe: () {
            Navigator.of(context).pop();
          },
          onLongPress: () => ref.read(audioEngineProvider).speak("Bantuan Kuis: Usap atas untuk A, bawah untuk B, kiri untuk C, dan kanan untuk D."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "SKOR: $_score",
                    style: TextStyle(color: AppTheme.highlight, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  if (_currentQuestion != null)
                    Text(
                      _currentQuestion!.question.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 32),
                  if (_isAnswered)
                    Icon(Icons.check_circle, color: AppTheme.highlight, size: 64)
                  else
                    const CircularProgressIndicator(color: Colors.white24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
