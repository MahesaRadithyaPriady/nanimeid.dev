class ProfileModel {
  final int id;
  final int userId;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? birthdate;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.birthdate,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProfileModel(
        id: _asInt(json['id']),
        userId: _asInt(json['user_id']),
        fullName: (json['full_name'] ?? '').toString(),
        avatarUrl: json['avatar_url']?.toString(),
        bio: json['bio']?.toString(),
        birthdate: _parseDate(json['birthdate']),
        gender: json['gender']?.toString(),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing ProfileModel: $e');
      // ignore: avoid_print
      print('JSON data: $json');
      rethrow;
    }
  } // Added closing brace here

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'birthdate': _formatDate(birthdate),
      'gender': gender,
      'createdAt': _formatDate(createdAt),
      'updatedAt': _formatDate(updatedAt),
    };
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static String? _formatDate(DateTime? d) => d?.toIso8601String();
}

class ProfileResponseModel {
  final String message;
  final int status;
  final ProfileModel? profile;

  ProfileResponseModel({
    required this.message,
    required this.status,
    required this.profile,
  });

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      return ProfileResponseModel(
        message: (json['message'] ?? '').toString(),
        status: ProfileModel._asInt(json['status']),
        profile: json['profile'] is Map<String, dynamic>
            ? ProfileModel.fromJson(json['profile'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing ProfileResponseModel: $e');
      // ignore: avoid_print
      print('JSON data: $json');
      rethrow;
    }
  }

  bool get isSuccess => status == 200;

  Map<String, dynamic> toJson() => {
        'message': message,
        'status': status,
        'profile': profile?.toJson(),
      };
}

// ===== Public Profile Aggregate (GET /profile/:userId) =====

class PublicVipLiteModel {
  final String status; // e.g., ACTIVE, INACTIVE
  final String? vipLevel; // e.g., Bronze, Silver, Gold, Diamond, Master
  final DateTime? endAt;
  PublicVipLiteModel({required this.status, this.vipLevel, this.endAt});
  factory PublicVipLiteModel.fromJson(Map<String, dynamic> json) {
    return PublicVipLiteModel(
      status: (json['status'] ?? '').toString(),
      vipLevel: json['vip_level']?.toString(),
      endAt: ProfileModel._parseDate(json['endAt']),
    );
  }
}

class PublicXpLiteModel {
  final int currentXp;
  final int levelId;
  PublicXpLiteModel({required this.currentXp, required this.levelId});
  factory PublicXpLiteModel.fromJson(Map<String, dynamic> json) {
    return PublicXpLiteModel(
      currentXp: ProfileModel._asInt(json['current_xp']),
      levelId: ProfileModel._asInt(json['level_id']),
    );
  }
}

class PublicLevelLiteModel {
  final int id;
  final int levelNumber;
  final int xpRequiredTotal;
  final String title; // e.g., Bronze, Silver, Gold, Diamond, Master
  PublicLevelLiteModel({
    required this.id,
    required this.levelNumber,
    required this.xpRequiredTotal,
    required this.title,
  });
  factory PublicLevelLiteModel.fromJson(Map<String, dynamic> json) {
    return PublicLevelLiteModel(
      id: ProfileModel._asInt(json['id']),
      levelNumber: ProfileModel._asInt(json['level_number']),
      xpRequiredTotal: ProfileModel._asInt(json['xp_required_total']),
      title: (json['title'] ?? '').toString(),
    );
  }
}

class PublicStatsModel {
  final int commentsCount;
  final int likesReceived;
  final int likesGiven;
  final int minutesWatched;
  PublicStatsModel({
    required this.commentsCount,
    required this.likesReceived,
    required this.likesGiven,
    required this.minutesWatched,
  });
  factory PublicStatsModel.fromJson(Map<String, dynamic> json) {
    return PublicStatsModel(
      commentsCount: ProfileModel._asInt(json['comments_count']),
      likesReceived: ProfileModel._asInt(json['likes_received']),
      likesGiven: ProfileModel._asInt(json['likes_given']),
      minutesWatched: ProfileModel._asInt(json['minutes_watched']),
    );
  }
}

class PublicXpProgressLiteModel {
  final int currentLevelRequired;
  final int nextLevelRequired;
  final int nextLevelNumber;
  final int xpToNext;
  final int percentToNext; // 0-100
  PublicXpProgressLiteModel({
    required this.currentLevelRequired,
    required this.nextLevelRequired,
    required this.nextLevelNumber,
    required this.xpToNext,
    required this.percentToNext,
  });
  factory PublicXpProgressLiteModel.fromJson(Map<String, dynamic> json) {
    return PublicXpProgressLiteModel(
      currentLevelRequired: ProfileModel._asInt(json['current_level_required']),
      nextLevelRequired: ProfileModel._asInt(json['next_level_required']),
      nextLevelNumber: ProfileModel._asInt(json['next_level_number']),
      xpToNext: ProfileModel._asInt(json['xp_to_next']),
      percentToNext: ProfileModel._asInt(json['percent_to_next']),
    );
  }
}

class PublicProfileAggregateModel {
  final int userId;
  final String username;
  final ProfileModel profile;
  final PublicVipLiteModel? vip;
  final PublicXpLiteModel? xp;
  final PublicLevelLiteModel? level;
  final PublicStatsModel? stats;
  final PublicXpProgressLiteModel? xpProgress;
  PublicProfileAggregateModel({
    required this.userId,
    required this.username,
    required this.profile,
    this.vip,
    this.xp,
    this.level,
    this.stats,
    this.xpProgress,
  });

