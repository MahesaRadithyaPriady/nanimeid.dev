import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/vip_model.dart';

class VipService {
  /// GET /vip/me using ApiService.dio (token handled by interceptor if configured)
  static Future<VipResponseModel> getMyVip() async {
    final Response res = await ApiService.dio.get('/vip/me');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return VipResponseModel.fromJson(data);
    }
    return VipResponseModel(
      message: 'Invalid response',
      status: res.statusCode ?? 0,
      vip: null,
    );
  }
}
