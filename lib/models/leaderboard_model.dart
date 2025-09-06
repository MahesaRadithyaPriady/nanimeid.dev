import 'package:meta/meta.dart';

@immutable
class LeaderboardUserModel {
  final int id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final Map<String, dynamic>? vip;

  const LeaderboardUserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.vip,
  });

  factory LeaderboardUserModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardUserModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      username: (json['username'] ?? '').toString(),
      fullName: json['fullName']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      vip: json['vip'] is Map<String, dynamic> ? json['vip'] as Map<String, dynamic> : null,
    );
  }
}

@immutable
class LeaderboardEntryModel {
  final int rank;
  final LeaderboardUserModel user;
  final int totalXp;

  const LeaderboardEntryModel({
    required this.rank,
    required this.user,
    required this.totalXp,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] is int ? json['rank'] as int : int.tryParse('${json['rank']}') ?? 0,
      user: LeaderboardUserModel.fromJson(json['user'] as Map<String, dynamic>),
      totalXp: json['total_xp'] is int ? json['total_xp'] as int : int.tryParse('${json['total_xp']}') ?? 0,
    );
  }
}

@immutable
class LeaderboardDataModel {
  final String period; // daily/weekly/monthly
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final List<LeaderboardEntryModel> entries;

  const LeaderboardDataModel({
    required this.period,
    required this.periodStart,
    required this.periodEnd,
    required this.entries,
  });

  factory LeaderboardDataModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List?) ?? const [];
    return LeaderboardDataModel(
      period: (json['period'] ?? 'daily').toString(),
      periodStart: json['period_start'] != null ? DateTime.tryParse(json['period_start'].toString()) : null,
      periodEnd: json['period_end'] != null ? DateTime.tryParse(json['period_end'].toString()) : null,
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map((e) => LeaderboardEntryModel.fromJson(e))
          .toList(),
    );
  }
}

@immutable
class LeaderboardResponseModel {
  final String message;
  final int code;
  final LeaderboardDataModel? data;

  const LeaderboardResponseModel({
    required this.message,
    required this.code,
    required this.data,
  });

  factory LeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponseModel(
      message: (json['message'] ?? '').toString(),
      code: json['code'] is int ? json['code'] as int : int.tryParse('${json['code']}') ?? 0,
      data: json['data'] is Map<String, dynamic> ? LeaderboardDataModel.fromJson(json['data'] as Map<String, dynamic>) : null,
    );
  }
}
