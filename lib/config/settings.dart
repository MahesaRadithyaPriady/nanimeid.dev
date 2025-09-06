import 'package:flutter/material.dart';

class AppSettings {
  /// Apakah aplikasi sedang dalam mode debug (true) atau production (false)
  static const bool isDebug = false;

  /// Default (non-VIP) base URL untuk production
  static const String apiBaseUrlProd = "https://mainapps.nanimeid.xyz/";

  /// VIP base URL untuk production
  static const String apiBaseUrlVip = "https://mainapps.nanimeid.xyz/";

  /// Base URL untuk development/local testing
  static const String apiBaseUrlDev = "http://192.168.1.8:4000/";

  /// Backward-compat: previous constant name. Prefer using ApiService dynamic base configuration.
  static const String apiBaseUrl = isDebug ? apiBaseUrlDev : apiBaseUrlProd;

  /// Nama aplikasi
  static const String appName = "NanimeID";

  /// Warna tema utama
  static const primaryColor = Colors.pinkAccent; // pinkAccent

  /// Versi aplikasi saat ini (untuk force update check)
  static const String appVersion = "1.0.0 Beta 0.2";
}
