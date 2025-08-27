import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/profile_model.dart';

class ProfileService {
  /// GET /profile/me using bearer token from ApiService interceptor
  /// Returns a typed ProfileResponseModel
  static Future<ProfileResponseModel> getMyProfile() async {
    final Response res = await ApiService.dio.get('/profile/me');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ProfileResponseModel.fromJson(data);
    }
    // Fallback: wrap non-map into a default response
    return ProfileResponseModel(
      message: 'Invalid response',
      status: res.statusCode ?? 0,
      profile: null,
    );
  }

  /// PUT /profile/me to update current user's profile
  /// Accepts nullable fields; only sends provided values.
  static Future<ProfileResponseModel> updateMyProfile({
    required String fullName,
    String? bio,
    String? avatarUrl,
    DateTime? birthdate,
    String? gender,
  }) async {
    final Map<String, dynamic> payload = {
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (birthdate != null) 'birthdate': birthdate.toIso8601String(),
      if (gender != null) 'gender': gender,
    };

    final Response res = await ApiService.dio.put('/profile/me', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ProfileResponseModel.fromJson(data);
    }
    return ProfileResponseModel(
      message: 'Invalid response',
      status: res.statusCode ?? 0,
      profile: null,
    );
  }
}
