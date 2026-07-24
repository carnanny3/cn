import 'package:dio/dio.dart';

/// Base URL is overridable at build/run time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api/v1
/// Defaults to the Android emulator's alias for the host machine's
/// localhost. iOS simulator / desktop should use http://localhost:3000/api/v1.
const _defaultBaseUrl = 'http://10.0.2.2:3000/api/v1';

class ApiClient {
  ApiClient({String? baseUrl, this.onUnauthorized})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ??
                const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl),
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (accessToken != null) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  String? accessToken;
  void Function()? onUnauthorized;

  /// Surfaces the backend's `{ error: { code, message, details } }` envelope
  /// as a readable string; falls back to Dio's own message otherwise.
  static String messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map && data['error']['message'] is String) {
      return data['error']['message'] as String;
    }
    return e.message ?? 'Something went wrong. Please try again.';
  }
}
