class CommentUserProfileModel {
  final int id;
  final int userId;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? birthdate;
  final String? gender;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CommentUserProfileModel({
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

  factory CommentUserProfileModel.fromJson(Map<String, dynamic> json) {
    return CommentUserProfileModel(
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
  }
}

class CommentVipModel {
  final int id;
  final int userId;
  final String vipLevel;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool autoRenew;
  final String? paymentMethod;
  final DateTime? lastPaymentAt;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CommentVipModel({
    required this.id,
    required this.userId,
    required this.vipLevel,
    this.startAt,
    this.endAt,
    required this.autoRenew,
    this.paymentMethod,
    this.lastPaymentAt,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CommentVipModel.fromJson(Map<String, dynamic> json) {
    return CommentVipModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      vipLevel: (json['vip_level'] ?? '').toString(),
      startAt: _parseDate(json['start_at']),
      endAt: _parseDate(json['end_at']),
      autoRenew: _asBool(json['auto_renew']),
      paymentMethod: json['payment_method']?.toString(),
      lastPaymentAt: _parseDate(json['last_payment_at']),
      status: (json['status'] ?? '').toString(),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class CommentUserModel {
  final int id;
  final int userID;
  final String username;
  final String email;
  final String password; // hashed
  final DateTime? createdAt;
  final CommentUserProfileModel? profile;
  final CommentVipModel? vip;

  CommentUserModel({
    required this.id,
    required this.userID,
    required this.username,
    required this.email,
    required this.password,
    this.createdAt,
    this.profile,
    this.vip,
  });

  factory CommentUserModel.fromJson(Map<String, dynamic> json) {
    return CommentUserModel(
      id: _asInt(json['id']),
      userID: _asInt(json['userID']),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']),
      profile: json['profile'] is Map<String, dynamic>
          ? CommentUserProfileModel.fromJson(
              json['profile'] as Map<String, dynamic>,
            )
          : null,
      vip: json['vip'] is Map<String, dynamic>
          ? CommentVipModel.fromJson(json['vip'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CommentCountModel {
  final int likes;
  CommentCountModel({required this.likes});
  factory CommentCountModel.fromJson(Map<String, dynamic> json) {
    return CommentCountModel(likes: _asInt(json['likes']));
  }
}

class CommentModel {
  final int id;
  final int userId;
  final int animeId;
  final int? episodeId;
  final String content;
  final bool isEdited;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CommentUserModel? user;
  final CommentCountModel? count;
  final bool likedByMe;

  CommentModel({
    required this.id,
    required this.userId,
    required this.animeId,
    required this.episodeId,
    required this.content,
    required this.isEdited,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.count,
    required this.likedByMe,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      animeId: _asInt(json['anime_id']),
      episodeId: json['episode_id'] == null ? null : _asInt(json['episode_id']),
      content: (json['content'] ?? '').toString(),
      isEdited: _asBool(json['is_edited']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      user: json['user'] is Map<String, dynamic>
          ? CommentUserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      count: json['_count'] is Map<String, dynamic>
          ? CommentCountModel.fromJson(json['_count'] as Map<String, dynamic>)
          : null,
      likedByMe: _asBool(json['likedByMe']),
    );
  }
}

class CommentListResponseModel {
  final String message;
  final int status;
  final List<CommentModel> comments;

  CommentListResponseModel({
    required this.message,
    required this.status,
    required this.comments,
  });

  factory CommentListResponseModel.fromJson(Map<String, dynamic> json) {
    final List<CommentModel> list = [];
    if (json['comments'] is List) {
      for (final item in (json['comments'] as List)) {
        if (item is Map<String, dynamic>) {
          list.add(CommentModel.fromJson(item));
        }
      }
    }
    return CommentListResponseModel(
      message: (json['message'] ?? '').toString(),
      status: _asInt(json['status']),
      comments: list,
    );
  }
}

// Helpers (kept local to this file for consistency with other models)
int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v == null) return false;
  final s = v.toString().toLowerCase();
  return s == 'true' || s == '1';
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}
