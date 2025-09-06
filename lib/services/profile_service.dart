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

  /// PUT /profile/me/avatar (VIP only)
  /// Multipart upload with field name 'avatar'. Returns updated profile.
  static Future<ProfileResponseModel> uploadMyAvatar({
    required String filePath,
  }) async {
    final fileName = filePath.split('/').isNotEmpty
        ? filePath.split('/').last
        : filePath;
    final form = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final Response res = await ApiService.dio.put(
      '/profile/me/avatar',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
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

  /// GET /profile/:userId (Public)
  /// Fetch a user's public profile aggregate by userId.
  static Future<PublicProfileResponseModel> getPublicProfileById(int userId) async {
    final Response res = await ApiService.dio.get('/profile/$userId');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return PublicProfileResponseModel.fromJson(data);
    }
    return PublicProfileResponseModel(
      message: 'Invalid response',
      status: res.statusCode ?? 0,
      profile: null,
    );
  }

  /// GET /profile/search?q=keyword&page=&limit=
  /// Returns a PublicProfileSearchResponseModel
  static Future<PublicProfileSearchResponseModel> searchUsersPublic({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final Response res = await ApiService.dio.get(
      '/profile/search',
      queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return PublicProfileSearchResponseModel.fromJson(data);
    }
    return PublicProfileSearchResponseModel(
      message: 'Invalid response',
      status: res.statusCode ?? 0,
      items: const [],
      page: page,
      limit: limit,
      total: 0,
    );
  }
}
