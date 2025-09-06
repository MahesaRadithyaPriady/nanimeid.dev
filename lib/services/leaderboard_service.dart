import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  static Future<LeaderboardResponseModel> getLeaderboard({String? period, int limit = 50}) async {
    try {
      final Dio dio = ApiService.dio;
      Response res;
      final params = {'limit': limit};
      if (period == null || period.isEmpty || period == 'daily') {
        res = await dio.get('/leaderboard', queryParameters: params);
      } else {
        res = await dio.get('/leaderboard/$period', queryParameters: params);
      }
      return LeaderboardResponseModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return LeaderboardResponseModel.fromJson(data);
      }
      rethrow;
    }
  }
}
