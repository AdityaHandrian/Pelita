import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

final voiceMemoServiceProvider = Provider((ref) => VoiceMemoService());

class VoiceMemoService {
  final _record = AudioRecorder();
  final _player = AudioPlayer();
  String? _lastRecordingPath;

  Future<void> startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        // Menggunakan .aac untuk kompatibilitas lebih luas di Android
        final path = '${dir.path}/memo_${DateTime.now().millisecondsSinceEpoch}.aac';
        
        // Memastikan konfigurasi encoder yang stabil
        await _record.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ), 
          path: path
        );
        _lastRecordingPath = path;
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _record.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      return path;
    } catch (e) {
      return null;
    }
  }

  Future<List<File>> getAllMemos() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync().whereType<File>().where((f) => 
        f.path.endsWith('.aac') || f.path.endsWith('.m4a')
      ).toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      return files;
    } catch (e) {
      return [];
    }
  }

  Future<void> playMemo(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await _player.stop();
        // Menggunakan UrlSource dengan prefix file:// seringkali lebih stabil di Android
        // daripada menggunakan DeviceFileSource untuk beberapa versi OS
        await _player.setSourceDeviceFile(path);
        await _player.resume();
      }
    } catch (e) {
      print("Error playing memo: $e");
    }
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  Future<void> deleteMemo(String path) async {
    try {
      await _player.stop();
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Error deleting memo: $e");
    }
  }
}
