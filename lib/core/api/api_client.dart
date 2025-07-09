import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

@singleton
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio();
    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            // Check if this is an OpenRouter request by URL or path
            final isOpenRouterRequest = options.uri.toString().contains('openrouter.ai') || 
                                       options.path.contains('/chat/completions') ||
                                       options.path.contains('/models');
            if (isOpenRouterRequest) {
              final apiKey = AppConstants.openRouterApiKey;
              if (apiKey.isEmpty) {
                throw Exception('OpenRouter API key is empty');
              }
              // Remove any existing Authorization header
              options.headers.remove('Authorization');
              options.headers['Authorization'] = 'Bearer $apiKey';
              // Set HTTP-Referer and X-Title for OpenRouter compliance
              options.headers['HTTP-Referer'] = AppConstants.appName;
              options.headers['X-Title'] = AppConstants.appName;
              // Always set content type for JSON requests
              options.headers['Content-Type'] = 'application/json';
              // Log all headers for debugging
              debugPrint('🔑 [OpenRouter] Headers:');
              options.headers.forEach((k, v) => debugPrint('  $k: $v'));
              debugPrint('🌐 [OpenRouter] Request URL: \\${options.uri}');
              debugPrint('📝 [OpenRouter] Request path: \\${options.path}');
            }
            handler.next(options);
          } catch (e) {
            debugPrint('API Configuration Error: $e');
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'API key is not configured properly',
                type: DioExceptionType.cancel,
              ),
            );
          }
        },
        onError: (error, handler) {
          // Handle common errors
          if (error.response?.statusCode == 401) {
            // Handle unauthorized error
            debugPrint('API Key is invalid or expired');
          } else if (error.response?.statusCode == 429) {
            // Handle rate limit
            debugPrint('Rate limit exceeded');
          } else if (error.response?.statusCode == 500) {
            // Handle server error
            debugPrint('Server error occurred');
          }
          
          handler.next(error);
        },
      ),
    ]);

    // Set default options
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    );
  }

  // Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }
}
