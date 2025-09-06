import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/watchparty_session_model.dart';

class WatchPartyService {
  // GET /watchparty/sessions?page=1&limit=20
  static Future<Response> listSessions({int page = 1, int limit = 20}) async {
    final dio = ApiService.dio;
    return dio.get(
      '/watchparty/sessions',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
  }

  // POST /watchparty/sessions
  static Future<Response> createSession({
    required int hostUserId,
    required int episodeId,
  }) async {
    final dio = ApiService.dio;
    return dio.post(
      '/watchparty/sessions',
      data: {
        'hostUserId': hostUserId,
        'episodeId': episodeId,
      },
    );
  }

  // GET /watchparty/sessions/:code
  static Future<Response> getSessionByCode(String code) async {
    final dio = ApiService.dio;
    return dio.get('/watchparty/sessions/$code');
  }

  // POST /watchparty/sessions/:code/join
  static Future<Response> joinSession({
    required String code,
  }) async {
    final dio = ApiService.dio;
    return dio.post(
      '/watchparty/sessions/$code/join',
      data: null,
    );
  }

  // GET /watchparty/sessions/:code/messages?take=30
  static Future<Response> getRecentMessages({
    required String code,
    int take = 30,
  }) async {
    final dio = ApiService.dio;
    return dio.get(
      '/watchparty/sessions/$code/messages',
      queryParameters: {
        'take': take,
      },
    );
  }

  // Helpers (typed)
  static Future<WatchPartySessionDetail> getSessionDetailTyped(String code) async {
    final res = await getSessionByCode(code);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return WatchPartySessionDetail.fromJson(data);
    }
    if (data is Map) {
      return WatchPartySessionDetail.fromJson(Map<String, dynamic>.from(data));
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Unexpected session detail response',
      response: res,
    );
  }

  static Future<List<WatchPartyMessage>> getRecentMessagesTyped({
    required String code,
    int take = 30,
  }) async {
    final res = await getRecentMessages(code: code, take: take);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => WatchPartyMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      final list = data['data'] as List;
      return list
          .whereType<Map>()
          .map((e) => WatchPartyMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return <WatchPartyMessage>[];
  }

  // GET /watchparty/sessions/:code/messages/since?sinceId=0&limit=50
  static Future<Response> pollMessagesSince({
    required String code,
    int sinceId = 0,
    int limit = 50,
  }) async {
    final dio = ApiService.dio;
    return dio.get(
      '/watchparty/sessions/$code/messages/since',
      queryParameters: {
        'sinceId': sinceId,
        'limit': limit,
      },
    );
  }

  // POST /watchparty/sessions/:code/messages
  static Future<Response> postMessage({
    required String code,
    required String message,
  }) async {
    final dio = ApiService.dio;
    return dio.post(
      '/watchparty/sessions/$code/messages',
      data: {
        'message': message,
      },
    );
  }

  // GET /watchparty/sessions/:code/player
  static Future<Response> getPlayerState(String code) async {
    final dio = ApiService.dio;
    return dio.get('/watchparty/sessions/$code/player');
  }

  // GET /watchparty/sessions/:code/status
  // Returns: { session: {currentTime, isPaused, ...}, readiness: {...}, participantsCount: number }
  static Future<Response> getStatus(String code) async {
    final dio = ApiService.dio;
    return dio.get('/watchparty/sessions/$code/status');
  }

  // POST /watchparty/sessions/:code/player
  static Future<Response> updatePlayerState({
    required String code,
    double? currentTime,
    bool? isPaused,
  }) async {
    final dio = ApiService.dio;
    final data = <String, dynamic>{};
    if (currentTime != null) data['currentTime'] = currentTime;
    if (isPaused != null) data['isPaused'] = isPaused;
    return dio.post('/watchparty/sessions/$code/player', data: data);
  }

  // GET /watchparty/sessions/:code/participants
  static Future<Response> getParticipants(String code) async {
    final dio = ApiService.dio;
    return dio.get('/watchparty/sessions/$code/participants');
  }

  // POST /watchparty/sessions/:code/ready
  static Future<Response> setReady({
    required String code,
    required bool isReady,
  }) async {
    final dio = ApiService.dio;
    return dio.post(
      '/watchparty/sessions/$code/ready',
      data: { 'isReady': isReady },
    );
  }

  // GET /watchparty/sessions/:code/readiness
  static Future<Response> getReadiness(String code) async {
    final dio = ApiService.dio;
    return dio.get('/watchparty/sessions/$code/readiness');
  }
}
