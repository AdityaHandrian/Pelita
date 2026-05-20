import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = Isar.autoIncrement;

  double speechRate = 0.5;
  String languageCode = 'id-ID';
  bool isFirstLaunch = true;
  
  // Safety Features
  String emergencyContact = "";
  bool fallDetectionEnabled = true;
  bool shakeToSosEnabled = true;

  // New Preferences
  double speechPitch = 1.0;
  String themeMode = 'black_white'; // 'black_white' or 'black_yellow'
}
