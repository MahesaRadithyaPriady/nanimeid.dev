import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/app_settings_model.dart';

class SettingsService {
  static Future<AppSettingsResponse> fetchSettings() async {
    final Dio dio = ApiService.dio;
    final res = await dio.get('/settings');
    return AppSettingsResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
