import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/episode_detail_model.dart';

class EpisodeService extends ApiService {
  // Get episode detail by episode ID
  static Future<EpisodeDetailModel> getEpisodeDetail(int episodeId) async {
    try {
      final response = await ApiService.dio.get('/episode/$episodeId');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final episodeDetailResponse = EpisodeDetailResponseModel.fromJson(
            responseData,
          );
          return episodeDetailResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil detail episode',
          );
        }
      } else {
        throw Exception('Gagal mengambil detail episode');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Gagal mengambil detail episode',
      );
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }

  // Get episode detail with authentication (if needed for user-specific data)
  static Future<EpisodeDetailModel> getEpisodeDetailWithAuth(
    int episodeId,
  ) async {
    try {
      // Get token from secure storage if needed
      // final token = await SecureStorage.getToken();

      final response = await ApiService.dio.get(
        '/episode/$episodeId',
        // options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final episodeDetailResponse = EpisodeDetailResponseModel.fromJson(
            responseData,
          );
          return episodeDetailResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil detail episode',
          );
        }
      } else {
        throw Exception('Gagal mengambil detail episode');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Token tidak valid. Silakan login ulang.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Akses ditolak. Silakan login terlebih dahulu.');
      } else {
        throw Exception(
          e.response?.data?['message'] ?? 'Gagal mengambil detail episode',
        );
      }
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }

  // Get episode video source by quality
  static Future<String?> getEpisodeVideoSource(
    int episodeId,
    String quality,
  ) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      final qualityModel = episodeDetail.getQualityByName(quality);
      return qualityModel?.sourceQuality;
    } catch (e) {
      return null;
    }
  }

  // Get best available video source for episode
  static Future<String?> getBestEpisodeVideoSource(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      final bestQuality = episodeDetail.bestQuality;
      return bestQuality?.sourceQuality;
    } catch (e) {
      return null;
    }
  }

  // Get available qualities for episode
  static Future<List<String>> getEpisodeQualities(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.availableQualityNames;
    } catch (e) {
      return [];
    }
  }

  // Check if episode has specific quality
  static Future<bool> episodeHasQuality(int episodeId, String quality) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.hasQuality(quality);
    } catch (e) {
      return false;
    }
  }

  // Get episode duration
  static Future<int> getEpisodeDuration(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.durasiEpisode;
    } catch (e) {
      return 0;
    }
  }

  // Get formatted episode duration
  static Future<String> getFormattedEpisodeDuration(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.formattedDuration;
    } catch (e) {
      return '0m';
    }
  }

  // Get episode thumbnail
  static Future<String> getEpisodeThumbnail(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.thumbnailEpisode;
    } catch (e) {
      return '';
    }
  }

  // Get episode description
  static Future<String> getEpisodeDescription(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.deskripsiEpisode;
    } catch (e) {
      return '';
    }
  }

  // Get episode title
  static Future<String> getEpisodeTitle(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.judulEpisode;
    } catch (e) {
      return '';
    }
  }

  // Get episode number
  static Future<int> getEpisodeNumber(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.nomorEpisode;
    } catch (e) {
      return 0;
    }
  }

  // Get anime info from episode
  static Future<Map<String, dynamic>?> getAnimeInfoFromEpisode(
    int episodeId,
  ) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.anime.toMap();
    } catch (e) {
      return null;
    }
  }

  // Check if episode is recently released
  static Future<bool> isEpisodeRecentlyReleased(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.isRecentlyReleased;
    } catch (e) {
      return false;
    }
  }

  // Get episode release date
  static Future<String> getEpisodeReleaseDate(int episodeId) async {
    try {
      final episodeDetail = await getEpisodeDetail(episodeId);
      return episodeDetail.formattedReleaseDate;
    } catch (e) {
      return '';
    }
  }
}
