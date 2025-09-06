import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/xp_model.dart';

class XpService {
  /// GET /xp/me
  static Future<XpResponseModel> getMyXp() async {
    final Response res = await ApiService.dio.get('/xp/me');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return XpResponseModel.fromJson(data);
    }
    return XpResponseModel(message: 'Invalid response', code: res.statusCode ?? 0, data: null);
  }

  /// POST /xp/add (no body) - server applies base and VIP multiplier
  static Future<XpResponseModel> addXp() async {
    final Response res = await ApiService.dio.post('/xp/add');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return XpResponseModel.fromJson(data);
    }
    return XpResponseModel(message: 'Invalid response', code: res.statusCode ?? 0, data: null);
  }
}
