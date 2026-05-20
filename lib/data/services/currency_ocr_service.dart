import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ocr_service.dart';

final currencyOcrServiceProvider = Provider<CurrencyOcrService>((ref) {
  return CurrencyOcrService(ref.read(ocrServiceProvider));
});

class CurrencyOcrService {
  final OcrService _ocrService;
  bool _isProcessing = false;

  CurrencyOcrService(this._ocrService);

  /// Processes a camera frame and attempts to identify Indonesian Rupiah denominations
  /// by reading the text printed on the banknote using OCR.
  Future<String?> detectCurrency(CameraImage image, CameraDescription camera) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final rawText = await _ocrService.processImage(image, camera);
      _isProcessing = false;

      if (rawText == null || rawText.isEmpty) return null;

      final upperText = rawText.toUpperCase();

      // Only proceed if it looks like a banknote
      if (!_looksLikeCurrency(upperText)) return null;

      return _identifyDenomination(upperText);
    } catch (e) {
      _isProcessing = false;
      return null;
    }
  }

  /// Check if the scanned text contains currency-related keywords
  bool _looksLikeCurrency(String text) {
    const keywords = [
      'RUPIAH',
      'BANK INDONESIA',
      'RIBU',
      'RATUS',
      'JUTA',
      'SERIBU',
    ];
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Match the denomination based on text content
  String? _identifyDenomination(String text) {
    // Check from highest to lowest to avoid false partial matches

    // Rp 100.000
    if (text.contains('SERATUS RIBU') ||
        text.contains('100000') ||
        text.contains('100.000') ||
        _containsAll(text, ['SERATUS', 'RIBU'])) {
      return 'Seratus Ribu Rupiah (Rp 100.000)';
    }

    // Rp 75.000
    if (text.contains('TUJUH PULUH LIMA RIBU') ||
        text.contains('75000') ||
        text.contains('75.000') ||
        _containsAll(text, ['TUJUH', 'PULUH', 'LIMA', 'RIBU'])) {
      return 'Tujuh Puluh Lima Ribu Rupiah (Rp 75.000)';
    }

    // Rp 50.000
    if (text.contains('LIMA PULUH RIBU') ||
        text.contains('50000') ||
        text.contains('50.000') ||
        _containsAll(text, ['LIMA', 'PULUH', 'RIBU'])) {
      return 'Lima Puluh Ribu Rupiah (Rp 50.000)';
    }

    // Rp 20.000
    if (text.contains('DUA PULUH RIBU') ||
        text.contains('20000') ||
        text.contains('20.000') ||
        _containsAll(text, ['DUA', 'PULUH', 'RIBU'])) {
      return 'Dua Puluh Ribu Rupiah (Rp 20.000)';
    }

    // Rp 10.000
    if (text.contains('SEPULUH RIBU') ||
        text.contains('10000') ||
        text.contains('10.000') ||
        _containsAll(text, ['SEPULUH', 'RIBU'])) {
      return 'Sepuluh Ribu Rupiah (Rp 10.000)';
    }

    // Rp 5.000
    if (text.contains('LIMA RIBU') ||
        text.contains('5000') ||
        text.contains('5.000') ||
        _containsAll(text, ['LIMA', 'RIBU'])) {
      return 'Lima Ribu Rupiah (Rp 5.000)';
    }

    // Rp 2.000
    if (text.contains('DUA RIBU') ||
        text.contains('2000') ||
        text.contains('2.000') ||
        _containsAll(text, ['DUA', 'RIBU'])) {
      return 'Dua Ribu Rupiah (Rp 2.000)';
    }

    // Rp 1.000
    if (text.contains('SERIBU') ||
        text.contains('1000') ||
        text.contains('1.000')) {
      return 'Seribu Rupiah (Rp 1.000)';
    }

    // Detected currency keywords but couldn't determine denomination
    if (text.contains('RUPIAH') || text.contains('BANK INDONESIA')) {
      return 'Uang Rupiah terdeteksi, coba dekatkan lagi.';
    }

    return null;
  }

  bool _containsAll(String text, List<String> words) {
    return words.every((word) => text.contains(word));
  }
}
