import 'package:dio/dio.dart';
import '../utils/secure_storage.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://192.168.1.7:3000/",
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {"Content-Type": "application/json"},
    ),
  );

  static Dio get dio => _dio;

  // Tambah interceptor untuk auth token
  static void initialize() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Bisa handle error 401 di sini nanti
          return handler.next(e);
        },
      ),
    );
  }
}
