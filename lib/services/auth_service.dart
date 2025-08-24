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
    required int userid,
  }) async {
    try {
      final response = await ApiService.dio.post(
        "/auth/register",
        data: {
          "username": username,
          "email": email,
          "password": password,
          "userid": userid,
        },
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
