import 'package:flutter/material.dart';

class AppSettings {
  /// Apakah aplikasi sedang dalam mode debug (true) atau production (false)
  static const bool isDebug = true;

  /// Base URL API (bisa beda antara dev & prod)
  static const String apiBaseUrl = isDebug
      ? "http://192.168.1.10:3000/" // untuk emulator/dev
      : "https://api.nanimeid.com/"; // untuk production

  /// Nama aplikasi
  static const String appName = "NanimeID";

  /// Warna tema utama
  static const primaryColor = Colors.pinkAccent; // pinkAccent
}