  factory PublicProfileAggregateModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final profileJson = json['profile'] as Map<String, dynamic>?;
    return PublicProfileAggregateModel(
      userId: ProfileModel._asInt(user?['id']),
      username: (user?['username'] ?? '').toString(),
      profile: ProfileModel.fromJson(profileJson ?? const {}),
      vip: json['vip'] is Map<String, dynamic>
          ? PublicVipLiteModel.fromJson(json['vip'] as Map<String, dynamic>)
          : null,
      xp: json['xp'] is Map<String, dynamic>
          ? PublicXpLiteModel.fromJson(json['xp'] as Map<String, dynamic>)
          : null,
      level: json['level'] is Map<String, dynamic>
          ? PublicLevelLiteModel.fromJson(json['level'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] is Map<String, dynamic>
          ? PublicStatsModel.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      xpProgress: json['xp_progress'] is Map<String, dynamic>
          ? PublicXpProgressLiteModel.fromJson(json['xp_progress'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PublicProfileResponseModel {
  final String message;
  final int status;
  final PublicProfileAggregateModel? profile;
  PublicProfileResponseModel({
    required this.message,
    required this.status,
    required this.profile,
  });

  factory PublicProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileResponseModel(
      message: (json['message'] ?? '').toString(),
      status: ProfileModel._asInt(json['status']),
      profile: json['profile'] is Map<String, dynamic>
          ? PublicProfileAggregateModel.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isSuccess => status == 200;
}

class PublicProfileSearchResponseModel {
  final String message;
  final int status;
  final List<PublicProfileAggregateModel> items;
  final int page;
  final int limit;
  final int total;
  PublicProfileSearchResponseModel({
    required this.message,
    required this.status,
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PublicProfileSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final List<PublicProfileAggregateModel> results = [];
    if (json['items'] is List) {
      for (final item in (json['items'] as List)) {
        if (item is Map<String, dynamic>) {
          results.add(PublicProfileAggregateModel.fromJson(item));
        }
      }
    }
    return PublicProfileSearchResponseModel(
      message: (json['message'] ?? '').toString(),
      status: ProfileModel._asInt(json['status']),
      items: results,
      page: ProfileModel._asInt(json['page']),
      limit: ProfileModel._asInt(json['limit']),
      total: ProfileModel._asInt(json['total']),
    );
  }

  bool get isSuccess => status == 200;
}
