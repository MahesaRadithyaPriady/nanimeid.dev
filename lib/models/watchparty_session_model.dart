import 'episode_model.dart';

class WatchPartySessionModel {
  final String code;
  final WatchPartyUserMini host;
  final EpisodeModel episode;
  final int participants;

  WatchPartySessionModel({
    required this.code,
    required this.host,
    required this.episode,
    required this.participants,
  });

  factory WatchPartySessionModel.fromJson(Map<String, dynamic> json) {
    final count = (json['_count'] as Map?) ?? {};
    return WatchPartySessionModel(
      code: (json['code'] ?? '').toString(),
      host: WatchPartyUserMini.fromJson((json['host'] as Map?)?.cast<String, dynamic>() ?? {}),
      episode: EpisodeModel.fromJson((json['episode'] as Map?)?.cast<String, dynamic>() ?? {}),
      participants: int.tryParse((count['participants'] ?? 0).toString()) ?? 0,
    );
  }
}

// Detailed session model (per API docs GET /watchparty/sessions/:code)
class WatchPartySessionDetail {
  final int id;
  final String code;
  final int hostUserId;
  final int episodeId;
  final bool isActive;
  final double currentTime;
  final bool isPaused;
  final String? createdAt;
  final String? updatedAt;
  final List<WatchPartyParticipant> participants;
  final Map<String, dynamic>? episode; // raw episode payload if provided

  WatchPartySessionDetail({
    required this.id,
    required this.code,
    required this.hostUserId,
    required this.episodeId,
    required this.isActive,
    required this.currentTime,
    required this.isPaused,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    required this.episode,
  });

  factory WatchPartySessionDetail.fromJson(Map<String, dynamic> json) {
    return WatchPartySessionDetail(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id'] ?? 0}') ?? 0,
      code: (json['code'] ?? '').toString(),
      hostUserId: json['host_user_id'] is int
          ? json['host_user_id'] as int
          : int.tryParse('${json['host_user_id'] ?? 0}') ?? 0,
      episodeId: json['episode_id'] is int
          ? json['episode_id'] as int
          : int.tryParse('${json['episode_id'] ?? 0}') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == 'true',
      currentTime: double.tryParse('${json['current_time'] ?? 0}') ?? 0,
      isPaused: json['is_paused'] == true || json['is_paused'] == 1 || json['is_paused'] == 'true',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      participants: (json['participants'] is List)
          ? (json['participants'] as List)
              .whereType<Map>()
              .map((e) => WatchPartyParticipant.fromJson(e.cast<String, dynamic>()))
              .toList()
          : <WatchPartyParticipant>[],
      episode: (json['episode'] is Map) ? Map<String, dynamic>.from(json['episode'] as Map) : null,
    );
  }
}

class WatchPartyParticipant {
  final int id;
  final int sessionId;
  final int userId;
  final String? role;
  final String? joinedAt;
  final String? lastSeen;
  final WatchPartyUserMini? user;

  WatchPartyParticipant({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.role,
    this.joinedAt,
    this.lastSeen,
    this.user,
  });

  factory WatchPartyParticipant.fromJson(Map<String, dynamic> json) {
    return WatchPartyParticipant(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id'] ?? 0}') ?? 0,
      sessionId: json['session_id'] is int
          ? json['session_id'] as int
          : int.tryParse('${json['session_id'] ?? 0}') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse('${json['user_id'] ?? 0}') ?? 0,
      role: json['role']?.toString(),
      joinedAt: json['joinedAt']?.toString(),
      lastSeen: json['last_seen']?.toString(),
      user: (json['user'] is Map)
          ? WatchPartyUserMini.fromJson((json['user'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}

class WatchPartyUserMini {
  final int id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;

  WatchPartyUserMini({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
  });

  factory WatchPartyUserMini.fromJson(Map<String, dynamic> json) {
    // Support both top-level and nested profile keys
    final profile = (json['profile'] is Map) ? Map<String, dynamic>.from(json['profile'] as Map) : const <String, dynamic>{};
    final fullName = (json['full_name'] ?? json['fullName'] ?? profile['full_name'] ?? profile['fullName'])?.toString();
    final avatarUrl = (json['avatar_url'] ?? json['avatarUrl'] ?? profile['avatar_url'] ?? profile['avatarUrl'])?.toString();
    return WatchPartyUserMini(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id'] ?? 0}') ?? 0,
      username: json['username']?.toString(),
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
  }
}

class WatchPartyMessage {
  final int id;
  final int sessionId;
  final int userId;
  final String message;
  final String? createdAt;
  final WatchPartyUserMini? user;

  WatchPartyMessage({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.message,
    this.createdAt,
    this.user,
  });

  factory WatchPartyMessage.fromJson(Map<String, dynamic> json) {
    return WatchPartyMessage(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id'] ?? 0}') ?? 0,
      sessionId: json['session_id'] is int
          ? json['session_id'] as int
          : int.tryParse('${json['session_id'] ?? 0}') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse('${json['user_id'] ?? 0}') ?? 0,
      message: (json['message'] ?? '').toString(),
      createdAt: json['createdAt']?.toString(),
      user: (json['user'] is Map)
          ? WatchPartyUserMini.fromJson((json['user'] as Map).cast<String, dynamic>())
          : null,
    );
  }
}
