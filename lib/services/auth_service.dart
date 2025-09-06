import 'package:dio/dio.dart';
import '../utils/secure_storage.dart';
import 'api_service.dart';

class AuthService {
  // LOGIN
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      final response = await ApiService.dio.post(
        "/auth/login",
        data: {"username": username, "password": password},
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        await SecureStorage.saveToken(response.data['token']);
        return {
          "success": true,
          "message": "Login berhasil",
          "token": response.data['token'],
        };
      }

      return {
        "success": false,
        "message": response.data?['error'] ?? "Login gagal",
      };
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data?['error'] ?? "Login error",
      };
    }
  }

  // REGISTER
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        "username": username,
        "email": email,
        "password": password,
      };

      final response = await ApiService.dio.post(
        "/auth/register",
        data: payload,
      );

      if (response.statusCode == 201) {
        if (response.data['token'] != null) {
          await SecureStorage.saveToken(response.data['token']);
        }
        return {
          "success": true,
          "message": response.data?['message'] ?? "Register berhasil",
        };
      }

      return {
        "success": false,
        "message": response.data?['error'] ?? "Register gagal",
      };
    } on DioException catch (e) {
      return {
        "success": false,
        "message": e.response?.data?['error'] ?? "Register error",
      };
    }
  }

  // CHANGE PASSWORD
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.dio.post(
        "/auth/change-password",
        data: {
          "old_password": oldPassword,
          "new_password": newPassword,
        },
      );

      final dynamic data = response.data;
      final int status = data is Map<String, dynamic>
          ? (data['status'] as int? ?? response.statusCode ?? 0)
          : (response.statusCode ?? 0);
      final String message = data is Map<String, dynamic>
          ? (data['message']?.toString() ?? 'Password berhasil diubah')
          : 'Password berhasil diubah';

      return {
        "success": status == 200,
        "message": message,
      };
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          'Gagal mengubah password';
      return {
        "success": false,
        "message": msg.toString(),
      };
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  // CEK LOGIN
  static Future<bool> isLoggedIn() async {
    final token = await SecureStorage.getToken();
    return token != null;
  }
}
