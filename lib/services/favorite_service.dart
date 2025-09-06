import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/favorite_model.dart';

class FavoriteService {
  static Future<FavoriteResponseModel> getMyFavoriteAnime({required String status}) async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.get('/me/favorites/anime', queryParameters: {
      'status': status,
    });

    return FavoriteResponseModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<bool> toggleAnimeFavorite(int animeId) async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.post('/anime/$animeId/favorite');
    try {
      final data = res.data as Map<String, dynamic>;
      final status = (data['status'] is int)
          ? data['status'] as int
          : int.tryParse(data['status'].toString()) ?? 0;
      return status == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> getAnimeFavoriteStatus(int animeId) async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.get('/anime/$animeId/favorite/status');
    final data = res.data as Map<String, dynamic>;
    final status = (data['status'] is int)
        ? data['status'] as int
        : int.tryParse(data['status'].toString()) ?? 0;
    if (status != 200) return false;
    return (data['isFavorited'] == true) ||
        (data['isFavorited']?.toString().toLowerCase() == 'true');
  }

  static Future<bool> deleteAnimeFavorite(int animeId) async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.delete('/anime/$animeId/favorite');
    final data = res.data as Map<String, dynamic>;
    final status = (data['status'] is int)
        ? data['status'] as int
        : int.tryParse(data['status'].toString()) ?? 0;
    return status == 200;
  }

  // ===================== EPISODE FAVORITES =====================

  static Future<FavoriteEpisodeResponseModel> getMyFavoriteEpisodes() async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.get('/me/favorites/episodes');
    return FavoriteEpisodeResponseModel.fromJson(res.data as Map<String, dynamic>);
  }

  static Future<bool> toggleEpisodeFavorite(int episodeId) async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.post('/episode/$episodeId/favorite');
    try {
      final data = res.data as Map<String, dynamic>;
      final status = (data['status'] is int)
          ? data['status'] as int
          : int.tryParse(data['status'].toString()) ?? 0;
      return status == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteEpisodeFavorite(int episodeId) async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.delete('/episode/$episodeId/favorite');
    final data = res.data as Map<String, dynamic>;
    final status = (data['status'] is int)
        ? data['status'] as int
        : int.tryParse(data['status'].toString()) ?? 0;
    return status == 200;
  }

  static Future<bool> getEpisodeFavoriteStatus(int episodeId) async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.get('/episode/$episodeId/favorite/status');
    final data = res.data as Map<String, dynamic>;
    final status = (data['status'] is int)
        ? data['status'] as int
        : int.tryParse(data['status'].toString()) ?? 0;
    if (status != 200) return false;
    return (data['isFavorited'] == true) ||
        (data['isFavorited']?.toString().toLowerCase() == 'true');
  }

  static Future<EpisodeFavoriteStatsModel> getEpisodeFavoriteStats(int episodeId) async {
    final Dio dio = ApiService.dio;
    final Response res = await dio.get('/episode/$episodeId/favorite');
    return EpisodeFavoriteStatsModel.fromJson(res.data as Map<String, dynamic>);
  }
}
