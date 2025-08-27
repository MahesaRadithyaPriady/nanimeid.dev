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
  }

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
