import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/voice_memo_service.dart';

class VoiceMemoHubScreen extends ConsumerStatefulWidget {
  const VoiceMemoHubScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceMemoHubScreen> createState() => _VoiceMemoHubScreenState();
}

class _VoiceMemoHubScreenState extends ConsumerState<VoiceMemoHubScreen> {
  List<File> _memos = [];
  int _currentIndex = 0;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _loadMemos();
    Future.delayed(const Duration(milliseconds: 500), () {
      ref.read(audioEngineProvider).speak(
          "Catatan Suara. Usap atas untuk mulai merekam, usap bawah untuk selesai. Ketuk dua kali untuk memutar.");
    });
  }

  Future<void> _loadMemos() async {
    final memos = await ref.read(voiceMemoServiceProvider).getAllMemos();
    setState(() {
      _memos = memos;
      if (_currentIndex >= _memos.length && _memos.isNotEmpty) {
        _currentIndex = _memos.length - 1;
      }
    });
  }

  void _announceCurrentMemo() {
    if (_memos.isEmpty) {
      ref.read(audioEngineProvider).speak("Tidak ada catatan suara.");
      return;
    }
    final date = DateFormat('d MMMM, HH:mm', 'id_ID').format(_memos[_currentIndex].lastModifiedSync());
    ref.read(audioEngineProvider).speak("Catatan ${_currentIndex + 1}. $date.");
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    final service = ref.read(voiceMemoServiceProvider);
    final haptic = ref.read(hapticEngineProvider);
    final audio = ref.read(audioEngineProvider);

    setState(() => _isRecording = true);
    haptic.strongImpact();
    audio.speak("Merekam...");
    await service.startRecording();
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final service = ref.read(voiceMemoServiceProvider);
    final haptic = ref.read(hapticEngineProvider);
    final audio = ref.read(audioEngineProvider);

    setState(() => _isRecording = false);
    haptic.doubleImpact();
    final path = await service.stopRecording();
    if (path != null) {
      audio.speak("Catatan disimpan.");
      await _loadMemos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {
            if (_memos.isEmpty || _isRecording) return;
            setState(() {
              _currentIndex = (_currentIndex + 1) % _memos.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentMemo();
          },
          onSwipeLeft: () {
            if (_memos.isEmpty || _isRecording) return;
            setState(() {
              _currentIndex = (_currentIndex - 1 + _memos.length) % _memos.length;
            });
            ref.read(hapticEngineProvider).weakImpact();
            _announceCurrentMemo();
          },
          onSingleTap: () {
            if (_isRecording) {
              ref.read(audioEngineProvider).speak("Sedang merekam. Usap ke bawah untuk berhenti.");
            } else if (_memos.isEmpty) {
              ref.read(audioEngineProvider).speak("Tidak ada catatan. Usap ke atas untuk mulai merekam.");
            } else {
              _announceCurrentMemo();
            }
          },
          onDoubleTap: () {
            if (_isRecording) {
               ref.read(audioEngineProvider).speak("Gunakan usap ke bawah untuk menyelesaikan rekaman.");
            } else if (_memos.isNotEmpty) {
              ref.read(voiceMemoServiceProvider).playMemo(_memos[_currentIndex].path);
            }
          },
          onSingleVerticalSwipeUp: _startRecording,
          onSingleVerticalSwipeDown: _stopRecording,
          onTwoFingerDoubleTap: () {
            if (_memos.isNotEmpty && !_isRecording) {
               ref.read(voiceMemoServiceProvider).deleteMemo(_memos[_currentIndex].path);
               ref.read(audioEngineProvider).speak("Catatan dihapus.");
               _loadMemos();
            }
          },
          onTwoFingerDownwardSwipe: () => Navigator.of(context).pop(),
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
                    _isRecording ? Icons.mic : Icons.audiotrack,
                    size: 120,
                    color: _isRecording ? Colors.red : AppTheme.highlight,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isRecording ? "MEREKAM..." : (_memos.isEmpty ? "TIDAK ADA CATATAN" : "CATATAN ${_currentIndex + 1}"),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: _isRecording ? Colors.red : AppTheme.primaryText,
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
