import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:volume_controller/volume_controller.dart';
import '../../data/local/isar_db.dart';
import '../localization/localization_service.dart';

final audioEngineProvider = Provider<AudioEngine>((ref) => AudioEngine(ref));

class AudioEngine {
  final Ref _ref;
  late final IsarDb _isarDb;
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  double _speechRate = 0.5;
  double _speechPitch = 1.0;
  bool _isEmergencyMode = false;
  
  bool get isEmergencyMode => _isEmergencyMode;
  void setEmergencyMode(bool active) => _isEmergencyMode = active;

  AudioEngine(this._ref) {
    _isarDb = _ref.read(isarDbProvider);
    _init();
  }

  Future<void> _init() async {
    final settings = await _isarDb.getSettings();
    _speechRate = settings.speechRate;
    _speechPitch = settings.speechPitch;
    
    await _tts.setLanguage(settings.languageCode);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_speechPitch);
    
    // Track speaking state more reliably
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
    });

    await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth
        ],
        IosTextToSpeechAudioMode.defaultMode);
  }

  Future<void> speak(String text, {bool interrupt = true}) async {
    // If emergency is active, don't allow normal interruptions unless it's another emergency
    if (_isEmergencyMode && interrupt) return;

    if (interrupt) {
      await stop();
    }
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  Future<void> cycleLanguage() async {
    final settings = await _isarDb.getSettings();
    
    int currentIndex = L10n.supportedLanguages.indexOf(settings.languageCode);
    if (currentIndex == -1) currentIndex = 0;
    
    int nextIndex = (currentIndex + 1) % L10n.supportedLanguages.length;
    String newLang = L10n.supportedLanguages[nextIndex];
    
    // Create a temporary L10n instance for the NEW language to get its name and confirmation message
    final newL10n = L10n(newLang);
    String langName = newL10n.translate('lang_name');
    String confirmationPrefix = newL10n.translate('lang_changed_to');
    String confirmationMsg = "$confirmationPrefix $langName";

    await _tts.setLanguage(newLang);
    settings.languageCode = newLang;
    await _isarDb.updateLanguage(newLang);
    
    // Refresh the language provider so the whole UI updates
    _ref.invalidate(languageProvider);
    
    // Give a short delay for TTS engine to switch
    await Future.delayed(const Duration(milliseconds: 300));
    await speak(confirmationMsg);
  }

  Future<void> setLanguageEn() async {
    await _tts.setLanguage("en-US");
    await _isarDb.updateLanguage("en-US");
  }

  Future<void> setLanguageId() async {
    await _tts.setLanguage("id-ID");
    await _isarDb.updateLanguage("id-ID");
  }

  Future<void> increaseSpeechRate() async {
    if (_speechRate < 1.0) {
      _speechRate += 0.1;
      await _tts.setSpeechRate(_speechRate);
      await _isarDb.updateSpeechRate(_speechRate);
      await speak("Suara lebih cepat.");
    } else {
      await speak("Kecepatan maksimal.");
    }
  }

  Future<void> decreaseSpeechRate() async {
    if (_speechRate > 0.1) {
      _speechRate -= 0.1;
      await _tts.setSpeechRate(_speechRate);
      await _isarDb.updateSpeechRate(_speechRate);
      await speak("Suara lebih lambat.");
    } else {
      await speak("Kecepatan minimal.");
    }
  }

  Future<void> increaseSpeechPitch() async {
    if (_speechPitch < 2.0) {
      _speechPitch += 0.5;
      await _tts.setPitch(_speechPitch);
      await _isarDb.updateSpeechPitch(_speechPitch);
      await stop();
      await speak("Nada lebih tinggi.");
    } else {
      await speak("Nada maksimal.");
    }
  }

  Future<void> decreaseSpeechPitch() async {
    if (_speechPitch > 0.5) {
      _speechPitch -= 0.5;
      await _tts.setPitch(_speechPitch);
      await _isarDb.updateSpeechPitch(_speechPitch);
      await stop();
      await speak("Nada lebih rendah.");
    } else {
      await speak("Nada minimal.");
    }
  }
}
