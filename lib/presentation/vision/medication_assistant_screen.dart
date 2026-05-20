import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_engine.dart';
import '../../core/haptic/haptic_engine.dart';
import '../../core/gesture/gesture_shell.dart';
import '../../core/theme/app_theme.dart';
import '../../core/camera/camera_manager.dart';
import '../../data/services/ocr_service.dart';
import '../../data/services/notification_service.dart';

class MedicationAssistantScreen extends ConsumerStatefulWidget {
  const MedicationAssistantScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicationAssistantScreen> createState() => _MedicationAssistantScreenState();
}

class _MedicationAssistantScreenState extends ConsumerState<MedicationAssistantScreen> {
  bool _isScanning = false;
  String _detectedMedicine = "";
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  Future<void> _initScanner() async {
    ref.read(audioEngineProvider).speak("Asisten Obat Aktif. Arahkan kamera ke label obat dan ketuk dua kali untuk memindai.");
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
      audioEngine.speak("Pemindaian selesai.");
    } else {
      setState(() {
        _isScanning = true;
        _detectedMedicine = "";
      });
      hapticEngine.doubleImpact();
      audioEngine.speak("Memindai nama obat...");

      cameraManager.startImageStream((image) async {
        if (!mounted || !_isScanning) return;
        
        final now = DateTime.now();
        if (_lastScanTime != null && now.difference(_lastScanTime!).inSeconds < 3) return;

        final camera = cameraManager.controller!.description;
        final text = await ocrService.processImage(image, camera);

        if (text != null && text.isNotEmpty) {
           _lastScanTime = DateTime.now();
           setState(() => _detectedMedicine = text);
           hapticEngine.weakImpact();
           audioEngine.speak("Terdeteksi: $text. Ketuk tahan untuk mengatur pengingat minum obat ini empat jam lagi.");
           cameraManager.stopImageStream();
           setState(() => _isScanning = false);
        }
      });
    }
  }

  Future<void> _setReminder() async {
    if (_detectedMedicine.isEmpty) {
      ref.read(audioEngineProvider).speak("Pindai obat dulu sebelum mengatur pengingat.");
      return;
    }

    final scheduledTime = DateTime.now().add(const Duration(hours: 4));
    await NotificationService.scheduleNotification(
      _detectedMedicine.hashCode,
      "Waktunya Minum Obat",
      "Jangan lupa minum $_detectedMedicine sekarang.",
      scheduledTime,
    );

    ref.read(hapticEngineProvider).doubleImpact();
    ref.read(audioEngineProvider).speak("Pengingat untuk $_detectedMedicine telah diatur empat jam dari sekarang.");
  }

  @override
  void dispose() {
    ref.read(cameraManagerProvider).stopImageStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureShell(
          onSwipeRight: () {},
          onSwipeLeft: () {},
          onSingleTap: () {
            if (_detectedMedicine.isNotEmpty) {
              ref.read(audioEngineProvider).speak("Obat terakhir terdeteksi: $_detectedMedicine.");
            } else {
              ref.read(audioEngineProvider).speak("Belum ada obat terdeteksi.");
            }
          },
          onDoubleTap: _toggleScanning,
          onLongPress: _setReminder,
          onSingleVerticalSwipeUp: () {},
          onSingleVerticalSwipeDown: () {},
          onTwoFingerDoubleTap: () {
            ref.read(hapticEngineProvider).strongImpact();
            Navigator.of(context).pop();
          },
          onTwoFingerDownwardSwipe: () => Navigator.of(context).pop(),
          child: Stack(
            children: [
              if (ref.watch(cameraManagerProvider).controller != null &&
                  ref.watch(cameraManagerProvider).controller!.value.isInitialized)
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: ref.watch(cameraManagerProvider).controller!.value.aspectRatio,
                    child: CameraPreview(ref.watch(cameraManagerProvider).controller!),
                  ),
                ),
              Container(
                width: double.infinity,
                height: double.infinity,
                color: AppTheme.background.withOpacity(0.3),
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication,
                        size: 100,
                        color: _detectedMedicine.isNotEmpty ? AppTheme.highlight : Colors.white24,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        _isScanning ? "MEMINDAI..." : (_detectedMedicine.isEmpty ? "ASISTEN OBAT" : _detectedMedicine.toUpperCase()),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: _isScanning ? AppTheme.highlight : AppTheme.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
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
