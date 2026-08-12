import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Centralized HTTP client for the existing RiderCraft Express API.
///
/// - Attaches `Authorization: Bearer <token>` on every request via an
///   interceptor (token supplied through [tokenProvider]).
/// - Maps every failure to [ApiException] with a user-friendly message.
/// - Fires [onUnauthorized] when the backend rejects the token (401) so the
///   app can log the user out cleanly.
class ApiClient {
  final Dio _dio;
  final String? Function()? tokenProvider;
  final void Function()? onUnauthorized;

  ApiClient({
    this.tokenProvider,
    this.onUnauthorized,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = AppConfig.apiBaseUrl
      ..connectTimeout = AppConfig.connectTimeout
      ..receiveTimeout = AppConfig.receiveTimeout
      ..responseType = ResponseType.json
      ..headers['Accept'] = 'application/json';

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = tokenProvider?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: query,
        options: Options(headers: headers),
      );
      return _decode(response);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: query,
        options: Options(headers: headers),
      );
      return _decode(response);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return _decode(response);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return _decode(response);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        options: Options(headers: headers),
      );
      return _decode(response);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  /// Returns the decoded body. Lists are returned as-is.
  dynamic _decode(Response<dynamic> response) {
    if (response.data is Map<String, dynamic>) {
      return response.data;
    }
    if (response.data is List) {
      return response.data;
    }
    if (response.data == null) return <String, dynamic>{};
    // JSON primitives (string/number/bool) returned by some endpoints.
    return response.data;
  }

  ApiException _mapError(DioException error) {
    final statusCode = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        message: 'The request timed out. Please check your connection.',
        isTimeout: true,
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      return const ApiException(
        message: 'Could not reach the server. Check your internet connection.',
        isNetworkError: true,
      );
    }

    final data = error.response?.data;
    var serverMessage = '';
    if (data is Map<String, dynamic>) {
      serverMessage = (data['error'] ?? data['message'] ?? '') as String;
    } else if (data is String && data.isNotEmpty) {
      serverMessage = data;
    }

    if (statusCode == 401 && onUnauthorized != null) {
      onUnauthorized!();
    }

    final message = serverMessage.isNotEmpty
        ? serverMessage
        : ApiException.friendlyMessageFor(statusCode ?? 0);

    return ApiException(
      message: message,
      statusCode: statusCode,
      isUnauthorized: statusCode == 401,
    );
  }
}
