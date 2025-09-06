import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings_model.dart';
import '../services/settings_service.dart';
import '../config/settings.dart';

class SettingsController {
  SettingsController._();
  static final SettingsController instance = SettingsController._();

  AppSettingsData? _settings;
  DateTime? _lastFetch;
  AppSettingsData? get settings => _settings;

  bool get downloadsEnabled => _settings?.downloadsEnabled == true;

  // Re-entrancy guard to avoid stacking dialogs due to NavigatorObserver.didPush
  bool _enforcing = false;
  // One-time maintenance dialog guard in current app session
  bool _maintenanceShown = false;

  bool isQualityPaid(String quality) {
    final q = quality.trim().toUpperCase();
    final list = _settings?.paidQualities.map((e) => e.toUpperCase()).toList() ?? const [];
    return list.contains(q);
  }

  // Check settings and enforce maintenance/force update when entering a screen
  Future<void> checkAndEnforce(BuildContext context) async {
    if (_enforcing) return;
    _enforcing = true;
    try {
      // Avoid spamming the API too frequently; refresh at most every ~30s
      final now = DateTime.now();
      if (_lastFetch == null || now.difference(_lastFetch!).inSeconds >= 30) {
        final res = await SettingsService.fetchSettings();
        _settings = res.settings;
        _lastFetch = now;
      }

      final s = _settings;
      if (s == null) return;

      // Maintenance: force close app (show only once per session)
      if (s.maintenanceEnabled && !_maintenanceShown && !AppSettings.isDebug) {
        _maintenanceShown = true;
        await _showForceDialog(
          context,
          title: 'Pemeliharaan',
          message: s.maintenanceMessage ?? 'Aplikasi sedang dalam pemeliharaan. Silakan coba lagi nanti.',
        );
        await _forceExit();
        return;
      }

      // Force update: compare versions and force close
      if (s.forceUpdateEnabled && s.forceUpdateVersion != null) {
        final current = AppSettings.appVersion.trim();
        final required = s.forceUpdateVersion!.trim();
        if (_isVersionLower(current, required)) {
          await _showForceDialog(
            context,
            title: 'Pembaruan Diperlukan',
            message: 'Versi aplikasi Anda ($current) sudah usang. Harap perbarui ke versi $required untuk melanjutkan.',
          );
          await _forceExit();
          return;
        }
      }
    } catch (_) {
      // silently ignore failures; app continues
    } finally {
      _enforcing = false;
    }
  }

  bool _isVersionLower(String a, String b) {
    List<int> parse(String v) => v.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pa = parse(a);
    final pb = parse(b);
    final len = (pa.length > pb.length) ? pa.length : pb.length;
    for (int i = 0; i < len; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va < vb;
    }
    return false; // equal or higher
    }

  Future<void> _showForceDialog(BuildContext context, {required String title, required String message}) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppSettings.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          const SizedBox.shrink(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppSettings.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx, rootNavigator: true).pop();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  Future<void> _forceExit() async {
    // Attempt to close the app
    try {
      await SystemNavigator.pop();
    } catch (_) {}
  }
}

class SettingsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final ctx = navigator?.context;
    if (ctx != null) {
      // Hanya jalankan pada PageRoute (hindari DialogRoute/PopupRoute agar tidak loop)
      if (route is PageRoute) {
        // Fire and forget
        SettingsController.instance.checkAndEnforce(ctx);
      }
    }
  }
}
