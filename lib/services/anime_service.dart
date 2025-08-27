import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/anime_model.dart';
import '../models/anime_detail_model.dart';
import '../models/episode_model.dart';
import '../models/episode_progress_model.dart';
import '../models/anime_schedule_model.dart';
import '../models/live_search_model.dart';
import '../utils/secure_storage.dart';

class AnimeService extends ApiService {
  // ==================== LIVE SEARCH ====================
  static Future<LiveSearchResponseModel> getLiveSearch({
    required String query,
    int limit = 10,
    bool includeScore = false,
    bool fuzzy = true,
    String sortBy = 'score',
  }) async {
    try {
      final response = await ApiService.dio.get(
        '/anime/live-search',
        queryParameters: {
          'q': query,
          'limit': limit,
          'includeScore': includeScore,
          'fuzzy': fuzzy,
          'sortBy': sortBy,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 200 && data['data'] != null) {
          return LiveSearchResponseModel.fromJson(data);
        } else {
          throw Exception(data['message'] ?? 'Gagal melakukan live search');
        }
      } else {
        throw Exception('Gagal melakukan live search');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Gagal melakukan live search',
      );
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }

  // ==================== SCHEDULE METHODS ====================
  static Future<AnimeScheduleResponseModel> getAnimeSchedule({
    int limitPerDay = 10,
  }) async {
    try {
      final response = await ApiService.dio.get(
        '/anime/schedule',
        queryParameters: {'limitPerDay': limitPerDay},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 200 && responseData['data'] != null) {
          return AnimeScheduleResponseModel.fromJson(responseData);
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil jadwal anime',
          );
        }
      } else {
        throw Exception('Gagal mengambil jadwal anime');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Gagal mengambil jadwal anime',
      );
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }

