import 'package:dio/dio.dart';
import 'api_service.dart';

class WatchSessionService {
  /// POST /watch/session/start
  /// Body: { "episodeId": <int> }
  /// Returns: { sessionToken: string, sessionId: number }
  static Future<Map<String, dynamic>> startSession({required int episodeId}) async {
    final Dio dio = ApiService.dio;
    final res = await dio.post(
      '/watch/session/start',
      data: {
        'episodeId': episodeId,
      },
    );
    final data = (res.data is Map<String, dynamic>) ? res.data as Map<String, dynamic> : <String, dynamic>{};
    final inner = (data['data'] is Map<String, dynamic>) ? data['data'] as Map<String, dynamic> : <String, dynamic>{};
    return inner;
  }

  /// POST /watch/progress
  /// Body: { sessionToken: string, positionSec: number, playbackRate: number }
  static Future<void> sendProgress({
    required String sessionToken,
    required int positionSec,
    double playbackRate = 1.0,
  }) async {
    final Dio dio = ApiService.dio;
    await dio.post(
      '/watch/progress',
      data: {
        'sessionToken': sessionToken,
        'positionSec': positionSec,
        'playbackRate': playbackRate,
      },
    );
  }

  /// POST /watch/session/complete
  /// Body: { sessionToken: string }
  /// Returns: { granted: bool, xp: number, duration: number }
  static Future<Map<String, dynamic>> completeSession({required String sessionToken}) async {
    final Dio dio = ApiService.dio;
    final res = await dio.post(
      '/watch/session/complete',
      data: {
        'sessionToken': sessionToken,
      },
    );
    final data = (res.data is Map<String, dynamic>) ? res.data as Map<String, dynamic> : <String, dynamic>{};
    final inner = (data['data'] is Map<String, dynamic>) ? data['data'] as Map<String, dynamic> : <String, dynamic>{};
    return inner;
  }
}
