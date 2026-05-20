import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final purificationServiceProvider = Provider<PurificationService>((ref) => PurificationService());

class PurificationService {
  /// Invoked quietly in the background to delete local cache files older than 24 hours.
  /// Complies with Phase 4: "Automatic database purification scripts to stay within 5GB free tier."
  Future<void> executeDailyPurge() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final threshold = DateTime.now().subtract(const Duration(hours: 24));

      if (cacheDir.existsSync()) {
        for (var entity in cacheDir.listSync(recursive: true)) {
          if (entity is File) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(threshold)) {
              await entity.delete();
            }
          }
        }
      }
      print("PELITA: Local Cache Purification cycle completed successfully.");
    } catch (e) {
      print("PELITA: Purification cycle encountered an error: $e");
    }
  }
}
