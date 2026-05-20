import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../core/camera/camera_manager.dart';
import '../../data/services/ocr_service.dart';

class TextScannerScreen extends ConsumerStatefulWidget {
  const TextScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TextScannerScreen> createState() => _TextScannerScreenState();
}

class _TextScannerScreenState extends ConsumerState<TextScannerScreen> {
  bool _isScanning = false;
  String _lastSpokenText = "";
  DateTime _lastScanTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    ref.read(audioEngineProvider).speak("Pemindai Teks diaktifkan. Arahkan kamera ke teks dan ketuk dua kali untuk mulai memindai.");
    await ref.read(cameraManagerProvider).initialize();
    if (mounted) setState(() {});
  }

  void _toggleScanning() {
    final cameraManager = ref.read(cameraManagerProvider);
    final ocrService = ref.read(ocrServiceProvider);
    final audioEngine = ref.read(audioEngineProvider);
    final hapticEngine = ref.read(hapticEngineProvider);

    if (_isScanning) {
      cameraManager.stopImageStream();
      setState(() => _isScanning = false);
      hapticEngine.strongImpact();
      audioEngine.speak("Pemindaian dihentikan.");
    } else {
      setState(() => _isScanning = true);
      hapticEngine.doubleImpact();
      audioEngine.speak("Memindai. Pertahankan posisi kamera.");

      cameraManager.startImageStream((image) async {
        if (!mounted || !_isScanning) return;
        
        final now = DateTime.now();
        // Throttle OCR to once every 2 seconds to avoid overwhelming TTS
        if (now.difference(_lastScanTime).inSeconds < 2) return;

        final camera = cameraManager.controller!.description;
        final recognizedText = await ocrService.processImage(image, camera);

        if (recognizedText != null && recognizedText.isNotEmpty) {
          // Avoid repeating the exact same text continuously
          if (recognizedText != _lastSpokenText) {
            _lastScanTime = DateTime.now();
            _lastSpokenText = recognizedText;
            hapticEngine.weakImpact();
            audioEngine.speak(recognizedText, interrupt: false);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    ref.read(cameraManagerProvider).stopImageStream();
    ref.read(cameraManagerProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {
            ref.read(audioEngineProvider).speak("Usap ke bawah dengan dua jari untuk kembali.");
          },
          onSwipeLeft: () {
            ref.read(audioEngineProvider).speak("Usap ke bawah dengan dua jari untuk kembali.");
          },
          onSingleTap: () {
            final status = _isScanning ? "sedang memindai" : "siap memindai";
            ref.read(audioEngineProvider).speak("Pemindai Teks $status. Ketuk dua kali untuk mengubah status.");
          },
          onDoubleTap: () {
            _toggleScanning();
          },
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
          onLongPress: () {
            ref.read(audioEngineProvider).speak("Bantuan Pemindai Teks: Ketuk dua kali untuk mulai atau berhenti memindai. Usap bawah dengan dua jari untuk keluar.");
          },
          child: Stack(
            children: [
              // Visual Camera Preview for Monitoring/Low Vision
              if (ref.watch(cameraManagerProvider).controller != null &&
                  ref.watch(cameraManagerProvider).controller!.value.isInitialized)
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: ref.watch(cameraManagerProvider).controller!.value.aspectRatio,
                    child: CameraPreview(ref.watch(cameraManagerProvider).controller!),
                  ),
                ),
              // High Contrast Overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(32),
                color: AppTheme.background.withOpacity(0.2), // Much more transparent so the camera is clearly visible
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: Semantics(
                          label: "Mode Pemindai Teks. Status: ${_isScanning ? 'Sedang memindai' : 'Siap memindai'}.",
                          liveRegion: true,
                          child: Text(
                            _isScanning ? "MEMINDAI..." : "PEMINDAI\nTEKS",
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: _isScanning ? AppTheme.highlight : AppTheme.primaryText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