  // Get all anime
  static Future<List<AnimeModel>> getAllAnime() async {
    try {
      final response = await ApiService.dio.get('/anime');
      if (response.statusCode == 200) {
        final responseData = response.data;
        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final animeResponse = AnimeResponseModel.fromJson(responseData);
          return animeResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch anime data',
          );
        }
      } else {
        throw Exception('Failed to fetch anime data');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch anime data',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Get anime by genre using path segment e.g. /anime/genre/Action
  static Future<List<AnimeModel>> getAnimeByGenrePath(String genre) async {
    try {
      final response = await ApiService.dio.get('/anime/genre/$genre');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['status'] == 200 && responseData['data'] != null) {
          final animeResponse = AnimeResponseModel.fromJson(responseData);
          return animeResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch anime by genre path',
          );
        }
      } else {
        throw Exception('Failed to fetch anime by genre path');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch anime by genre path',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Get anime A–Z with optional filters and pagination
  static Future<AnimeAZResponseModel> getAnimeAZ({
    String? letter,
    String? genre,
    String? studio,
    int page = 1,
    int limit = 24,
    String order = 'asc',
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
        'order': order,
      };
      if (letter != null && letter.isNotEmpty) query['letter'] = letter;
      if (genre != null && genre.isNotEmpty) query['genre'] = genre;
      if (studio != null && studio.isNotEmpty) query['studio'] = studio;

      final response = await ApiService.dio.get(
        '/anime/a-z',
        queryParameters: query,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['status'] == 200 && responseData['data'] != null) {
          return AnimeAZResponseModel.fromJson(responseData);
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil anime A–Z',
          );
        }
      } else {
        throw Exception('Gagal mengambil anime A–Z');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Gagal mengambil anime A–Z',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Get popular anime (ordered by views)
  static Future<List<AnimeModel>> getPopularAnime() async {
    try {
      print('Fetching popular anime...');
      final response = await ApiService.dio.get('/anime/view');

      if (response.statusCode == 200) {
        final responseData = response.data;
        print('Popular anime response: $responseData');

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final animeResponse = AnimeResponseModel.fromJson(responseData);
          print(
            'Popular anime parsed successfully: ${animeResponse.data.length} items',
          );
          return animeResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch popular anime data',
          );
        }
      } else {
        throw Exception('Failed to fetch popular anime data');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch popular anime data',
      );
    } catch (e) {
      print('Error in getPopularAnime: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // Get anime by genre
  static Future<List<AnimeModel>> getAnimeByGenre(String genre) async {
    try {
      final response = await ApiService.dio.get(
        '/anime',
        queryParameters: {'genre': genre},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final animeResponse = AnimeResponseModel.fromJson(responseData);
          return animeResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch anime by genre',
          );
        }
      } else {
        throw Exception('Failed to fetch anime by genre');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch anime by genre',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Get latest anime
  static Future<List<AnimeModel>> getLatestAnime() async {
    try {
      final response = await ApiService.dio.get(
        '/anime',
        queryParameters: {'sort': 'latest'},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final animeResponse = AnimeResponseModel.fromJson(responseData);
          return animeResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch latest anime data',
          );
        }
      } else {
        throw Exception('Failed to fetch latest anime data');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch latest anime data',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Get anime movies
  static Future<List<AnimeModel>> getAnimeMovies() async {
    try {
      final response = await ApiService.dio.get(
        '/anime',
        queryParameters: {'type': 'movie'},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final animeResponse = AnimeResponseModel.fromJson(responseData);
          return animeResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch anime movies',
          );
        }
      } else {
        throw Exception('Failed to fetch anime movies');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch anime movies',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Get recommended anime
  static Future<List<AnimeModel>> getRecommendedAnime() async {
    try {
      final response = await ApiService.dio.get(
        '/anime',
        queryParameters: {'sort': 'recommended'},
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final animeResponse = AnimeResponseModel.fromJson(responseData);
          return animeResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch recommended anime',
          );
        }
      } else {
        throw Exception('Failed to fetch recommended anime');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to fetch recommended anime',
      );
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // ==================== ANIME DETAIL METHODS ====================

  // Get anime detail by ID
  static Future<AnimeDetailModel> getAnimeDetail(int animeId) async {
    try {
      final response = await ApiService.dio.get('/anime/$animeId');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final animeDetailResponse = AnimeDetailResponseModel.fromJson(
            responseData,
          );
          return animeDetailResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil detail anime',
          );
        }
      } else {
        throw Exception('Gagal mengambil detail anime');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Gagal mengambil detail anime',
      );
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }

  // ==================== EPISODE METHODS ====================

  // Get episodes by anime ID
  static Future<List<EpisodeModel>> getEpisodesByAnimeId(int animeId) async {
    try {
      final response = await ApiService.dio.get('/episode/anime/$animeId');

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final episodeResponse = EpisodeResponseModel.fromJson(responseData);
          return episodeResponse.sortedEpisodes; // Return sorted episodes
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil data episode',
          );
        }
      } else {
        throw Exception('Gagal mengambil data episode');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Gagal mengambil data episode',
      );
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }

  // Get episode by anime ID and episode number
  static Future<EpisodeModel?> getEpisodeByNumber(
    int animeId,
    int episodeNumber,
  ) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      return episodes.firstWhere(
        (episode) => episode.nomorEpisode == episodeNumber,
        orElse: () => throw Exception('Episode tidak ditemukan'),
      );
    } catch (e) {
      return null;
    }
  }

  // Get latest episode for anime
  static Future<EpisodeModel?> getLatestEpisode(int animeId) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      if (episodes.isEmpty) return null;
      return episodes.last;
    } catch (e) {
      return null;
    }
  }

  // Get first episode for anime
  static Future<EpisodeModel?> getFirstEpisode(int animeId) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      if (episodes.isEmpty) return null;
      return episodes.first;
    } catch (e) {
      return null;
    }
  }

  // Get total episodes count for anime
  static Future<int> getTotalEpisodes(int animeId) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      return episodes.length;
    } catch (e) {
      return 0;
    }
  }

  // Check if anime has episodes
  static Future<bool> hasEpisodes(int animeId) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      return episodes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get episodes with specific quality
  static Future<List<EpisodeModel>> getEpisodesWithQuality(
    int animeId,
    String quality,
  ) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      return episodes.where((episode) => episode.hasQuality(quality)).toList();
    } catch (e) {
      return [];
    }
  }

  // Get episodes range (e.g., episode 1-10)
  static Future<List<EpisodeModel>> getEpisodesRange(
    int animeId,
    int startEpisode,
    int endEpisode,
  ) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      return episodes
          .where(
            (episode) =>
                episode.nomorEpisode >= startEpisode &&
                episode.nomorEpisode <= endEpisode,
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Search episodes by title
  static Future<List<EpisodeModel>> searchEpisodes(
    int animeId,
    String searchQuery,
  ) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      final query = searchQuery.toLowerCase();
      return episodes
          .where(
            (episode) =>
                episode.judulEpisode.toLowerCase().contains(query) ||
                episode.deskripsiEpisode.toLowerCase().contains(query),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get episodes with best quality available
  static Future<List<EpisodeModel>> getEpisodesWithBestQuality(
    int animeId,
  ) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);
      return episodes.where((episode) => episode.bestQuality != null).toList();
    } catch (e) {
      return [];
    }
  }

  // Get episode statistics
  static Future<Map<String, dynamic>> getEpisodeStatistics(int animeId) async {
    try {
      final episodes = await getEpisodesByAnimeId(animeId);

      if (episodes.isEmpty) {
        return {
          'total_episodes': 0,
          'total_duration': 0,
          'average_duration': 0,
          'available_qualities': [],
          'latest_episode': null,
          'first_episode': null,
        };
      }

      final totalDuration = episodes.fold<int>(
        0,
        (sum, episode) => sum + episode.durasiEpisode,
      );
      final averageDuration = totalDuration / episodes.length;

      // Get all available qualities
      final allQualities = <String>{};
      for (final episode in episodes) {
        for (final quality in episode.qualities) {
          allQualities.add(quality.namaQuality);
        }
      }

      return {
        'total_episodes': episodes.length,
        'total_duration': totalDuration,
        'average_duration': averageDuration.round(),
        'available_qualities': allQualities.toList()..sort(),
        'latest_episode': episodes.last.nomorEpisode,
        'first_episode': episodes.first.nomorEpisode,
      };
    } catch (e) {
      return {
        'total_episodes': 0,
        'total_duration': 0,
        'average_duration': 0,
        'available_qualities': [],
        'latest_episode': null,
        'first_episode': null,
      };
    }
  }

  // ==================== EPISODE PROGRESS METHODS ====================

  // Get all episode progress for authenticated user
  static Future<List<EpisodeProgressModel>> getUserEpisodeProgress() async {
    try {
      // Get token from secure storage
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception(
          'Token tidak ditemukan. Silakan login terlebih dahulu.',
        );
      }

      final response = await ApiService.dio.get(
        '/episode/user/progress',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final progressResponse = EpisodeProgressResponseModel.fromJson(
            responseData,
          );
          return progressResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil data progress',
          );
        }
      } else {
        throw Exception('Gagal mengambil data progress');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Token tidak valid. Silakan login ulang.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Akses ditolak. Silakan login terlebih dahulu.');
      } else {
        throw Exception(
          e.response?.data?['message'] ?? 'Gagal mengambil data progress',
        );
      }
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }

  // Get episode progress by anime ID
  static Future<List<EpisodeProgressModel>> getEpisodeProgress(
    int animeId,
  ) async {
    try {
      // Get token from secure storage
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception(
          'Token tidak ditemukan. Silakan login terlebih dahulu.',
        );
      }

      final response = await ApiService.dio.get(
        '/episode/user/progress/anime/$animeId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final progressResponse = EpisodeProgressResponseModel.fromJson(
            responseData,
          );
          return progressResponse.data;
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil data progress',
          );
        }
      } else {
        throw Exception('Gagal mengambil data progress');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Token tidak valid. Silakan login ulang.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Akses ditolak. Silakan login terlebih dahulu.');
      } else {
        throw Exception(
          e.response?.data?['message'] ?? 'Gagal mengambil data progress',
        );
      }
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }

  // Get episode progress statistics
  static Future<Map<String, dynamic>> getEpisodeProgressStatistics(
    int animeId,
  ) async {
    try {
      final progressList = await getEpisodeProgress(animeId);
      final progressResponse = EpisodeProgressResponseModel(
        status: 200,
        message: 'Success',
        data: progressList,
      );

      return {
        'total_episodes': progressResponse.totalEpisodes,
        'completed_episodes': progressResponse.totalCompletedEpisodes,
        'partially_watched_episodes':
            progressResponse.partiallyWatchedEpisodes.length,
        'not_started_episodes': progressResponse.notStartedEpisodes.length,
        'total_progress_percentage': progressResponse.totalProgressPercentage,
        'total_watch_time': progressResponse.formattedTotalWatchTime,
        'latest_watched_episode':
            progressResponse.latestWatchedEpisode?.episode.nomorEpisode,
        'next_episode_to_watch':
            progressResponse.nextEpisodeToWatch?.episode.nomorEpisode,
      };
    } catch (e) {
      return {
        'total_episodes': 0,
        'completed_episodes': 0,
        'partially_watched_episodes': 0,
        'not_started_episodes': 0,
        'total_progress_percentage': 0.0,
        'total_watch_time': '0m',
        'latest_watched_episode': null,
        'next_episode_to_watch': null,
      };
    }
  }

  // Get progress by episode number
  static Future<EpisodeProgressModel?> getProgressByEpisodeNumber(
    int animeId,
    int episodeNumber,
  ) async {
    try {
      final progressList = await getEpisodeProgress(animeId);
      final progressResponse = EpisodeProgressResponseModel(
        status: 200,
        message: 'Success',
        data: progressList,
      );
      return progressResponse.getProgressByEpisodeNumber(episodeNumber);
    } catch (e) {
      return null;
    }
  }

  // Get latest watched episode progress
  static Future<EpisodeProgressModel?> getLatestWatchedEpisodeProgress(
    int animeId,
  ) async {
    try {
      final progressList = await getEpisodeProgress(animeId);
      final progressResponse = EpisodeProgressResponseModel(
        status: 200,
        message: 'Success',
        data: progressList,
      );
      return progressResponse.latestWatchedEpisode;
    } catch (e) {
      return null;
    }
  }

  // Get next episode to watch progress
  static Future<EpisodeProgressModel?> getNextEpisodeToWatchProgress(
    int animeId,
  ) async {
    try {
      final progressList = await getEpisodeProgress(animeId);
      final progressResponse = EpisodeProgressResponseModel(
        status: 200,
        message: 'Success',
        data: progressList,
      );
      return progressResponse.nextEpisodeToWatch;
    } catch (e) {
      return null;
    }
  }

  // Get completed episodes progress
  static Future<List<EpisodeProgressModel>> getCompletedEpisodesProgress(
    int animeId,
  ) async {
    try {
      final progressList = await getEpisodeProgress(animeId);
      final progressResponse = EpisodeProgressResponseModel(
        status: 200,
        message: 'Success',
        data: progressList,
      );
      return progressResponse.completedEpisodes;
    } catch (e) {
      return [];
    }
  }

  // Get partially watched episodes progress
  static Future<List<EpisodeProgressModel>> getPartiallyWatchedEpisodesProgress(
    int animeId,
  ) async {
    try {
      final progressList = await getEpisodeProgress(animeId);
      final progressResponse = EpisodeProgressResponseModel(
        status: 200,
        message: 'Success',
        data: progressList,
      );
      return progressResponse.partiallyWatchedEpisodes;
    } catch (e) {
      return [];
    }
  }

  // Check if user has any progress for anime
  static Future<bool> hasEpisodeProgress(int animeId) async {
    try {
      final progressList = await getEpisodeProgress(animeId);
      return progressList.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get total watch time for anime
  static Future<String> getTotalWatchTime(int animeId) async {
    try {
      final progressList = await getEpisodeProgress(animeId);
      final progressResponse = EpisodeProgressResponseModel(
        status: 200,
        message: 'Success',
        data: progressList,
      );
      return progressResponse.formattedTotalWatchTime;
    } catch (e) {
      return '0m';
    }
  }

  // Get total progress percentage for anime
  static Future<int> getTotalProgressPercentage(int animeId) async {
    try {
      // Get token from secure storage
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception(
          'Token tidak ditemukan. Silakan login terlebih dahulu.',
        );
      }

      final response = await ApiService.dio.get(
        '/episode/user/progress/anime/$animeId/total',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // Check if response has the expected structure
        if (responseData['status'] == 200 && responseData['data'] != null) {
          final data = responseData['data'];
          return data['progress_percentage'] ?? 0;
        } else {
          throw Exception(
            responseData['message'] ?? 'Gagal mengambil data total progress',
          );
        }
      } else {
        throw Exception('Gagal mengambil data total progress');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Token tidak valid. Silakan login ulang.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Akses ditolak. Silakan login terlebih dahulu.');
      } else {
        throw Exception(
          e.response?.data?['message'] ?? 'Gagal mengambil data total progress',
        );
      }
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }
}
