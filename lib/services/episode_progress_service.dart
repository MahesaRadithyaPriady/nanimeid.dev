import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/episode_progress_model.dart';

class EpisodeProgressService {
  /// POST /episode/:episodeId/progress
  static Future<UserEpisodeProgressSingleResponseModel> saveOrUpdateProgress({
    required int episodeId,
    required int progressWatching,
    bool isCompleted = false,
  }) async {
    final Dio dio = ApiService.dio;
    final res = await dio.post(
      '/episode/$episodeId/progress',
      data: {
        'progress_watching': progressWatching,
        'is_completed': isCompleted,
      },
    );
    return UserEpisodeProgressSingleResponseModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  /// GET /episode/:episodeId/progress
  static Future<UserEpisodeProgressSingleResponseModel> getEpisodeProgress(int episodeId) async {
    final Dio dio = ApiService.dio;
    final res = await dio.get('/episode/$episodeId/progress');
    return UserEpisodeProgressSingleResponseModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  /// GET /episode/user/progress
  static Future<EpisodeProgressResponseModel> getAllUserProgress() async {
    final Dio dio = ApiService.dio;
    final res = await dio.get('/episode/user/progress');
    return EpisodeProgressResponseModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  /// GET /episode/user/progress/anime/:animeId
  static Future<EpisodeProgressResponseModel> getUserProgressByAnime(int animeId) async {
    final Dio dio = ApiService.dio;
    final res = await dio.get('/episode/user/progress/anime/$animeId');
    return EpisodeProgressResponseModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }

  /// GET /episode/user/progress/anime/:animeId/total
  static Future<UserAnimeTotalProgressResponseModel> getUserTotalProgressByAnime(int animeId) async {
    final Dio dio = ApiService.dio;
    final res = await dio.get('/episode/user/progress/anime/$animeId/total');
    return UserAnimeTotalProgressResponseModel.fromJson(
      res.data as Map<String, dynamic>,
    );
  }
}
