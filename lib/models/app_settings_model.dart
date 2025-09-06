class AppSettingsResponse {
  final String message;
  final AppSettingsData settings;

  AppSettingsResponse({required this.message, required this.settings});

  factory AppSettingsResponse.fromJson(Map<String, dynamic> json) {
    return AppSettingsResponse(
      message: (json['message'] ?? '').toString(),
      settings: AppSettingsData.fromJson(
        Map<String, dynamic>.from(json['settings'] ?? const {}),
      ),
    );
  }
}

class AppSettingsData {
  final int id;
  final bool maintenanceEnabled;
  final String? maintenanceMessage;
  final bool downloadsEnabled;
  final List<String> paidQualities;
  final bool forceUpdateEnabled;
  final String? forceUpdateVersion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppSettingsData({
    required this.id,
    required this.maintenanceEnabled,
    required this.maintenanceMessage,
    required this.downloadsEnabled,
    required this.paidQualities,
    required this.forceUpdateEnabled,
    required this.forceUpdateVersion,
    this.createdAt,
    this.updatedAt,
  });

  factory AppSettingsData.fromJson(Map<String, dynamic> json) {
    List<String> paid = [];
    final rawPaid = json['paid_qualities'];
    if (rawPaid is List) {
      paid = rawPaid.map((e) => e.toString()).toList();
    }
    DateTime? parseDate(dynamic v) {
      try {
        if (v == null) return null;
        return DateTime.tryParse(v.toString());
      } catch (_) {
        return null;
      }
    }
    return AppSettingsData(
      id: int.tryParse((json['id'] ?? 0).toString()) ?? 0,
      maintenanceEnabled: json['maintenance_enabled'] == true,
      maintenanceMessage: json['maintenance_message']?.toString(),
      downloadsEnabled: json['downloads_enabled'] == true,
      paidQualities: paid,
      forceUpdateEnabled: json['force_update_enabled'] == true,
      forceUpdateVersion: json['force_update_version']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
