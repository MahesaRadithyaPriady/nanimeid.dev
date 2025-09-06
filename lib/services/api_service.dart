import 'package:dio/dio.dart';
import '../utils/secure_storage.dart';
import '../config/settings.dart';

class ApiService {
  static bool _useVip = false;

  static String _resolveBaseUrl() {
    if (AppSettings.isDebug) {
      return AppSettings.apiBaseUrlDev;
    }
    return _useVip ? AppSettings.apiBaseUrlVip : AppSettings.apiBaseUrlProd;
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _resolveBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
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
        onError: (DioException e, handler) async {
          // Fallback: jika menggunakan VIP base dan gagal (timeout/network/5xx),
          // ganti ke non-VIP base dan retry sekali.
          final opts = e.requestOptions;
          final alreadyRetried = opts.extra['fallbackRetried'] == true;

          final isNetworkError = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.unknown;

          final status = e.response?.statusCode ?? 0;
          final isServerError = status >= 500 && status < 600;

          if (!AppSettings.isDebug && _useVip && !alreadyRetried && (isNetworkError || isServerError)) {
            // Switch to non-VIP base and retry once
            _useVip = false;
            _dio.options.baseUrl = _resolveBaseUrl();

            final newOptions = Options(
              method: opts.method,
              headers: opts.headers,
              responseType: opts.responseType,
              contentType: opts.contentType,
              followRedirects: opts.followRedirects,
              receiveDataWhenStatusError: opts.receiveDataWhenStatusError,
              validateStatus: opts.validateStatus,
            );

            final retryRequestOptions = RequestOptions(
              path: opts.path,
              method: opts.method,
              headers: opts.headers,
              queryParameters: opts.queryParameters,
              data: opts.data,
              baseUrl: _dio.options.baseUrl,
            );
            retryRequestOptions.extra.addAll(opts.extra);
            retryRequestOptions.extra['fallbackRetried'] = true;

            try {
              final response = await _dio.fetch<dynamic>(retryRequestOptions);
              return handler.resolve(response);
            } catch (err) {
              // Return original error chain if retry also fails
              return handler.next(e);
            }
          }

          // Bisa handle error 401 di sini nanti
          return handler.next(e);
        },
      ),
    );
  }

  /// Set apakah user VIP atau bukan, dan update baseUrl sesuai.
  /// Prod: VIP -> mainapps, Non-VIP -> apps. Debug selalu pakai dev.
  static void setVip(bool isVip) {
    _useVip = isVip;
    _dio.options.baseUrl = _resolveBaseUrl();
  }
}
