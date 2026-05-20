import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cameraManagerProvider = Provider<CameraManager>((ref) => CameraManager());

class CameraManager {
  CameraController? controller;
  List<CameraDescription> _cameras = [];

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Use the back camera for scanning
    final backCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    controller = CameraController(
      backCamera,
      ResolutionPreset.medium, // Medium resolution to balance performance and accuracy
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // Best for ML Kit
    );

    await controller!.initialize();
    
    // Lock auto focus if possible
    await controller!.setFocusMode(FocusMode.auto);
  }

  void startImageStream(Function(CameraImage) onImage) {
    if (controller?.value.isInitialized == true && !controller!.value.isStreamingImages) {
      controller!.startImageStream(onImage);
    }
  }

  void stopImageStream() {
    if (controller?.value.isStreamingImages == true) {
      controller!.stopImageStream();
    }
  }

  Future<void> dispose() async {
    await controller?.dispose();
    controller = null;
  }
}
