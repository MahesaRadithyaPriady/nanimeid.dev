import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/wallet_model.dart';
import '../utils/secure_storage.dart';

class StoreService {
  /// GET /store/wallet
  /// Returns current user's wallet with coins balance
  static Future<WalletModel> getWallet() async {
    final Dio dio = ApiService.dio;
    try {
      // Explicitly attach Bearer token from SecureStorage
      final String? token = await SecureStorage.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login terlebih dahulu.');
      }

      final Response res = await dio.get(
        '/store/wallet',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return WalletModel.fromJson(data);
      }
      throw Exception('Format respons tidak valid');
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message']?.toString() ?? 'Gagal mengambil wallet')
          : 'Gagal mengambil wallet';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Error tidak terduga: $e');
    }
  }
}
