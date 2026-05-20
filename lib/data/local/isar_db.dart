import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/app_settings.dart';

final isarDbProvider = Provider<IsarDb>((ref) => IsarDb());

class IsarDb {
  late Future<Isar> db;

  IsarDb() {
    db = _initDb();
  }

  Future<Isar> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      return await Isar.open(
        [AppSettingsSchema],
        directory: dir.path,
      );
    }
    return Future.value(Isar.getInstance());
  }

  Future<AppSettings> getSettings() async {
    final isar = await db;
    var settings = await isar.appSettings.where().findFirst();
    if (settings == null) {
      settings = AppSettings();
      await isar.writeTxn(() async {
        await isar.appSettings.put(settings!);
      });
    }
    return settings;
  }

  Future<void> updateSpeechRate(double rate) async {
    final isar = await db;
    final settings = await getSettings();
    settings.speechRate = rate;
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  Future<void> updateLanguage(String code) async {
    final isar = await db;
    final settings = await getSettings();
    settings.languageCode = code;
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  Future<void> updateSpeechPitch(double pitch) async {
    final isar = await db;
    final settings = await getSettings();
    settings.speechPitch = pitch;
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  Future<void> updateThemeMode(String mode) async {
    final isar = await db;
    final settings = await getSettings();
    settings.themeMode = mode;
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  Future<void> updateFallDetectionEnabled(bool enabled) async {
    final isar = await db;
    final settings = await getSettings();
    settings.fallDetectionEnabled = enabled;
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }
}
