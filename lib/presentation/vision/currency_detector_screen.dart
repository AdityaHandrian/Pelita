import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../core/camera/camera_manager.dart';
import '../../data/services/currency_ocr_service.dart';

class CurrencyDetectorScreen extends ConsumerStatefulWidget {
  const CurrencyDetectorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CurrencyDetectorScreen> createState() => _CurrencyDetectorScreenState();
}

class _CurrencyDetectorScreenState extends ConsumerState<CurrencyDetectorScreen> {
  bool _isScanning = false;
  String _lastDetectedCurrency = "";
  String _displayText = "DETEKSI\nUANG";
  DateTime _lastDetectionTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    ref.read(audioEngineProvider).speak("Deteksi Uang diaktifkan. Arahkan kamera ke uang kertas, lalu ketuk dua kali untuk mulai mendeteksi.");
    await ref.read(cameraManagerProvider).initialize();
    if (mounted) setState(() {});
  }

  void _toggleScanning() {
    final cameraManager = ref.read(cameraManagerProvider);
    final currencyService = ref.read(currencyOcrServiceProvider);
    final audioEngine = ref.read(audioEngineProvider);
    final hapticEngine = ref.read(hapticEngineProvider);

    if (_isScanning) {
      cameraManager.stopImageStream();
      setState(() {
        _isScanning = false;
        _displayText = "DETEKSI\nUANG";
      });
      hapticEngine.strongImpact();
      audioEngine.speak("Deteksi dihentikan.");
    } else {
      setState(() {
        _isScanning = true;
        _displayText = "MENDETEKSI...";
      });
      hapticEngine.doubleImpact();
      audioEngine.speak("Mendeteksi. Arahkan kamera ke uang kertas.");

      cameraManager.startImageStream((image) async {
        if (!mounted || !_isScanning) return;

        // Throttle to once every 1.5 seconds
        final now = DateTime.now();
        if (now.difference(_lastDetectionTime).inMilliseconds < 1500) return;

        final camera = cameraManager.controller!.description;
        final detectedCurrency = await currencyService.detectCurrency(image, camera);

        if (detectedCurrency != null && detectedCurrency.isNotEmpty) {
          if (detectedCurrency != _lastDetectedCurrency || now.difference(_lastDetectionTime).inSeconds > 4) {
            _lastDetectionTime = DateTime.now();
            _lastDetectedCurrency = detectedCurrency;

            if (mounted) {
              setState(() {
                _displayText = detectedCurrency;
              });
            }
            hapticEngine.pulsingImpact();
            audioEngine.speak(detectedCurrency, interrupt: true);
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
            final status = _isScanning ? "sedang mendeteksi" : "siap mendeteksi";
            ref.read(audioEngineProvider).speak("Deteksi Uang $status. Ketuk dua kali untuk mengubah status.");
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
            ref.read(audioEngineProvider).speak("Bantuan Deteksi Uang: Arahkan kamera ke uang kertas. Teks pada uang akan dibaca untuk mengenali nominal.");
          },
          child: Stack(
            children: [
              // Camera Preview
              if (ref.watch(cameraManagerProvider).controller != null &&
                  ref.watch(cameraManagerProvider).controller!.value.isInitialized)
                Positioned.fill(
                  child: CameraPreview(ref.watch(cameraManagerProvider).controller!),
                ),
              // Overlay with detected text
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  color: AppTheme.background.withOpacity(0.3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status indicator
                      if (_isScanning)
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      // Main text
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Semantics(
                              label: "Hasil Deteksi: ${_displayText.replaceAll('\n', ' ')}",
                              liveRegion: true,
                              child: Text(
                                _displayText,
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: _lastDetectedCurrency.isNotEmpty && _isScanning
                                      ? AppTheme.highlight
                                      : AppTheme.primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
