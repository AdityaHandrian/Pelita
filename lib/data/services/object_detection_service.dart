import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as image_lib;

final objectDetectionServiceProvider = Provider<ObjectDetectionService>((ref) => ObjectDetectionService());

class ObjectDetectionService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isProcessing = false;
  
  // SSD MobileNet V1 Quantized input size
  static const int inputSize = 300;

  Future<void> initialize() async {
    try {
      // Load official Google SSD MobileNet model
      _interpreter = await Interpreter.fromAsset('assets/models/detect.tflite');
      
      // Load labels
      final labelData = await rootBundle.loadString('assets/models/labelmap.txt');
      _labels = labelData.split('\n');
      print("PELITA: Real AI Model Loaded Successfully.");
    } catch (e) {
      print("Failed to initialize TFLite model: $e");
    }
  }

  Future<String?> processImage(CameraImage image) async {
    if (_isProcessing || _interpreter == null || _labels == null) return null;
    _isProcessing = true;

    try {
      // 1. Convert CameraImage to RGB Image
      image_lib.Image convertedImage = _convertCameraImage(image);
      
      // 2. Resize to match model input (300x300)
      image_lib.Image resizedImage = image_lib.copyResize(convertedImage, width: inputSize, height: inputSize);

      // 3. Convert to Uint8List for Quantized Model [1, 300, 300, 3]
      var input = _imageToByteListUint8(resizedImage, inputSize);

      // 4. Prepare output buffers for SSD MobileNet
      // Output 0: Locations [1, 10, 4]
      // Output 1: Classes [1, 10]
      // Output 2: Scores [1, 10]
      // Output 3: Number of detections [1]
      var outputLocations = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);
      var outputClasses = List.filled(1 * 10, 0.0).reshape([1, 10]);
      var outputScores = List.filled(1 * 10, 0.0).reshape([1, 10]);
      var numDetections = List.filled(1, 0.0).reshape([1]);

      Map<int, Object> outputs = {
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      };

      // 5. Run Inference
      _interpreter!.runForMultipleInputs([input], outputs);

      // 6. Parse Output
      double highestScore = 0.0;
      int bestClassIndex = -1;

      for (int i = 0; i < 10; i++) {
        double score = outputScores[0][i];
        if (score > highestScore && score > 0.6) { // 60% confidence threshold
          highestScore = score;
          bestClassIndex = outputClasses[0][i].toInt();
        }
      }

      String? detectedLabel;
      if (bestClassIndex != -1 && bestClassIndex < _labels!.length) {
        // labelmap.txt has '???', at index 0. Real labels start at 1.
        detectedLabel = _labels![bestClassIndex];
        // Translate some common generic objects to Indonesian for demonstration
        detectedLabel = _translateToIndonesian(detectedLabel);
      }

      _isProcessing = false;
      return detectedLabel;
    } catch (e) {
      print("Inference Error: $e");
      _isProcessing = false;
      return null;
    }
  }

  // Very basic YUV to RGB conversion
  image_lib.Image _convertCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    var img = image_lib.Image(width: width, height: height); 

    // Extract planes
    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yp = yPlane[yIndex];
        final up = uPlane[uvIndex];
        final vp = vPlane[uvIndex];

        // Simplified YUV to RGB
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - uPlane[uvIndex] * 46549 / 131072 + 44 - vPlane[uvIndex] * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + uPlane[uvIndex] * 1814 / 1024 - 227).round().clamp(0, 255);

        img.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    return img;
  }

  Uint8List _imageToByteListUint8(image_lib.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = pixel.r.toInt();
        buffer[pixelIndex++] = pixel.g.toInt();
        buffer[pixelIndex++] = pixel.b.toInt();
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  String _translateToIndonesian(String label) {
    final l = label.toLowerCase();
    if (l.contains("person")) return "Manusia";
    if (l.contains("cell phone")) return "Ponsel";
    if (l.contains("laptop")) return "Laptop";
    if (l.contains("keyboard")) return "Keyboard";
    if (l.contains("mouse")) return "Mouse";
    if (l.contains("bottle")) return "Botol";
    if (l.contains("cup")) return "Gelas";
    if (l.contains("chair")) return "Kursi";
    if (l.contains("book")) return "Buku";
    return label; // Fallback to english
  }

  void dispose() {
    _interpreter?.close();
  }
}
