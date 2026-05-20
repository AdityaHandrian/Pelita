import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';

class DiscussionPlatformScreen extends ConsumerStatefulWidget {
  const DiscussionPlatformScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DiscussionPlatformScreen> createState() => _DiscussionPlatformScreenState();
}

class _DiscussionPlatformScreenState extends ConsumerState<DiscussionPlatformScreen> {
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(audioEngineProvider).speak("Platform Diskusi. Ketuk dua kali dan tahan untuk merekam pertanyaan.");
    });
  }

  void _startRecording() {
    setState(() => _isRecording = true);
    ref.read(hapticEngineProvider).weakImpact();
    ref.read(audioEngineProvider).speak("Merekam...");
  }

  void _stopRecordingAndSend() {
    setState(() => _isRecording = false);
    ref.read(hapticEngineProvider).doubleImpact();
    ref.read(audioEngineProvider).speak("Pertanyaan dan foto terkirim ke relawan. Wajah akan diblur otomatis secara luring.");
    // Simulate async network upload to Firebase
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () => ref.read(audioEngineProvider).speak("Geser tidak tersedia di layar ini."),
          onSwipeLeft: () => ref.read(audioEngineProvider).speak("Geser tidak tersedia di layar ini."),
          onSingleTap: () {
            ref.read(audioEngineProvider).speak("Siap bertanya. Ketuk dua kali untuk merekam.");
          },
          onDoubleTap: () {
            if (_isRecording) {
              _stopRecordingAndSend();
            } else {
              _startRecording();
            }
          },
          onSingleVerticalSwipeUp: () {
            ref.read(hapticEngineProvider).weakImpact();
            ref.read(audioEngineProvider).increaseSpeechRate();
          },
          onSingleVerticalSwipeDown: () {
            ref.read(hapticEngineProvider).weakImpact();
            ref.read(audioEngineProvider).decreaseSpeechRate();
          },
          onTwoFingerDoubleTap: () {
            ref.read(hapticEngineProvider).strongImpact();
            ref.read(audioEngineProvider).speak("Kembali.");
            Navigator.of(context).pop();
          },
          onTwoFingerDownwardSwipe: () {
            ref.read(hapticEngineProvider).strongImpact();
            Navigator.of(context).pop();
          },
          onLongPress: () => ref.read(audioEngineProvider).speak("Bantuan Diskusi: Pertanyaan Anda beserta gambar dari kamera akan dikirim ke relawan (Firebase)."),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(32),
            color: AppTheme.background,
            child: Center(
              child: Semantics(
                label: "Mode Platform Diskusi. Status: ${_isRecording ? 'Merekam' : 'Siap merekam'}.",
                liveRegion: true,
                child: Text(
                  _isRecording ? "MEREKAM..." : "PLATFORM\nDISKUSI",
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: _isRecording ? AppTheme.error : AppTheme.primaryText,
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
