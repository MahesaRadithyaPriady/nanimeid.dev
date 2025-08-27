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
}
