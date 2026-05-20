import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statusServiceProvider = Provider<StatusService>((ref) => StatusService());

class StatusService {
  final Battery _battery = Battery();

  Future<String> getTimeAndDate() async {
    final now = DateTime.now();
    final time = DateFormat('HH:mm').format(now);
    final date = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    return "Pukul $time. $date.";
  }

  Future<String> getBatteryStatus() async {
    final level = await _battery.batteryLevel;
    final state = await _battery.batteryState;
    String stateStr = "";
    if (state == BatteryState.charging) stateStr = "sedang diisi daya";
    if (state == BatteryState.full) stateStr = "penuh";
    return "Baterai $level persen, $stateStr.";
  }

  Future<String> getLocationAndPoi() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "Layanan lokasi dimatikan.";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "Izin lokasi ditolak.";
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      String accuracyMsg = "Akurasi GPS sekitar ${position.accuracy.toStringAsFixed(1)} meter.";
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        String address = "Lokasi Anda saat ini di ${p.street}. ";
        if (p.subLocality != null && p.subLocality!.isNotEmpty) address += "Kelurahan ${p.subLocality}, ";
        if (p.locality != null && p.locality!.isNotEmpty) address += "Kecamatan ${p.locality}, ";
        if (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty) address += "${p.subAdministrativeArea}. ";
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) address += "Provinsi ${p.administrativeArea}. ";
        
        return "$address$accuracyMsg";
      }
      return "Lokasi terdeteksi di koordinat ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}. $accuracyMsg";
    } catch (e) {
      return "Gagal mendapatkan lokasi GPS detail.";
    }
  }

  Future<String> getWeatherMock() async {
    // Mock weather as requested for Zero-Cost/No-Key implementation
    return "Suhu saat ini 28 derajat celcius. Prakiraan cuaca cerah berawan.";
  }

  Future<String> getPrayerTimes() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final myCoordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;
      
      final prayerTimes = PrayerTimes.today(myCoordinates, params);
      
      final current = prayerTimes.currentPrayer();
      final next = prayerTimes.nextPrayer();
      
      String currentStr = _prayerName(current);
      String nextStr = _prayerName(next);
      String nextTime = DateFormat('HH:mm').format(prayerTimes.timeForPrayer(next)!.toLocal());

      return "Saat ini waktu $currentStr. Jadwal berikutnya adalah $nextStr pada pukul $nextTime.";
    } catch (e) {
      return "Gagal menghitung jadwal shalat. Pastikan GPS aktif.";
    }
  }

  String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr: return "Subuh";
      case Prayer.dhuhr: return "Dzuhur";
      case Prayer.asr: return "Ashar";
      case Prayer.maghrib: return "Maghrib";
      case Prayer.isha: return "Isya";
      case Prayer.sunrise: return "Terbit Matahari";
      case Prayer.none: return "Menunggu Subuh";
      default: return "Tidak diketahui";
    }
  }

  Future<String> getCompassHeading() async {
    try {
      if (FlutterCompass.events == null) {
        return "Sensor kompas tidak terdeteksi pada perangkat keras ini.";
      }
      
      final compassEvent = await FlutterCompass.events!.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TimeoutException("Compass timeout"),
      );
      
      double? heading = compassEvent.heading;
      if (heading == null) return "Gagal mendapatkan arah mata angin.";

      // Convert heading to cardinal direction (Indonesian)
      if (heading >= 337.5 || heading < 22.5) return "Arah mata angin menghadap ke Utara.";
      if (heading >= 22.5 && heading < 67.5) return "Arah mata angin menghadap ke Timur Laut.";
      if (heading >= 67.5 && heading < 112.5) return "Arah mata angin menghadap ke Timur.";
      if (heading >= 112.5 && heading < 157.5) return "Arah mata angin menghadap ke Tenggara.";
      if (heading >= 157.5 && heading < 202.5) return "Arah mata angin menghadap ke Selatan.";
      if (heading >= 202.5 && heading < 247.5) return "Arah mata angin menghadap ke Barat Daya.";
      if (heading >= 247.5 && heading < 292.5) return "Arah mata angin menghadap ke Barat.";
      if (heading >= 292.5 && heading < 337.5) return "Arah mata angin menghadap ke Barat Laut.";
      
      return "Arah mata angin terdeteksi.";
    } catch (e) {
      return "Sensor kompas tidak tersedia di perangkat ini.";
    }
  }

  Future<String> getNearestPoi() async {
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        if (p.name != null && p.name!.isNotEmpty) {
          return "Titik kenal terdekat adalah ${p.name}.";
        }
        return "Tidak ditemukan titik kenal spesifik di koordinat ini.";
      }
      return "Gagal mencari titik kenal terdekat.";
    } catch (e) {
      return "Layanan titik kenal tidak tersedia.";
    }
  }

  Future<double?> getQiblaAngle() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final coordinates = Coordinates(position.latitude, position.longitude);
      final qibla = Qibla(coordinates);
      return qibla.direction;
    } catch (e) {
      return null;
    }
  }
}
